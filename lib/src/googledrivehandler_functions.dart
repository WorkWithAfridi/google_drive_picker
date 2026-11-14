import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'google_drive_service.dart';
import 'googledrivehandler_screen.dart';

/// Coordinates Google authentication and the Drive file picker.
class GoogleDriveHandler {
  GoogleDriveHandler._();

  static final GoogleDriveHandler _instance = GoogleDriveHandler._();

  factory GoogleDriveHandler() => _instance;

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
  Future<File?> getFileFromGoogleDrive({required BuildContext context}) async {
    await initialize();

    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'This platform requires platform-provided Google Sign-In UI. '
        'GoogleDriveHandler currently supports the interactive Android, iOS, '
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
      final List<drive.File> files = await service.listFiles();
      if (!context.mounted) {
        return null;
      }

      return await Navigator.of(context).push<File>(
        MaterialPageRoute<File>(
          builder:
              (BuildContext context) => GoogleDriveScreen(
                files: files,
                service: service,
                userName: _account?.displayName ?? _account?.email ?? 'Google',
              ),
        ),
      );
    } finally {
      client.close();
    }
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
