import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_drive_picker/src/google_drive_picker_screen.dart';
import 'package:google_drive_picker/src/google_drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;

void main() {
  final List<drive.File> files = <drive.File>[
    drive.File()
      ..id = 'alpha'
      ..name = 'Alpha.pdf'
      ..mimeType = 'application/pdf',
    drive.File()
      ..id = 'beta'
      ..name = 'Beta.jpg'
      ..mimeType = 'image/jpeg',
  ];

  testWidgets('filters files without losing the original list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleDriveScreen(files: files, service: _FakeDriveService()),
      ),
    );

    expect(find.text('Alpha.pdf'), findsOneWidget);
    expect(find.text('Beta.jpg'), findsOneWidget);

    await tester.tap(find.byTooltip('Search files'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pump();

    expect(find.text('Alpha.pdf'), findsNothing);
    expect(find.text('Beta.jpg'), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pump();
    expect(find.text('Alpha.pdf'), findsOneWidget);
    expect(find.text('Beta.jpg'), findsOneWidget);
  });

  testWidgets('asks for confirmation before downloading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleDriveScreen(files: files, service: _FakeDriveService()),
      ),
    );

    await tester.tap(find.text('Alpha.pdf'));
    await tester.pumpAndSettle();

    expect(find.text('Download file?'), findsOneWidget);
    expect(find.text('Alpha.pdf'), findsNWidgets(2));
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('filters by file type and switches to grid view', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GoogleDriveScreen(files: files, service: _FakeDriveService()),
      ),
    );

    await tester.tap(find.text('Images'));
    await tester.pumpAndSettle();

    expect(find.text('Alpha.pdf'), findsNothing);
    expect(find.text('Beta.jpg'), findsOneWidget);

    await tester.tap(find.byTooltip('Show grid'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show list'), findsOneWidget);
    expect(find.text('Beta.jpg'), findsOneWidget);
  });

  testWidgets('uses compact Drive chrome without identity or intro copy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleDriveScreen(files: files, service: _FakeDriveService()),
      ),
    );

    expect(find.text('My Drive'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Choose a file'), findsNothing);
    expect(
      find.text('Browse files you can download from your Drive.'),
      findsNothing,
    );
    expect(find.text('Taylor'), findsNothing);
  });

  for (final Brightness brightness in Brightness.values) {
    testWidgets('inherits the host ${brightness.name} color scheme', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: brightness,
        ),
        useMaterial3: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: GoogleDriveScreen(files: files, service: _FakeDriveService()),
        ),
      );

      final Scaffold scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final AppBar appBar = tester.widget<AppBar>(find.byType(AppBar));
      final FilterChip allFilter = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'All'),
      );

      expect(scaffold.backgroundColor, theme.colorScheme.surface);
      expect(appBar.backgroundColor, theme.colorScheme.surface);
      expect(allFilter.backgroundColor, theme.colorScheme.surface);
      expect(allFilter.selectedColor, theme.colorScheme.secondaryContainer);
    });
  }

  testWidgets('uses an adaptive grid that can be overridden', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1200);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GoogleDriveScreen(files: files, service: _FakeDriveService()),
      ),
    );

    expect(find.byTooltip('Show list'), findsOneWidget);

    await tester.tap(find.byTooltip('Show list'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show grid'), findsOneWidget);
  });
}

class _FakeDriveService implements GoogleDriveService {
  @override
  Future<Uint8List> downloadBytes(drive.File file) async => Uint8List(0);

  @override
  Future<File> downloadFile(drive.File file, {Directory? directory}) {
    throw UnimplementedError();
  }

  @override
  Future<List<drive.File>> listFiles() async => const <drive.File>[];
}
