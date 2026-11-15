# 2.1.1

- Fixed the migration, troubleshooting, complete-example, and changelog links
  on pub.dev by using stable absolute GitHub URLs.

# 2.1.0

- Updated the picker to a cleaner Google Drive-inspired layout.
- Removed the picker intro copy and signed-in account name.
- Made picker surfaces, controls, and states inherit the host app's light or
  dark color scheme.
- Improved adaptive list/grid behavior and allowed wide layouts to override
  their automatic grid mode.
- Added single and multiple selection modes configured by the picker trigger.
- Added maximum-selection limits plus extension and exact/wildcard MIME type
  allowlists, including Google Workspace export-extension matching.
- Added a trigger gallery to the example app for single, multiple, image,
  document, and runtime-configured picker flows.
- Opened the picker immediately after authorization, with in-screen Drive
  loading, visible API failures, and a retry action.
- Replaced the package screenshots with current privacy-safe trigger, list,
  grid, and download-result views.

# 2.0.1

- Fixed screenshot rendering on pub.dev by using verified absolute image URLs.

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
