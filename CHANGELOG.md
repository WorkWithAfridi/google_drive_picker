# 2.0.0

- Promoted the renamed package to version 2, matching the modernized legacy
  release line.
- Added privacy-safe screenshots for the example, account chooser, list view,
  grid view, filters, and Drive thumbnails.
- Completed the `google_drive_picker` naming audit across package metadata,
  example projects, platform identifiers, tests, and documentation.
- Updated the example application name and Apple bundle identifier.

# 1.0.0

- Initial release as `google_drive_picker`.
- Renamed from the discontinued `googledrivehandler` package.
- Added a concise `GoogleDrivePicker.instance.pickFile(...)` API.
- Uses Google Sign-In 7, Google Drive read-only OAuth, and Drive API 19.
- Supports complete pagination, Shared Drives, shortcuts, and download checks.
- Supports Drive thumbnails, responsive list/grid views, filters, and search.
- Downloads regular files and exports Docs, Sheets, Slides, and Drawings.
- Includes typed errors, safe filenames, temporary storage, tests, and a
  complete Android/iOS example.
