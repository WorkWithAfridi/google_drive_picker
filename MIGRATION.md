# Migrating from 1.x to 2.0

Version 2 is a breaking modernization release. It replaces the Firebase-era
sign-in flow, upgrades Google Sign-In from 6 to 7, uses the generated Drive API
for downloads, and stores downloaded files in temporary storage.

## Breaking changes

| 1.x | 2.0 |
|---|---|
| Firebase dependencies were required by the package | Firebase is not a package dependency |
| A Google API key had to be set | API keys are not used |
| Sign-in was initialized internally on every picker call | `initialize()` must be awaited once |
| Full Drive OAuth scope | Read-only Drive OAuth scope |
| Raw REST download URLs | Generated Drive API media methods |
| Only Sheets had a native export path | Docs, Sheets, Slides, and Drawings are exported |
| Files were saved in application documents | Files are saved in temporary storage |
| Untyped asynchronous return value | `Future<File?>` |
| First page only | All pages are loaded |

`setAPIKey` remains as a deprecated no-op so existing source can compile while
it is being migrated. Remove the call rather than supplying another key.

## Before and after

### 1.x

```dart
GoogleDriveHandler().setAPIKey(apiKey: apiKey);
final file = await GoogleDriveHandler().getFileFromGoogleDrive(
  context: context,
);
```

### 2.0

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleDriveHandler().initialize();
  runApp(const MyApp());
}

final File? file = await GoogleDriveHandler().getFileFromGoogleDrive(
  context: context,
);
```

## Migration plan

### 1. Establish a baseline

- Upgrade to at least Flutter 3.29 and Dart 3.7.
- Record current Android package names, Apple bundle identifiers, OAuth client
  IDs, and debug/release signing fingerprints.
- Run the existing analyzer and tests before changing dependencies.

### 2. Upgrade dependencies

Update the application dependency:

```yaml
dependencies:
  googledrivehandler: ^2.0.0
```

Remove `firebase_auth` and `firebase_core` only if no other application feature
uses them. Do not remove Firebase from an application that relies on it for
unrelated services.

### 3. Update Google Cloud configuration

- Enable the Google Drive API.
- Ensure the OAuth consent screen includes the read-only Drive scope.
- Verify Android OAuth clients cover every application ID/signing SHA pair.
- Ensure iOS/macOS client IDs match each bundle identifier.
- Add the reversed iOS/macOS client ID as a URL scheme.
- For Android without `google-services.json`, retain the web OAuth client ID to
  pass as `serverClientId`.

### 4. Update application startup

Call `GoogleDriveHandler().initialize()` exactly once before the first picker
call. Passing identifiers is optional when native platform configuration
already supplies them.

```dart
await GoogleDriveHandler().initialize(
  clientId: iosClientId,
  serverClientId: webClientId,
);
```

### 5. Update picker callers

- Treat the result as `File?`.
- Handle `null` as cancellation, not failure.
- Catch authorization, API, network, and filesystem errors.
- Copy important downloads out of temporary storage.
- Remove all `setAPIKey` calls and API-key configuration.

### 6. Update native projects

- Android must use SDK 21 or later.
- iOS must use 12.0 or later; current Flutter templates may select a higher
  deployment target.
- macOS must use 10.15 or later and enable Google Sign-In keychain sharing.
- Refresh generated native project files if upgrading from an old Flutter
  template.

### 7. Verify before release

Test at least:

- First-time and returning-user sign-in.
- User cancellation at account selection and at the picker.
- Debug and release signing configurations.
- Blob files such as PDF, image, and video.
- Google Docs, Sheets, Slides, and Drawings exports.
- Shared Drive files and Drive shortcuts.
- A file whose owner disables downloads.
- Offline/API-error behavior and retry messaging.
- Copying a selected file to permanent storage.

Run the project checks:

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```

## Rollback strategy

Keep OAuth configuration changes additive until the 2.0 integration is
verified. If rollback is necessary, pin `googledrivehandler` to the prior 1.x
version and restore the old application integration. Do not delete OAuth or
Firebase configuration still used by the production version until deployment
is complete.
