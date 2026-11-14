import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_drive_picker_example/main.dart';

void main() {
  testWidgets('shows the picker onboarding and action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GoogleDrivePickerExampleApp());

    expect(find.text('Google Drive file picker'), findsOneWidget);
    expect(find.text('OAuth configuration'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('Single'), findsOneWidget);
    expect(find.text('Multiple'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.text('Multiple'));
    await tester.pumpAndSettle();

    expect(find.text('Maximum files'), findsOneWidget);
    expect(find.text('Choose files'), findsOneWidget);
  });
}
