import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_therapy_pal/services/encryption/AES/aes.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:my_therapy_pal/services/generate_chat.dart';

class Chat {

  // Initialize the Firestore database instance
  late FirebaseFirestore db;

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Define the properties of the Chat class
  final String chatID;
  Uint8List aesKey;
  String? chatContext;
  late String username;
  List<ChatUser> users; 
  List<dynamic>? conversationHistory;
  late bool ai = false;

  // Define the constructor
  Chat({required this.chatID, required this.users, required this.username, this.conversationHistory, required this.aesKey, FirebaseFirestore? db}) {
    
    // Initialize the Firestore database instance
    if(db != null) {
      this.db = db;
    } else {
      this.db = FirebaseFirestore.instance;
    }

    // Listen for new messages in the chat
    listenToMessages();
    
    // Initialize conversationHistory with context if necessary
    loadContext().then((loadedContext) {

      chatContext = loadedContext;
      // Initialize conversationHistory with context if necessary
      conversationHistory ??= [chatContext];
      
    }).catchError((error) {
      print("Error loading context: $error");
    });

    // Check if the chat is with the AI assistant
    checkAI();
  }

  // Method to check if the chat is with the AI assistant
  checkAI() {
    for (var user in users) {
      if (user.id == "ai-mental-health-assistant") {
        ai = true;
      }
    }
  }

  void dispose() {
    // Dispose of the stream
    messagesStream.drain();
  }


  // Method to load the context from a file
  Future<String> loadContext() async {
    const contextFilePath = 'assets/documents/context.txt';
    try {
      final loadedContext = await rootBundle.loadString(contextFilePath);
      return loadedContext;
    } catch (e) {
      print("Failed to load context from file: $e");
      return ""; 
    }
  }

  // Method for making a request to the LLM API
  // Needs to be HTTPS for production
  Future<String> llmResponse(String text) async {
  try {
    final response = await http.post(
      Uri.parse('https://5059-2a0d-3344-83a-510-2494-bb05-e86e-4d7f.ngrok-free.app/llm_api'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'text': text,
        'conversation_history': conversationHistory,
        'username': username,
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      return 'Error: Failed to load response, status code: ${response.statusCode}, please try again.';
    }
  } catch (e, stackTrace) {
    print('Error: Failed to make a request: $e');
    print('Stack trace: $stackTrace');
    return 'Error: Failed to make a request.';
  }
}

  // Method that listens for new messages in the chat and stores the latest 10 messages in the conversationHistory list
  void listenToMessages() {
    db.collection("messages")
      .where("chatID", isEqualTo: chatID)
      .where("active", isEqualTo: true)
      .orderBy("timestamp", descending: true)
      .limit(10)
      .snapshots().listen((querySnapshot) {
        List<Message> messages = querySnapshot.docs.map((docSnapshot) {
        String encryptedMsg = docSnapshot.data()['message'];
        String decryptedMessage = "";
        try {
          final utfToKey = encrypt.Key(aesKey);
          Uint8List ivGen = aesKeyEncryptionService.generateIVFromDocId(docSnapshot.id);
          final iv = encrypt.IV(ivGen);
          decryptedMessage = AESEncryption(utfToKey, iv).decryptData(encryptedMsg);
        } catch (e) {
          // Handle decryption errors or leave encrypted if decryption fails
          decryptedMessage = "[Encrypted message]";
        }
        return Message(
          id: docSnapshot.id,
          message: decryptedMessage,
          createdAt: (docSnapshot.data()['timestamp'] as Timestamp).toDate(),
          sendBy: docSnapshot.data()['sender'],
          status: _getStatusFromString(docSnapshot.data()['status']),
        );
      }).toList();

        // Reverse to maintain chronological order
        messages = messages.reversed.toList();

        // Ensure context is the first element, then append messages
        conversationHistory = [chatContext] + messages.map((message) => message.message).toList();

      }, onError: (error) {
        print("Error listening to messages: $error");
      });
  }

  // Firebase Stream for listening to new messages in the chat and adding them to the messages list
  Stream<List<Message>> get messagesStream => db.collection("messages")
    .where("chatID", isEqualTo: chatID)
    .where("active", isEqualTo: true)
    .orderBy("timestamp", descending: false)
    .snapshots()
    .map((querySnapshot) => querySnapshot.docs.map((docSnapshot) {
      String encryptedMsg = docSnapshot.data()['message'];
      String decryptedMessage = "";

      // Decrypt the message
      
      try {
        final utfToKey = encrypt.Key(aesKey);
        Uint8List ivGen = aesKeyEncryptionService.generateIVFromDocId(docSnapshot.id);
        final iv = encrypt.IV(ivGen);
        decryptedMessage = AESEncryption(utfToKey, iv).decryptData(encryptedMsg);
      } catch (e) {
        decryptedMessage = "[Encrypted message]";
      }

      // Create and return the Message object with the decrypted message.
      return Message(
        id: docSnapshot.id,
        message: decryptedMessage,
        createdAt: (docSnapshot.data()['timestamp'] as Timestamp).toDate(),
        sendBy: docSnapshot.data()['sender'],
        status: _getStatusFromString(docSnapshot.data()['status']),
      );
    }).toList());


  // Method to add an ai message to the firebase database
  Future<String?> addAIMessage(String newMessage, String uuid, [String llmTestResponse = '']) async {

    // Start a Firestore batch
    WriteBatch batch = db.batch();

    try {
      
        final utfToKey = encrypt.Key(aesKey);

        // Reference to the new document in the "messages" collection
        DocumentReference newMessageRef = db.collection("messages").doc();

        // Reference to the new document in the "messages" collection for the ai response
        DocumentReference newMessageRefAi = db.collection("messages").doc();

        // Generate an IV from the document ID for the user message
        Uint8List ivUserGen = aesKeyEncryptionService.generateIVFromDocId(newMessageRef.id);
        final ivUser = encrypt.IV(ivUserGen);

        // Generate an IV from the document ID for the ai response
        Uint8List ivAiGen = aesKeyEncryptionService.generateIVFromDocId(newMessageRefAi.id);
        final ivAi = encrypt.IV(ivAiGen);

        // Initialize the raw LLM response
        String llmRawResponse;

        if(llmTestResponse != "") {
          // If a test response is provided, use it instead of making a request to the LLM API
          llmRawResponse = llmTestResponse;
        }else{
          // Send the user's message and conversation history to the llmResponse function
          llmRawResponse = await llmResponse(newMessage);
        }

        // Parse the JSON to access the llm_response text
        Map<String, dynamic> llmParsedResponse = jsonDecode(llmRawResponse);
        String llmTextResponse = llmParsedResponse["llm_response"];

        final encryptedAiMessageString = AESEncryption(utfToKey, ivAi).encryptData(llmTextResponse);
        final encryptedUserMessageString = AESEncryption(utfToKey, ivUser).encryptData(newMessage);

        // Prepare the new message data with ai response
        Map<String, dynamic> messageDataAi = {
          "chatID": chatID,
          "message": encryptedAiMessageString,
          "sender": "ai-mental-health-assistant",
          "status": "delivered",
          "timestamp": Timestamp.now(),
          "active": true,
        };

        // Add the new message to the batch
        batch.set(newMessageRefAi, messageDataAi);

        // Prepare the lastMessage update for the chat with the same details as the new message
        Map<String, dynamic> lastMessageUpdate = {
          "lastMessage": {
            "lastMessageId": newMessageRef.id,
            "message": encryptedUserMessageString,
            "sender": uuid,
            "timestamp": messageDataAi["timestamp"],
            "status": "delivered",
            "active": true,
          }
        };

        // Reference to the chat document in the "chat" collection
        DocumentReference chatRef = db.collection("chat").doc(chatID);

        // Update the chat document in the batch
        batch.update(chatRef, lastMessageUpdate);

        // Commit the batch write
        await batch.commit();

        // Return the new message document ID on success
        return newMessageRef.id;

      } catch (e) {
      print(e);
      return null;
    }
  }

  // Method to add a message to the firebase database
  Future<String?> addMessage(String newMessage, String uuid) async {

    // Start a Firestore batch
    WriteBatch batch = db.batch();

    try {

        // Reference to the new document in the "messages" collection
        DocumentReference newMessageRef = db.collection("messages").doc();

        // Declare map to store the new message data
        Map<String, dynamic> messageData;

        Uint8List ivUserGen = aesKeyEncryptionService.generateIVFromDocId(newMessageRef.id);
        final ivUser = encrypt.IV(ivUserGen);

        final utfToKey = encrypt.Key(aesKey);

        final encryptedUserMessageString = AESEncryption(utfToKey, ivUser).encryptData(newMessage);

        // Prepare the new message data
        messageData = {
          "chatID": chatID,
          "message": encryptedUserMessageString,
          "sender": uuid,
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
            "sender": uuid,
            "timestamp": messageData["timestamp"],
            "status": "delivered",
            "active": true,
          }
        };

        // Reference to the chat document in the "chat" collection
        DocumentReference chatRef = db.collection("chat").doc(chatID);

        // Update the chat document in the batch
        batch.update(chatRef, lastMessageUpdate);

        // Commit the batch write
        await batch.commit();

        // Return the new message document ID on success
        return newMessageRef.id;

      
    } catch (e) {
      print(e);
      return null;
    }
  }


  // Method to update the status of a message in the database
  Future<void> updateMessageStatus(String messageId, String newStatus) async {
    try {
      // Update the message status in the messages collection
      await db.collection("messages").doc(messageId).update({
        "status": newStatus,
      });

      // Fetch the chat document to check if the message being updated is the last one sent
      DocumentSnapshot chatDoc = await db.collection("chat").doc(chatID).get();
      Map<String, dynamic>? chatData = chatDoc.data() as Map<String, dynamic>?;
      Map<String, dynamic>? lastMessage = chatData?['lastMessage'] as Map<String, dynamic>?;
      
      if (lastMessage != null && lastMessage['lastMessageId'] == messageId) {

        // The message being updated is the last message, so update the status in the lastMessage field of the chat document
        await db.collection("chat").doc(chatID).update({
          "lastMessage.status": newStatus,
        });

      }
    } catch (e) {
      print(e);
    }
  }

  // Method to get the message status from a string
  MessageStatus _getStatusFromString(String status) {
    switch (status) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.undelivered;
    }
  }

  // Method to generate a new ai chat room
  Future<void> generateAIChat(String encryptedAESKey, String fname, String uid) async {
    // Generate a chat with the ai chatbot
        GenerateChat(
          aesKey: aesKey,
          encryptedAESKey: encryptedAESKey,
          fname: fname,
          uid: uid,
        ).generateAIChat();
  }

  
}
