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
  final Uint8List iv;

  // Create a new instance of the firebase firestore
  var db = FirebaseFirestore.instance;

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Constructor to initialise the user's data
  GenerateChat({required this.aesKey, required this.encryptedAESKey, required this.fname, required this.uid, required this.iv});

  // Function to generate a chat with the ai chatbot
  Future<void> generateAIChat() async {
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

        // Start a Firestore batch
        WriteBatch batch = db.batch();

        // Add a new document to the chat collection for the new user to interact with the ai chatbot
        db.collection("chat").doc(uid).set({
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
        });

        // Prepare the new message data
        messageData = {
          "chatID": uid,
          "message": encryptedUserMessageString,
          "sender": 'ai-mental-health-assistant',
          "status": "delivered",
          "timestamp": Timestamp.now(),
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

        // Reference to the chat document in the "chat" collection
        DocumentReference chatRef = db.collection("chat").doc(uid);

        // Update the chat document in the batch
        batch.update(chatRef, lastMessageUpdate);

        // Commit the batch write
        await batch.commit();

  }

}