import 'package:chatview/chatview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';
import '../../services/mock_firebase.dart';

void main() {

  // Set to true to disable tests
  const disabled = true; 

  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });


  testWidgets('ChatScreen displays loading indicator while fetching data', (WidgetTester tester) async {

    // TODO: Mock SharedPreferences setup

    // Act: Render the ChatScreen
    await tester.pumpWidget(const MaterialApp(home: ChatScreen(chatID: "testChatId")));

    // Pump and settle in case there are any animations
    await tester.pumpAndSettle();

    // Assert: Verify a CircularProgressIndicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }, skip: disabled);

  testWidgets('ChatScreen displays messages when data is loaded', (WidgetTester tester) async {

    // TODO: Mock setup to return a list of messages

    // Act: Render the ChatScreen and let it load data
    await tester.pumpWidget(const MaterialApp(home: ChatScreen(chatID: "testChatId")));
    
    // Pump and settle in case there are any animations
    await tester.pumpAndSettle();

    // Assert: Verify messages are displayed on the screen
    expect(find.byType(Message), findsWidgets);
  }, skip: disabled);

  testWidgets('Sending a message clears the input and shows the message in the list', (WidgetTester tester) async {

    // Act: Render the ChatScreen, enter text, and tap send
    await tester.pumpWidget(const MaterialApp(home: ChatScreen(chatID: "testChatId")));
    await tester.enterText(find.byType(TextField), 'Test Message');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Assert: Input field should be cleared, and the message should appear in the list
    expect(find.text('Test Message'), findsOneWidget);

    // Ensure the TextField is cleared after sending
    expect(find.widgetWithText(TextField, ''), findsOneWidget);
  }, skip: disabled);

}

