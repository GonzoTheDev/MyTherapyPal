import 'dart:typed_data';
import 'package:chatview/chatview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/models/chat.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';


void main() async {

  TestWidgetsFlutterBinding.ensureInitialized();
  
  final instance = FakeFirebaseFirestore();

  group('Chat Class Tests', () {
    late Chat chat;

    setUp(() {
      // Initialize the Chat class with mock data
      chat = Chat(
        chatID: 'testChatID',
        db: instance,
        users: [
          ChatUser(id: 'user1', name: 'User 1'),
          ChatUser(id: 'user2', name: 'User 2'),
        ],
        username: 'testUser',
        aesKey: Uint8List.fromList(List.generate(32, (index) => index)),
      );
      
    });

    test('Check if the chat is with the AI chatbot', () {
      // Test the checkAI method
      expect(chat.ai, false); 
    });

    test('Load context from file', () async {
      // Test the loadContext method
      final context = await chat.loadContext();
      expect(context, isNotEmpty);
    });

    test('Make request to LLM API', () async {
      // Test the llmResponse method
      final response = await chat.llmResponse('Test message');
      expect(response, isNotEmpty);
    });

    tearDown(() {
      // Dispose of resources, if needed
      chat.dispose();
    });
  });
}
