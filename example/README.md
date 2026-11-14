# Google Drive Picker example

The example demonstrates the complete 2.0 flow:

- Initialize Google Sign-In once.
- Authenticate and request read-only Drive authorization.
- Browse, search, and select Drive files.
- Try ready-made triggers for unrestricted single selection, capped multiple
  selection, images, documents, and runtime options.
- See the API, selection mode, file limit, and format constraints for each
  trigger before opening it.
- Inspect and reopen the downloaded temporary file.
- Handle cancellation and errors.
- Sign out.

## Configure Google OAuth

Enable the Google Drive API and create OAuth clients before running the app.
The package README contains the complete
[Google Cloud walkthrough](../README.md#google-cloud-setup), including consent
screen, test-user, scope, credential, and production-verification steps.

The example uses the identifiers:

- Android application ID: `com.immichtv.google_drive_picker.example`
- iOS bundle identifier: `com.immichtv.googleDrivePicker.example`

For a real application, replace these sample identifiers in the native project
and create matching OAuth clients.

### Android

Register the application ID and signing SHA fingerprints. Then either:

1. Configure `google-services.json` with a web OAuth client, or
2. Pass the web OAuth client ID with `GOOGLE_SERVER_CLIENT_ID`.

Get the debug signing fingerprint with:

```sh
cd android
./gradlew signingReport
```

Create both an **Android** OAuth client for the package/SHA pair and a **Web
application** OAuth client. The Web client ID is the value supplied through
`GOOGLE_SERVER_CLIENT_ID`; do not use its client secret.

### iOS

Replace `YOUR_REVERSED_CLIENT_ID` in
`ios/Runner/Info.plist` with the reversed iOS OAuth client ID. Then either add
`GIDClientID` to that plist or pass the normal iOS client ID with
`GOOGLE_CLIENT_ID`.

Create the client under **Google Auth Platform → Clients → Create client →
iOS**, using bundle identifier `com.immichtv.googleDrivePicker.example`. The Cloud console shows
the iOS URL scheme, or the downloaded plist provides `CLIENT_ID` and
`REVERSED_CLIENT_ID`.

The URL scheme is required even when using `--dart-define`.

## Run

With native platform configuration:

```sh
flutter pub get
flutter run
```

With identifiers supplied from the command line:

```sh
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=YOUR_IOS_CLIENT_ID \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID
```

Only provide the identifiers required by the current platform. OAuth client
IDs are identifiers rather than secrets, but production projects should manage
environment-specific values through their normal build configuration.

## Expected behavior

1. Choose one of the trigger cards on the home screen and tap **Try trigger**.
2. Select a Google account and authorize read-only Drive access.
3. Search or browse the file list. The picker applies the trigger's single or
   multiple selection mode, maximum count, and format filters.
4. Confirm the selection and download.
5. The downloaded paths appear on the home screen; use the open icon to launch a
   compatible installed application.
6. Use the app-bar sign-out action to end the Google session.

The file is temporary. Copy it elsewhere before relying on it for later use.

See the package [README](../README.md), [migration guide](../MIGRATION.md), and
[troubleshooting guide](../TROUBLESHOOTING.md) for more detail.
