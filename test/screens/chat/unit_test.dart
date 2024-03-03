import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  // Initialize Firebase app for tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  group('ChatScreen Tests', () {
    // Mock data for user profiles and chat
    final instance = FakeFirebaseFirestore();
    final user = MockUser(
      isAnonymous: false,
      uid: 'testUid',
      email: 'test@example.com',
    );
    final mockFirebaseAuth = MockFirebaseAuth(mockUser: user);

    setUp(() async {
      // Populate mock data into Firestore
      await instance.collection('profiles').doc('testUid').set({
        'fname': 'Test',
        'sname': 'User',
        'userType': 'TestType',
        'photoURL': 'http://example.com/photo.jpg',
        'publicRSAKey': 'mockPublicKey',
      });

      await instance.collection('chat').doc('testChatId').set({
        'users': ['testUid', 'otherUserId'],
        'keys': {'testUid': 'mockEncryptedAESKey'},
      });

      await instance.collection('profiles').doc('otherUserId').set({
        'fname': 'Other',
        'sname': 'User',
        'userType': 'OtherType',
        'photoURL': 'http://example.com/other_photo.jpg',
      });
    });

    testWidgets('initializeChat loads user and chat data correctly', (WidgetTester tester) async {
      // Create the widget by telling the tester to build it.
      await tester.pumpWidget(const MaterialApp(
        home: ChatScreen(chatID: 'testChatId'),
      ));

      // Trigger a frame.
      await tester.pumpAndSettle();

      // Check if chat data and user data are loaded correctly
      // This can include checking if certain widgets are present or certain states are set
      // Since `initializeChat` is called in `initState`, we need to check the resulting state of the widget
    });

    test('updateUserTypingStatus updates Firestore correctly', () async {
      const chatScreen = ChatScreen(chatID: 'testChatId'); // Assuming ChatScreen can be instantiated like this for the test.
      await chatScreen.updateUserTypingStatus(true);

      // Fetch the updated document from Firestore.
      final docSnapshot = await instance.collection('chat').doc('testChatId').get();
      final typingStatus = docSnapshot.data()?['typingStatus']['testUid'];

      // Verify the typing status is updated to true.
      expect(typingStatus, true);
    });

    test('updateAITypingStatus updates Firestore correctly', () async {
      final chatScreen = ChatScreen(chatID: 'testChatId'); // Adjust instantiation as needed.
      await chatScreen.updateAITypingStatus(true);

      // Fetch the updated document from Firestore.
      final docSnapshot = await instance.collection('chat').doc('testChatId').get();
      final typingStatus = docSnapshot.data()?['typingStatus']['ai-mental-health-assistant'];

      // Verify the AI typing status is updated to true.
      expect(typingStatus, true);
    });

  });
}
