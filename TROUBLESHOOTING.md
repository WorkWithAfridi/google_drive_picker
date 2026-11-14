# Troubleshooting

## Sign-in appears cancelled after choosing an Android account

Some Android OAuth configuration failures are reported as cancellation by the
underlying sign-in SDK. Check:

- The Android OAuth client package name matches `applicationId`.
- Debug and release signing SHA fingerprints are both registered.
- `serverClientId` is the web OAuth client ID, not the Android client ID.
- When using `google-services.json`, it contains a web OAuth client entry.

## `serverClientId must be provided on Android`

Either pass the web OAuth client ID:

```dart
await GoogleDrivePicker.instance.initialize(
  serverClientId: 'YOUR_WEB_OAUTH_CLIENT_ID',
);
```

or configure the Google Services Gradle integration with a
`google-services.json` that includes a web OAuth client.

## iOS returns a configuration error or cannot return to the app

- Confirm the iOS OAuth client matches the app bundle identifier.
- Set `GIDClientID` or pass the iOS client ID to `initialize(clientId: ...)`.
- Add the reversed client ID to `CFBundleURLTypes` in `Info.plist`.
- Clean the build and reinstall the app after changing URL schemes.

The URL scheme is required even when the client ID is supplied from Dart.

## macOS reports a keychain error

Enable keychain sharing and add the Google Sign-In access group described in
the `google_sign_in_ios` macOS integration documentation.

## Drive returns 403 or authorization fails

- Confirm the Google Drive API is enabled in the OAuth client's Cloud project.
- Confirm the user granted the read-only Drive scope.
- Confirm the OAuth consent screen and test-user list are correctly configured.
- Check whether an organization administrator blocks third-party Drive access.
- A specific file may have `canDownload` disabled by its owner.

## A Google Workspace file cannot be exported

The picker exports Docs, Sheets, Slides, and Drawings. Other Google-native types,
including Forms and some newer Workspace formats, do not have a supported
export mapping and produce `GoogleDriveFileException`.

Google also applies export size and format limits. For unusually large native
documents, use the Drive web UI or a backend workflow appropriate for that file
type.

## The downloaded file disappears

Downloads are intentionally written to the temporary directory. Copy files to
application documents or another permanent location if they must persist.

## The downloaded file replaces an earlier file

Downloads use their sanitized Drive filename. Selecting another file with the
same name can replace the existing temporary file. Move or rename important
files after selection.

## Web compilation or authentication is unsupported

The package currently returns `dart:io` `File` objects and uses an interactive
native sign-in flow. Web is intentionally unsupported in 2.0.

## Collecting useful diagnostics

When reporting a problem, include:

- Flutter and Dart versions from `flutter --version`.
- Package version and target platform/OS version.
- Debug or release build mode.
- The structured `GoogleSignInExceptionCode`, when present.
- Drive API HTTP status/error details without access tokens or user data.
- Whether the problem affects all accounts/files or one specific item.

Never include OAuth client secrets, access tokens, downloaded user content, or
private signing material in an issue.
