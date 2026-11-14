import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_drive_picker_example/main.dart';

void main() {
  testWidgets('shows the available picker trigger examples', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const GoogleDrivePickerExampleApp());

    expect(find.text('Try every picker trigger'), findsOneWidget);
    expect(find.text('OAuth configuration'), findsOneWidget);
    expect(find.text('Single file'), findsOneWidget);
    expect(find.text('Multiple files'), findsOneWidget);
    expect(find.text('Images only'), findsOneWidget);
    expect(find.text('Documents only'), findsOneWidget);
    expect(find.text('Runtime options'), findsOneWidget);
    expect(find.text('pickFile()'), findsNWidgets(2));
    expect(find.text('pickFiles()'), findsNWidgets(2));
    expect(find.text('pick(options:)'), findsOneWidget);
    expect(find.text('Try trigger'), findsNWidgets(5));
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
