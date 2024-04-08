import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/screens/account_settings_screen.dart';

void main() {
  testWidgets('ManageAccount renders correctly', (WidgetTester tester) async {
    // Build the ManageAccount widget
    await tester.pumpWidget(const MaterialApp(home: ManageAccount()));

    // Verify that the ManageAccount widget is rendered
    expect(find.byType(ManageAccount), findsOneWidget);

    // Verify the AppBar title
    expect(find.text('Manage Account'), findsOneWidget);

    // Verify the body Text widget
    expect(find.text('This page needs to be implemented.'), findsOneWidget);
  });
}