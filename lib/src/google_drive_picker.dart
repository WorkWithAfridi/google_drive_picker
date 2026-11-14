import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'google_drive_service.dart';
import 'google_drive_picker_options.dart';
import 'google_drive_picker_screen.dart';

/// Coordinates Google authentication and the Drive file picker.
class GoogleDrivePicker {
  GoogleDrivePicker._();

  /// Shared picker instance used by most applications.
  static final GoogleDrivePicker instance = GoogleDrivePicker._();

  factory GoogleDrivePicker() => instance;

  Future<void>? _initialization;
  GoogleSignInAccount? _account;

  /// The currently authenticated account, if one has signed in.
  GoogleSignInAccount? get account => _account;

  /// Initializes Google Sign-In.
  ///
  /// Call this once during application startup when platform configuration
  /// does not already provide the client identifiers. Calling it repeatedly
  /// returns the original initialization future.
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? hostedDomain,
  }) {
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
      hostedDomain: hostedDomain,
    );
  }

  /// Retained for source compatibility.
  ///
  /// OAuth-authenticated Drive requests do not require an API key.
  @Deprecated('API keys are no longer required. Remove this call.')
  void setAPIKey({required String apiKey}) {}

  /// Authenticates the user and opens the Google Drive file picker.
  ///
  /// Returns the downloaded temporary file, or `null` when the user cancels
  /// authentication or closes the picker without choosing a file.
  Future<File?> pickFile({
    required BuildContext context,
    Set<String> allowedExtensions = const <String>{},
    Set<String> allowedMimeTypes = const <String>{},
  }) async {
    final List<File>? files = await pick(
      context: context,
      options: GoogleDrivePickerOptions(
        allowedExtensions: allowedExtensions,
        allowedMimeTypes: allowedMimeTypes,
      ),
    );
    return files == null || files.isEmpty ? null : files.first;
  }

  /// Authenticates the user and opens a multiple-file Drive picker.
  ///
  /// Returns downloaded temporary files in selection order, or `null` when
  /// the user cancels authentication or closes the picker without choosing.
  Future<List<File>?> pickFiles({
    required BuildContext context,
    int? maxFiles,
    Set<String> allowedExtensions = const <String>{},
    Set<String> allowedMimeTypes = const <String>{},
  }) {
    return pick(
      context: context,
      options: GoogleDrivePickerOptions(
        allowMultiple: true,
        maxFiles: maxFiles,
        allowedExtensions: allowedExtensions,
        allowedMimeTypes: allowedMimeTypes,
      ),
    );
  }

  /// Opens the picker with a fully specified [options] object.
  ///
  /// This is useful when selection behavior is chosen dynamically. Prefer
  /// [pickFile] or [pickFiles] when the mode is known at the call site.
  Future<List<File>?> pick({
    required BuildContext context,
    GoogleDrivePickerOptions options = const GoogleDrivePickerOptions(),
  }) async {
    await initialize();

    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'This platform requires platform-provided Google Sign-In UI. '
        'GoogleDrivePicker currently supports the interactive Android, iOS, '
        'and macOS sign-in flow.',
      );
    }

    try {
      _account = await signIn.authenticate(
        scopeHint: const <String>[drive.DriveApi.driveReadonlyScope],
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }

    final Map<String, String>? headers = await _account?.authorizationClient
        .authorizationHeaders(const <String>[
          drive.DriveApi.driveReadonlyScope,
        ], promptIfNecessary: true);
    if (headers == null) {
      throw const GoogleDriveAuthorizationException();
    }

    final _GoogleAuthClient client = _GoogleAuthClient(headers);
    final GoogleDriveApiService service = GoogleDriveApiService(client);
    try {
      if (!context.mounted) {
        return null;
      }

      return await Navigator.of(context).push<List<File>>(
        MaterialPageRoute<List<File>>(
          builder:
              (BuildContext context) =>
                  GoogleDriveScreen(service: service, options: options),
        ),
      );
    } finally {
      client.close();
    }
  }

  /// Compatibility alias for applications migrating from
  /// `googledrivehandler`.
  @Deprecated('Use pickFile(context: context) instead.')
  Future<File?> getFileFromGoogleDrive({required BuildContext context}) {
    return pickFile(context: context);
  }

  /// Signs the current user out of Google Sign-In.
  Future<void> signOut() async {
    await initialize();
    await GoogleSignIn.instance.signOut();
    _account = null;
  }
}

class _GoogleAuthClient extends http.BaseClient {
  _GoogleAuthClient(this._headers, {http.Client? client})
    : _client = client ?? http.Client();

  final Map<String, String> _headers;
  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
