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
        home: GoogleDriveScreen(
          files: files,
          service: _FakeDriveService(),
          userName: 'Taylor',
        ),
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
        home: GoogleDriveScreen(
          files: files,
          service: _FakeDriveService(),
          userName: 'Taylor',
        ),
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
    await tester.pumpWidget(
      MaterialApp(
        home: GoogleDriveScreen(
          files: files,
          service: _FakeDriveService(),
          userName: 'Taylor',
        ),
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
