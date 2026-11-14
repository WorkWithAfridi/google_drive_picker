import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_drive_picker/google_drive_picker.dart';
import 'package:open_file/open_file.dart';

const String _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const String _serverClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);

const List<_TriggerPreset> _triggerPresets = <_TriggerPreset>[
  _TriggerPreset(
    title: 'Single file',
    description: 'Pick any one file from Google Drive.',
    icon: Icons.insert_drive_file_outlined,
    apiLabel: 'pickFile()',
    formatLabel: 'Any format',
  ),
  _TriggerPreset(
    title: 'Multiple files',
    description: 'Pick up to three files and download them together.',
    icon: Icons.library_add_check_outlined,
    apiLabel: 'pickFiles()',
    formatLabel: 'Any format',
    allowMultiple: true,
    maxFiles: 3,
  ),
  _TriggerPreset(
    title: 'Images only',
    description: 'Pick up to five images using extension and MIME filters.',
    icon: Icons.photo_library_outlined,
    apiLabel: 'pickFiles()',
    formatLabel: 'image/*',
    allowMultiple: true,
    maxFiles: 5,
    allowedExtensions: <String>{'jpg', 'jpeg', 'png', 'webp'},
    allowedMimeTypes: <String>{'image/*'},
  ),
  _TriggerPreset(
    title: 'Documents only',
    description: 'Pick one PDF or supported Google Workspace document.',
    icon: Icons.description_outlined,
    apiLabel: 'pickFile()',
    formatLabel: 'Documents',
    allowedExtensions: <String>{'pdf', 'docx', 'xlsx', 'pptx'},
    allowedMimeTypes: <String>{
      'application/pdf',
      'application/vnd.google-apps.document',
      'application/vnd.google-apps.spreadsheet',
      'application/vnd.google-apps.presentation',
    },
  ),
  _TriggerPreset(
    title: 'Runtime options',
    description: 'Use the generic pick API with a dynamic configuration.',
    icon: Icons.tune_rounded,
    apiLabel: 'pick(options:)',
    formatLabel: 'PDF only',
    allowMultiple: true,
    maxFiles: 2,
    allowedExtensions: <String>{'pdf'},
    useOptionsApi: true,
  ),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleDrivePicker.instance.initialize(
    clientId:
        (Platform.isIOS || Platform.isMacOS) && _clientId.isNotEmpty
            ? _clientId
            : null,
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );
  runApp(const GoogleDrivePickerExampleApp());
}

class GoogleDrivePickerExampleApp extends StatelessWidget {
  const GoogleDrivePickerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Drive Picker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<File> _selectedFiles = <File>[];
  String? _message;
  bool _isBusy = false;
  _TriggerPreset? _activePreset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Picker'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            onPressed: _isBusy ? null : _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              'Try every picker trigger',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Each example below opens Google Drive with a different '
              'selection and format configuration.',
            ),
            const SizedBox(height: 24),
            const _ConfigurationCard(),
            const SizedBox(height: 24),
            for (final _TriggerPreset preset in _triggerPresets) ...<Widget>[
              _TriggerCard(
                preset: preset,
                enabled: !_isBusy,
                isBusy: _isBusy && identical(_activePreset, preset),
                onPressed: () => _runTrigger(preset),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedFiles.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Downloaded files',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final File file in _selectedFiles)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.download_done),
                    title: Text(file.uri.pathSegments.last),
                    subtitle: Text(file.path),
                    trailing: IconButton(
                      tooltip: 'Open downloaded file',
                      onPressed: _isBusy ? null : () => _openFile(file),
                      icon: const Icon(Icons.open_in_new),
                    ),
                  ),
                ),
            ],
            if (_message case final String message) ...<Widget>[
              const SizedBox(height: 16),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runTrigger(_TriggerPreset preset) async {
    setState(() => _activePreset = preset);
    _setBusy(true);
    try {
      final List<File>? files;
      if (preset.useOptionsApi) {
        files = await GoogleDrivePicker.instance.pick(
          context: context,
          options: GoogleDrivePickerOptions(
            allowMultiple: preset.allowMultiple,
            maxFiles: preset.maxFiles,
            allowedExtensions: preset.allowedExtensions,
            allowedMimeTypes: preset.allowedMimeTypes,
          ),
        );
      } else if (preset.allowMultiple) {
        files = await GoogleDrivePicker.instance.pickFiles(
          context: context,
          maxFiles: preset.maxFiles,
          allowedExtensions: preset.allowedExtensions,
          allowedMimeTypes: preset.allowedMimeTypes,
        );
      } else {
        final File? file = await GoogleDrivePicker.instance.pickFile(
          context: context,
          allowedExtensions: preset.allowedExtensions,
          allowedMimeTypes: preset.allowedMimeTypes,
        );
        files = file == null ? null : <File>[file];
      }
      if (!mounted) return;

      setState(() {
        _selectedFiles
          ..clear()
          ..addAll(files ?? const <File>[]);
        _message =
            files == null || files.isEmpty
                ? 'No files were selected.'
                : '${files.length} file${files.length == 1 ? '' : 's'} '
                    'downloaded to temporary storage.';
      });
    } on Object catch (error) {
      _showError('Unable to open Google Drive', error);
    } finally {
      _setBusy(false);
      if (mounted) {
        setState(() => _activePreset = null);
      }
    }
  }

  Future<void> _openFile(File file) async {
    _setBusy(true);
    try {
      final OpenResult result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        _showMessage('Could not open the file: ${result.message}');
      }
    } on Object catch (error) {
      _showError('Unable to open the downloaded file', error);
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _signOut() async {
    _setBusy(true);
    try {
      await GoogleDrivePicker.instance.signOut();
      if (mounted) {
        setState(() {
          _selectedFiles.clear();
          _message = 'Signed out.';
        });
      }
    } on Object catch (error) {
      _showError('Unable to sign out', error);
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    if (mounted) setState(() => _isBusy = value);
  }

  void _showError(String action, Object error) {
    _showMessage('$action: $error');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    setState(() => _message = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TriggerPreset {
  const _TriggerPreset({
    required this.title,
    required this.description,
    required this.icon,
    required this.apiLabel,
    required this.formatLabel,
    this.allowMultiple = false,
    this.maxFiles,
    this.allowedExtensions = const <String>{},
    this.allowedMimeTypes = const <String>{},
    this.useOptionsApi = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final String apiLabel;
  final String formatLabel;
  final bool allowMultiple;
  final int? maxFiles;
  final Set<String> allowedExtensions;
  final Set<String> allowedMimeTypes;
  final bool useOptionsApi;
}

class _TriggerCard extends StatelessWidget {
  const _TriggerCard({
    required this.preset,
    required this.enabled,
    required this.isBusy,
    required this.onPressed,
  });

  final _TriggerPreset preset;
  final bool enabled;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      preset.icon,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        preset.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _PresetChip(label: preset.apiLabel),
                _PresetChip(
                  label: preset.allowMultiple ? 'Multiple' : 'Single',
                ),
                if (preset.maxFiles case final int maxFiles)
                  _PresetChip(label: 'Max $maxFiles'),
                _PresetChip(label: preset.formatLabel),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: enabled ? onPressed : null,
                icon:
                    isBusy
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.play_arrow_rounded),
                label: Text(isBusy ? 'Opening…' : 'Try trigger'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}

class _ConfigurationCard extends StatelessWidget {
  const _ConfigurationCard();

  @override
  Widget build(BuildContext context) {
    final bool usesDartDefines =
        _clientId.isNotEmpty || _serverClientId.isNotEmpty;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'OAuth configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              usesDartDefines
                  ? 'Client identifiers were supplied through --dart-define.'
                  : 'Using native platform configuration. See example/README.md '
                      'before running the app.',
            ),
          ],
        ),
      ),
    );
  }
}
