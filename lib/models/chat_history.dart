import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final messages = [];
  final db = FirebaseFirestore.instance;
  final String chatID;
  final users = [];

  Chat({
    this.chatID = '', required users,
  }) {
    populateMessages();
  }
  
  populateMessages() async {
    db.collection("messages").where("chatID", isEqualTo: chatID).get().then(
        (querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            String messageID = docSnapshot.id;
            String msgStatus = docSnapshot['status'];

            if (msgStatus == 'delivered') {
              messages.add(Message(
                id: messageID,
                message: docSnapshot['message'],
                createdAt: docSnapshot['timestamp'],
                sendBy: docSnapshot['sender'], // userId of who sends the message
                status: MessageStatus.delivered,
              )
              );
            } else if (msgStatus == 'read') {
              messages.add(Message(
                id: messageID,
                message: docSnapshot['message'],
                createdAt: docSnapshot['timestamp'],
                sendBy: docSnapshot['sender'], // userId of who sends the message
                status: MessageStatus.read,
              )
              );
            } else {
              messages.add(Message(
                id: messageID,
                message: docSnapshot['message'],
                createdAt: docSnapshot['timestamp'],
                sendBy: docSnapshot['sender'], // userId of who sends the message
                status: MessageStatus.undelivered,
              )
              );
            }
          }
        },
        onError: (e) => print("Error completing: $e"),
      );
  }

  addMessage(String newMessage, String uuid) async {
    try {
      final myNewDoc = await db.collection("messages").add({
        "chatID": chatID,
        "message": newMessage,
        "sender": uuid,
        "timestamp": Timestamp.now()
      });
      return myNewDoc.id.toString();
    } catch (e) {
      print(e);
      return null; 
    }
  }

  
}