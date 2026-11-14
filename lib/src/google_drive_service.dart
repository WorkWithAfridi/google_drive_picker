import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// A failure to obtain authorization for Google Drive.
class GoogleDriveAuthorizationException implements Exception {
  const GoogleDriveAuthorizationException([
    this.message = 'Google Drive authorization was not granted.',
  ]);

  final String message;

  @override
  String toString() => 'GoogleDriveAuthorizationException: $message';
}

/// An operation that cannot be performed for a particular Drive file.
class GoogleDriveFileException implements Exception {
  const GoogleDriveFileException(this.message);

  final String message;

  @override
  String toString() => 'GoogleDriveFileException: $message';
}

/// Drive operations consumed by the picker UI.
abstract interface class GoogleDriveService {
  Future<List<drive.File>> listFiles();

  Future<Uint8List> downloadBytes(drive.File file);

  Future<File> downloadFile(drive.File file, {Directory? directory});
}

/// Google Drive v3 implementation of [GoogleDriveService].
class GoogleDriveApiService implements GoogleDriveService {
  GoogleDriveApiService(http.Client client) : _api = drive.DriveApi(client);

  final drive.DriveApi _api;

  static const String _folderMimeType = 'application/vnd.google-apps.folder';
  static const String _shortcutMimeType =
      'application/vnd.google-apps.shortcut';
  static const String _googleMimePrefix = 'application/vnd.google-apps.';

  static const Map<String, ({String extension, String mimeType})>
  _exportFormats = <String, ({String extension, String mimeType})>{
    'application/vnd.google-apps.document': (
      extension: '.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    ),
    'application/vnd.google-apps.spreadsheet': (
      extension: '.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
    'application/vnd.google-apps.presentation': (
      extension: '.pptx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    ),
    'application/vnd.google-apps.drawing': (
      extension: '.png',
      mimeType: 'image/png',
    ),
  };

  @override
  Future<List<drive.File>> listFiles() async {
    final List<drive.File> files = <drive.File>[];
    String? pageToken;

    do {
      final drive.FileList page = await _api.files.list(
        q: "trashed = false and mimeType != '$_folderMimeType'",
        spaces: 'drive',
        orderBy: 'name_natural',
        pageSize: 1000,
        pageToken: pageToken,
        includeItemsFromAllDrives: true,
        supportsAllDrives: true,
        $fields:
            'nextPageToken,files(id,name,mimeType,size,modifiedTime,'
            'thumbnailLink,iconLink,capabilities(canDownload),'
            'shortcutDetails(targetId,targetMimeType))',
      );
      files.addAll(page.files ?? const <drive.File>[]);
      pageToken = page.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return List<drive.File>.unmodifiable(files);
  }

  @override
  Future<Uint8List> downloadBytes(drive.File file) async {
    if (file.capabilities?.canDownload == false) {
      throw GoogleDriveFileException(
        '${file.name ?? 'This file'} cannot be downloaded.',
      );
    }

    final _DownloadTarget target = _downloadTarget(file);
    final drive.Media? media;
    final ({String extension, String mimeType})? export =
        _exportFormats[target.mimeType];

    if (export != null) {
      media = await _api.files.export(
        target.id,
        export.mimeType,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
    } else if (target.mimeType.startsWith(_googleMimePrefix)) {
      throw GoogleDriveFileException(
        '${file.name ?? 'This Google Workspace file'} has no supported export format.',
      );
    } else {
      final Object response = await _api.files.get(
        target.id,
        supportsAllDrives: true,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      media = response as drive.Media;
    }

    if (media == null) {
      throw const GoogleDriveFileException(
        'Google Drive returned no downloadable content.',
      );
    }

    final BytesBuilder bytes = BytesBuilder(copy: false);
    await for (final List<int> chunk in media.stream) {
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }

  @override
  Future<File> downloadFile(drive.File file, {Directory? directory}) async {
    final Uint8List bytes = await downloadBytes(file);
    final Directory destination = directory ?? await getTemporaryDirectory();
    await destination.create(recursive: true);

    final String fileName = _downloadName(file);
    final File output = File(path.join(destination.path, fileName));
    return output.writeAsBytes(bytes, flush: true);
  }

  _DownloadTarget _downloadTarget(drive.File file) {
    final String? id = file.id;
    final String? mimeType = file.mimeType;
    if (id == null || mimeType == null) {
      throw const GoogleDriveFileException(
        'The selected file is missing its ID or MIME type.',
      );
    }

    if (mimeType == _shortcutMimeType) {
      final String? targetId = file.shortcutDetails?.targetId;
      final String? targetMimeType = file.shortcutDetails?.targetMimeType;
      if (targetId == null || targetMimeType == null) {
        throw const GoogleDriveFileException(
          'The selected shortcut has no accessible target.',
        );
      }
      return _DownloadTarget(targetId, targetMimeType);
    }

    return _DownloadTarget(id, mimeType);
  }

  String _downloadName(drive.File file) {
    final _DownloadTarget target = _downloadTarget(file);
    final String rawName =
        file.name?.trim().isNotEmpty == true ? file.name!.trim() : 'download';
    final String safeName = path
        .basename(rawName)
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_');
    final String extension = _exportFormats[target.mimeType]?.extension ?? '';
    if (extension.isEmpty ||
        safeName.toLowerCase().endsWith(extension.toLowerCase())) {
      return safeName;
    }
    return '$safeName$extension';
  }
}

final class _DownloadTarget {
  const _DownloadTarget(this.id, this.mimeType);

  final String id;
  final String mimeType;
}
