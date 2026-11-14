import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;

/// Selection and file-format constraints applied by the Drive picker.
final class GoogleDrivePickerOptions {
  const GoogleDrivePickerOptions({
    this.allowMultiple = false,
    this.maxFiles,
    this.allowedExtensions = const <String>{},
    this.allowedMimeTypes = const <String>{},
  }) : assert(maxFiles == null || maxFiles > 0, 'maxFiles must be positive.'),
       assert(
         allowMultiple || maxFiles == null || maxFiles == 1,
         'maxFiles can only exceed 1 when allowMultiple is true.',
       );

  /// Whether more than one file can be selected.
  final bool allowMultiple;

  /// Maximum number of files that can be selected, or `null` for no limit.
  final int? maxFiles;

  /// Allowed filename extensions, with or without a leading dot.
  ///
  /// Matching is case-insensitive. Google Workspace exports are matched by
  /// their resulting extension (`docx`, `xlsx`, `pptx`, or `png`).
  final Set<String> allowedExtensions;

  /// Allowed MIME types.
  ///
  /// Exact values and category wildcards such as `image/*` are supported.
  /// Matching is case-insensitive.
  final Set<String> allowedMimeTypes;

  /// The effective selection limit for this configuration.
  int? get effectiveMaxFiles => allowMultiple ? maxFiles : 1;

  /// Whether at least one file-format restriction is active.
  bool get hasFormatRestrictions =>
      allowedExtensions.isNotEmpty || allowedMimeTypes.isNotEmpty;

  /// Returns whether [file] satisfies the configured format restrictions.
  bool allows(drive.File file) {
    if (!hasFormatRestrictions) {
      return true;
    }

    final String mimeType = _effectiveMimeType(file).toLowerCase();
    final bool matchesMimeType = allowedMimeTypes.any((String allowed) {
      final String normalized = allowed.trim().toLowerCase();
      if (normalized.endsWith('/*')) {
        return mimeType.startsWith(
          normalized.substring(0, normalized.length - 1),
        );
      }
      return mimeType == normalized;
    });

    final Set<String> fileExtensions = _effectiveExtensions(file, mimeType);
    final bool matchesExtension = allowedExtensions.any((String allowed) {
      final String normalized = allowed.trim().toLowerCase().replaceFirst(
        RegExp(r'^\.'),
        '',
      );
      return normalized.isNotEmpty && fileExtensions.contains(normalized);
    });

    return matchesMimeType || matchesExtension;
  }
}

const Map<String, String> _workspaceExportExtensions = <String, String>{
  'application/vnd.google-apps.document': 'docx',
  'application/vnd.google-apps.spreadsheet': 'xlsx',
  'application/vnd.google-apps.presentation': 'pptx',
  'application/vnd.google-apps.drawing': 'png',
};

String _effectiveMimeType(drive.File file) {
  if (file.mimeType == 'application/vnd.google-apps.shortcut') {
    return file.shortcutDetails?.targetMimeType ?? file.mimeType ?? '';
  }
  return file.mimeType ?? '';
}

Set<String> _effectiveExtensions(drive.File file, String mimeType) {
  final Set<String> extensions = <String>{};
  final String fileExtension = path.extension(file.name ?? '').toLowerCase();
  if (fileExtension.isNotEmpty) {
    extensions.add(fileExtension.substring(1));
  }
  final String? exportExtension = _workspaceExportExtensions[mimeType];
  if (exportExtension != null) {
    extensions.add(exportExtension);
  }
  return extensions;
}
