import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final messages = [];
  final db = FirebaseFirestore.instance;
  final String chatID;
  final users = [];
  static const String profileImage = 'lib/assets/images/chatcbt.webp';

  Chat({
    this.chatID = '', required users,
  }) {
    populateMessages();
  }
  
  populateMessages() async {
    db.collection("messages").where("chatID", isEqualTo: chatID).get().then(
        (querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            String message = docSnapshot['message'];
            String messageId = docSnapshot.id;
            String sentBy = docSnapshot['sender'];
            DateTime timestamp = docSnapshot['timestamp'];
            messages.add(Message(
              id: messageId,
              message: message,
              createdAt: timestamp,
              sendBy: sentBy,
            ));
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