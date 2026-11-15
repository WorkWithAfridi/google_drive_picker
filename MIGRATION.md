# Migrating from `googledrivehandler`

`google_drive_picker` is the maintained successor to `googledrivehandler`.
The OAuth behavior and native configuration are unchanged from
`googledrivehandler` 2.0.0; only the package name and preferred Dart API have
changed.

## 1. Replace the dependency

```yaml
dependencies:
  google_drive_picker: ^2.1.3
```

Remove the old dependency:

```yaml
dependencies:
  # Remove this:
  googledrivehandler: ^2.0.0
```

Then run:

```sh
flutter pub get
```

## 2. Replace the import

```dart
// Before
import 'package:googledrivehandler/googledrivehandler.dart';

// After
import 'package:google_drive_picker/google_drive_picker.dart';
```

## 3. Rename the public API

```dart
// Before
await GoogleDriveHandler().initialize(
  clientId: iosClientId,
  serverClientId: webClientId,
);

final File? file = await GoogleDriveHandler().getFileFromGoogleDrive(
  context: context,
);

// After
await GoogleDrivePicker.instance.initialize(
  clientId: iosClientId,
  serverClientId: webClientId,
);

final File? file = await GoogleDrivePicker.instance.pickFile(
  context: context,
);
```

Use `GoogleDrivePicker.instance.signOut()` to disconnect the current account.
The longer `getFileFromGoogleDrive` method remains temporarily available as a
deprecated migration alias.

## 4. Remove obsolete API-key setup

Remove calls to `setAPIKey`. Google Drive requests are authorized with the
signed-in user's OAuth access token, so this package does not require a Google
API key:

```dart
// Remove this legacy call:
GoogleDrivePicker.instance.setAPIKey(apiKey: '...');
```

The deprecated method remains a no-op in the 2.x release line only to let
existing applications migrate without an immediate compilation failure. It is
scheduled for removal in the next major release. OAuth client configuration is
still required as described below.

## 5. Keep existing OAuth configuration

Applications migrating from `googledrivehandler` do not need new OAuth clients
when their Android application ID, Apple bundle ID, and signing certificates
stay the same. Package names in `pubspec.yaml` and Dart imports do not affect
Google Cloud OAuth registration.

If you copy the included example instead of migrating your own app, register
its application ID and signing SHA fingerprints as described in the README.

## 6. Verify

```sh
flutter analyze
flutter test
flutter run
```

Test first-time sign-in, cancellation, regular-file downloads, Google Workspace
exports, and sign-out on each supported platform before releasing your app.
