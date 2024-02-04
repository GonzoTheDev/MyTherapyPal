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
    try {
      final myNewDoc = await db.collection("messages").add({
        "chatID": chatID,
        "message": newMessage,
        "sender": uuid,
        "status": "delivered",
        "timestamp": Timestamp.now(),
      });
      return myNewDoc.id;
    } catch (e) {
      print(e);
      return null;
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
