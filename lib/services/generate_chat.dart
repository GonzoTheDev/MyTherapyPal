import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_therapy_pal/services/encryption/AES/aes.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';

class GenerateChat {        
  // Declare the variables to store the user's data
  final String fname;
  final String uid;
  final Uint8List aesKey;
  final String encryptedAESKey;

  // Create a new instance of the firebase firestore
  var db = FirebaseFirestore.instance;

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Constructor to initialise the user's data
  GenerateChat({required this.aesKey, required this.encryptedAESKey, this.fname = "missing_name", required this.uid});

  // Function to generate a chat with the ai chatbot
  Future<String> generateAIChat() async {

        // Start a Firestore batch
        WriteBatch batch = db.batch();

        // Write a greeting message from the ai chatbot to the new user
        final initialGreeting = "Hello, $fname!\n\nI am your AI mental health assistant.\n\nI am here to help you with your mental health. I am not a replacement for a professional, but I can help you with some of the day-to-day challenges you may face. I am here to listen and provide you with some guidance.\n\nI am available 24/7!\n\nIs there anything I can help you with today?";

        // Encrypt the initial greeting message with the AES key
        final utfToKey = encrypt.Key(aesKey);
        DocumentReference newMessageRef = db.collection("messages").doc();
        // Generate an IV from the document ID for the user message
        Uint8List ivUserGen = aesKeyEncryptionService.generateIVFromDocId(newMessageRef.id);
        final ivUser = encrypt.IV(ivUserGen);
        final encryptedUserMessageString = AESEncryption(utfToKey, ivUser).encryptData(initialGreeting);

        // Declare map to store the new message data
        Map<String, dynamic> messageData;

        // Declare map to store the new message data
        Map<String, dynamic> chatData;

        // Reference to the new document in the "chat" collection
        DocumentReference newChatRef = db.collection("chat").doc();

        // Add a new document to the chat collection for the new user to interact with the ai chatbot
        chatData = {
          "lastMessage": {
            "lastMessageId": "",
            "message": "",
            "sender": "",
            "status": "",
            "timestamp": "",
          },
          "typingStatus": {
            "ai-mental-health-assistant": false,
            uid: false,
          },
          "users": ["ai-mental-health-assistant", uid],
          "keys": {
            "ai-mental-health-assistant": encryptedAESKey,
            uid: encryptedAESKey,
          },
          "active": true,
        };

        // Add the new message to the batch
        batch.set(newChatRef, chatData);

        // Prepare the new message data
        messageData = {
          "chatID": newChatRef.id,
          "message": encryptedUserMessageString,
          "sender": 'ai-mental-health-assistant',
          "status": "delivered",
          "timestamp": Timestamp.now(),
          "active": true,
        };

        // Add the new message to the batch
        batch.set(newMessageRef, messageData);

        // Prepare the lastMessage update for the chat with the same details as the new message
        Map<String, dynamic> lastMessageUpdate = {
          "lastMessage": {
            "lastMessageId": newMessageRef.id,
            "message": encryptedUserMessageString,
            "sender": 'ai-mental-health-assistant',
            "timestamp": messageData["timestamp"],
            "status": "delivered",
          }
        };

        // Update the chat document in the batch
        batch.update(newChatRef, lastMessageUpdate);

        // Commit the batch write
        await batch.commit();

        return newChatRef.id;

  }

  Future<String> generateUserChat(String ouid, String otherUserEncryptedAESKey) async {
    // Generate a new chat with a user
    try {

      // Start a Firestore batch
      WriteBatch batch = db.batch();

      // Declare map to store the new message data
      Map<String, dynamic> chatData;

      // Reference to the new document in the "chat" collection
        DocumentReference newChatRef = db.collection("chat").doc();

        // Add a new document to the chat collection for the new user to interact with the ai chatbot
        chatData = {
          "lastMessage": {
            "lastMessageId": "",
            "message": "",
            "sender": "",
            "status": "",
            "timestamp": Timestamp.now(),
          },
          "typingStatus": {
            ouid: false,
            uid: false,
          },
          "users": [ouid, uid],
          "keys": {
            ouid: otherUserEncryptedAESKey,
            uid: encryptedAESKey,
          },
          "active": true,
        };

        // Add the new message to the batch
        batch.set(newChatRef, chatData);

        // Commit the batch write
        await batch.commit();


      return "success";
    } catch (e) {
      print("Error generating chat: $e");
      return "error";
    }
  }

}