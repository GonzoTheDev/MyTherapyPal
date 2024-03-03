import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';

void main() {
  setUpAll(() async {
    final instance = FakeFirebaseFirestore();
  });

  testWidgets('ChatScreen Widget Test', (WidgetTester tester) async {

    await tester.pumpWidget(MaterialApp(home: ChatScreen(chatID: "testChatId")));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
