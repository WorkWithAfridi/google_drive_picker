import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_drive_picker/google_drive_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GoogleDriveApiService', () {
    test('loads every page and requests downloadable file fields', () async {
      final List<Uri> requests = <Uri>[];
      final MockClient client = MockClient((http.Request request) async {
        requests.add(request.url);
        final String? pageToken = request.url.queryParameters['pageToken'];
        return http.Response(
          jsonEncode(<String, Object>{
            if (pageToken == null) 'nextPageToken': 'page-2',
            'files': <Map<String, Object>>[
              <String, Object>{
                'id': pageToken == null ? 'first' : 'second',
                'name': pageToken == null ? 'Alpha.pdf' : 'Beta.pdf',
                'mimeType': 'application/pdf',
                'capabilities': <String, bool>{'canDownload': true},
              },
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final GoogleDriveApiService service = GoogleDriveApiService(client);
      final List<drive.File> files = await service.listFiles();

      expect(files.map((drive.File file) => file.id), <String>[
        'first',
        'second',
      ]);
      expect(requests, hasLength(2));
      expect(requests.first.queryParameters['pageSize'], '1000');
      expect(requests.first.queryParameters['supportsAllDrives'], 'true');
      expect(requests.last.queryParameters['pageToken'], 'page-2');
      expect(requests.first.queryParameters['q'], contains('trashed = false'));
      expect(
        requests.first.queryParameters['fields'],
        allOf(contains('thumbnailLink'), contains('iconLink')),
      );
    });

    test('downloads blob content with the media option', () async {
      final MockClient client = MockClient((http.Request request) async {
        expect(request.url.path, endsWith('/drive/v3/files/blob-id'));
        expect(request.url.queryParameters['alt'], 'media');
        return http.Response.bytes(
          <int>[1, 2, 3],
          200,
          headers: <String, String>{'content-type': 'application/octet-stream'},
        );
      });
      final GoogleDriveApiService service = GoogleDriveApiService(client);
      final drive.File file =
          drive.File()
            ..id = 'blob-id'
            ..name = 'report.pdf'
            ..mimeType = 'application/pdf';

      expect(await service.downloadBytes(file), <int>[1, 2, 3]);
    });

    test('exports a Google Doc as a Word document', () async {
      final MockClient client = MockClient((http.Request request) async {
        expect(request.url.path, endsWith('/drive/v3/files/doc-id/export'));
        expect(request.url.queryParameters['alt'], 'media');
        expect(
          request.url.queryParameters['mimeType'],
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
        return http.Response.bytes(
          utf8.encode('document'),
          200,
          headers: <String, String>{'content-type': 'application/octet-stream'},
        );
      });
      final GoogleDriveApiService service = GoogleDriveApiService(client);
      final drive.File file =
          drive.File()
            ..id = 'doc-id'
            ..name = 'Proposal'
            ..mimeType = 'application/vnd.google-apps.document';

      expect(utf8.decode(await service.downloadBytes(file)), 'document');
    });

    test('sanitizes file names and appends export extensions', () async {
      final MockClient client = MockClient(
        (_) async => http.Response.bytes(
          <int>[4, 5, 6],
          200,
          headers: <String, String>{'content-type': 'application/octet-stream'},
        ),
      );
      final GoogleDriveApiService service = GoogleDriveApiService(client);
      final drive.File file =
          drive.File()
            ..id = 'sheet-id'
            ..name = '../Quarter:One'
            ..mimeType = 'application/vnd.google-apps.spreadsheet';
      final Directory directory = await Directory.systemTemp.createTemp(
        'google_drive_picker_test_',
      );

      try {
        final File downloaded = await service.downloadFile(
          file,
          directory: directory,
        );
        expect(downloaded.path, endsWith('Quarter_One.xlsx'));
        expect(await downloaded.readAsBytes(), <int>[4, 5, 6]);
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('rejects files without download permission', () async {
      final GoogleDriveApiService service = GoogleDriveApiService(
        MockClient((_) async => http.Response('', 500)),
      );
      final drive.File file =
          drive.File()
            ..id = 'blocked'
            ..name = 'Blocked.pdf'
            ..mimeType = 'application/pdf'
            ..capabilities = (drive.FileCapabilities()..canDownload = false);

      expect(
        () => service.downloadBytes(file),
        throwsA(isA<GoogleDriveFileException>()),
      );
    });
  });
}
