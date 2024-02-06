import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final String chatID;
  List<ChatUser> users; 

  Chat({
    this.chatID = '',
    required this.users,
  });

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

  Future<String?> addMessage(String newMessage, String uuid) async {
    // Start a Firestore batch
    WriteBatch batch = db.batch();

    try {
      // Reference to the new document in the "messages" collection
      DocumentReference newMessageRef = db.collection("messages").doc();

      // Prepare the new message data
      Map<String, dynamic> messageData = {
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
          "status": "delivered", // or messageData["status"] if you prefer to keep consistency
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
