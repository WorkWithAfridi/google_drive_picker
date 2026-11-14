import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the picker onboarding and action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GoogleDrivePickerExampleApp());

    expect(find.text('Google Drive file picker'), findsOneWidget);
    expect(find.text('OAuth configuration'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
