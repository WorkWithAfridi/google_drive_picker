import 'package:flutter_test/flutter_test.dart';
import 'package:google_drive_picker/google_drive_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;

void main() {
  group('GoogleDrivePickerOptions', () {
    test('allows every file when no format restriction is configured', () {
      const GoogleDrivePickerOptions options = GoogleDrivePickerOptions();

      expect(options.allows(_file('archive.zip', 'application/zip')), isTrue);
      expect(options.effectiveMaxFiles, 1);
    });

    test('matches extensions case-insensitively with optional dots', () {
      const GoogleDrivePickerOptions options = GoogleDrivePickerOptions(
        allowedExtensions: <String>{'.PDF', 'jpg'},
      );

      expect(options.allows(_file('Report.Pdf', 'application/pdf')), isTrue);
      expect(options.allows(_file('photo.JPG', 'image/jpeg')), isTrue);
      expect(options.allows(_file('notes.txt', 'text/plain')), isFalse);
    });

    test('matches Google Workspace files by their export extension', () {
      const GoogleDrivePickerOptions options = GoogleDrivePickerOptions(
        allowedExtensions: <String>{'docx', 'xlsx'},
      );

      expect(
        options.allows(
          _file('Proposal', 'application/vnd.google-apps.document'),
        ),
        isTrue,
      );
      expect(
        options.allows(
          _file('Deck', 'application/vnd.google-apps.presentation'),
        ),
        isFalse,
      );
    });

    test('matches exact and wildcard MIME types', () {
      const GoogleDrivePickerOptions options = GoogleDrivePickerOptions(
        allowedMimeTypes: <String>{'image/*', 'application/pdf'},
      );

      expect(options.allows(_file('photo.webp', 'image/webp')), isTrue);
      expect(options.allows(_file('report', 'application/pdf')), isTrue);
      expect(options.allows(_file('clip.mp4', 'video/mp4')), isFalse);
    });

    test('uses a shortcut target MIME type for matching', () {
      const GoogleDrivePickerOptions options = GoogleDrivePickerOptions(
        allowedMimeTypes: <String>{'image/*'},
      );
      final drive.File shortcut = _file(
          'Image shortcut',
          'application/vnd.google-apps.shortcut',
        )
        ..shortcutDetails =
            (drive.FileShortcutDetails()..targetMimeType = 'image/png');

      expect(options.allows(shortcut), isTrue);
    });

    test('exposes the configured multiple-selection limit', () {
      const GoogleDrivePickerOptions options = GoogleDrivePickerOptions(
        allowMultiple: true,
        maxFiles: 4,
      );

      expect(options.effectiveMaxFiles, 4);
    });

    test('rejects invalid maximum counts', () {
      expect(
        () => GoogleDrivePickerOptions(allowMultiple: true, maxFiles: 0),
        throwsAssertionError,
      );
      expect(() => GoogleDrivePickerOptions(maxFiles: 2), throwsAssertionError);
    });
  });
}

drive.File _file(String name, String mimeType) =>
    drive.File()
      ..name = name
      ..mimeType = mimeType;
