import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_drive_picker/google_drive_picker.dart';
import 'package:open_file/open_file.dart';

const String _clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
const String _serverClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
);

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
  File? _selectedFile;
  String? _message;
  bool _isBusy = false;

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
              'Google Drive file picker',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This example authenticates with Google, requests read-only '
              'Drive access, and downloads the selected file to temporary '
              'storage.',
            ),
            const SizedBox(height: 24),
            const _ConfigurationCard(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isBusy ? null : _pickFile,
              icon:
                  _isBusy
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.add_to_drive_outlined),
              label: Text(_isBusy ? 'Working…' : 'Choose a file'),
            ),
            if (_selectedFile case final File file) ...<Widget>[
              const SizedBox(height: 24),
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

  Future<void> _pickFile() async {
    _setBusy(true);
    try {
      final File? file = await GoogleDrivePicker.instance.pickFile(
        context: context,
      );
      if (!mounted) return;

      setState(() {
        _selectedFile = file;
        _message =
            file == null
                ? 'No file was selected.'
                : 'Downloaded to temporary storage.';
      });
    } on Object catch (error) {
      _showError('Unable to open Google Drive', error);
    } finally {
      _setBusy(false);
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
          _selectedFile = null;
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
