import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Chat {

  // Initialize the Firestore database instance
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Define the properties of the Chat class
  final String chatID;
  late String context;
  List<ChatUser> users; 
  List<dynamic>? conversationHistory;
  late bool ai = false;

  // Define the constructor
  Chat({required this.chatID, required this.users, this.conversationHistory}) {

    // Initialize conversationHistory here if needed, or consider an async init method.
    loadContext().then((loadedContext) {

      context = loadedContext;
      // Initialize conversationHistory with context if necessary
      conversationHistory ??= [context];
      
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

  // Method to load the context from a file
  Future<String> loadContext() async {
    const contextFilePath = 'lib/assets/documents/context.txt';
    try {
      final loadedContext = await rootBundle.loadString(contextFilePath);
      return loadedContext;
    } catch (e) {
      print("Failed to load context from file: $e");
      return ""; 
    }
  }

  // Method for making a request to the LLM API
  Future<String> llmResponse(String text) async {
  try {
    final response = await http.post(
      Uri.parse('http://localhost:5000/llm_api'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'text': text,
        'conversation_history': conversationHistory,
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load response');
    }
  } catch (e) {
    throw Exception('Failed to make a request: $e');
  }
}

  // Method that listens for new messages in the chat and stores the latest 10 messages in the conversationHistory list
  void listenToMessages() {
    db.collection("messages")
      .where("chatID", isEqualTo: chatID)
      .where("sender", isNotEqualTo: "ai-mental-health-assistant")
      .orderBy("timestamp", descending: true)
      .limit(10)
      .snapshots().listen((querySnapshot) {
        List<Message> messages = querySnapshot.docs.map((docSnapshot) => Message(
          id: docSnapshot.id,
          message: docSnapshot.data()['message'] as String,
          createdAt: (docSnapshot.data()['timestamp'] as Timestamp).toDate(),
          sendBy: docSnapshot.data()['sender'] as String,
          status: _getStatusFromString(docSnapshot.data()['status'] as String),
        )).toList();

        // Reverse to maintain chronological order
        messages = messages.reversed.toList();

        // Ensure context is the first element, then append messages
        conversationHistory = [context] + messages.map((message) => message.message).toList();

      }, onError: (error) {
        print("Error listening to messages: $error");
      });
  }

  // Firebase Stream for listening to new messages in the chat and adding them to the messages list
  Stream<List<Message>> get messagesStream => db.collection("messages")
    .where("chatID", isEqualTo: chatID)
    .orderBy("timestamp", descending: false)
    .snapshots()
    .map((querySnapshot) => querySnapshot.docs.map((docSnapshot) => Message(
          id: docSnapshot.id,
          message: docSnapshot.data()['message'] as String,
          createdAt: (docSnapshot.data()['timestamp'] as Timestamp).toDate(),
          sendBy: docSnapshot.data()['sender'] as String,
          status: _getStatusFromString(docSnapshot.data()['status'] as String),
        )).toList());


  // Method to add an ai message to the firebase database
  Future<String?> addAIMessage(String newMessage, String uuid) async {

    // Start a Firestore batch
    WriteBatch batch = db.batch();

    try {

        // Reference to the new document in the "messages" collection
        DocumentReference newMessageRef = db.collection("messages").doc();

        // Reference to the new document in the "messages" collection for the ai response
        DocumentReference newMessageRefAi = db.collection("messages").doc();

        // Send the user's message and conversation history to the llmResponse function
        String llmRawResponse = await llmResponse(newMessage);

        // Parse the JSON to access the llm_response text
        Map<String, dynamic> llmParsedResponse = jsonDecode(llmRawResponse);
        String llmTextResponse = llmParsedResponse["llm_response"];

        // Prepare the new message data with ai response
        Map<String, dynamic> messageDataAi = {
          "chatID": chatID,
          "message": llmTextResponse,
          "sender": "ai-mental-health-assistant",
          "status": "delivered",
          "timestamp": Timestamp.now(),
        };

        // Add the new message to the batch
        batch.set(newMessageRefAi, messageDataAi);

        // Prepare the lastMessage update for the chat with the same details as the new message
        Map<String, dynamic> lastMessageUpdate = {
          "lastMessage": {
            "lastMessageId": newMessageRef.id,
            "message": newMessage,
            "sender": uuid,
            "timestamp": messageDataAi["timestamp"],
            "status": "delivered",
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

        // Prepare the new message data
        messageData = {
          "chatID": chatID,
          "message": newMessage,
          "sender": uuid,
          "status": "delivered",
          "timestamp": Timestamp.now(),
        };

        // Add the new message to the batch
        batch.set(newMessageRef, messageData);

        // Prepare the lastMessage update for the chat with the same details as the new message
        Map<String, dynamic> lastMessageUpdate = {
          "lastMessage": {
            "lastMessageId": newMessageRef.id,
            "message": newMessage,
            "sender": uuid,
            "timestamp": messageData["timestamp"],
            "status": "delivered",
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
}
