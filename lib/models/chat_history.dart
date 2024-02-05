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
    .map((querySnapshot) => querySnapshot.docs.map((docSnapshot) {
      final reactionData = docSnapshot.data()['reaction'] as Map<String, dynamic>?;
      final reactions = reactionData != null ? Reaction(
        reactions: reactionData['reactions'] != null ? List<String>.from(reactionData['reactions']) : [],
        reactedUserIds: reactionData['reactedUserIds'] != null ? List<String>.from(reactionData['reactedUserIds']) : [],
      ) : null;
      
      return Message(
        id: docSnapshot.id,
        message: docSnapshot.data()['message'] as String,
        createdAt: (docSnapshot.data()['timestamp'] as Timestamp).toDate(),
        sendBy: docSnapshot.data()['sender'] as String,
        reaction: reactions,
        status: _getStatusFromString(docSnapshot.data()['status'] as String),
      );
    }).toList());

  Future<void> updateMessageReaction(String messageId, Reaction reaction) async {
    final reactionMap = {
      'reactions': reaction.reactions,
      'reactedUserIds': reaction.reactedUserIds,
    };
    await db.collection("messages").doc(messageId).update({
      'reaction': reactionMap,
    });
  }

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
