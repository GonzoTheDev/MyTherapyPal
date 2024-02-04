import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? _aiChatId; // Store the AI chat ID

  @override
  void initState() {
    super.initState();
    getChatbotChatId().then((id) {
      if (mounted) {
        setState(() {
          _aiChatId = id; // Set the AI chat ID
        });
      }
    });
  }

  Future<String?> getChatbotChatId() async {
    try {
      QuerySnapshot chatSnapshot = await _firestore
          .collection('chat')
          .where('users', arrayContains: _currentUserId)
          .get();

      for (var doc in chatSnapshot.docs) {
        var users = List<String>.from(doc['users']);
        if (users.contains('ai-mental-health-assistant')) {
          return doc.id; 
        }
      }
      return null;
    } catch (e) {
      print('Error fetching chatbot chat ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chat')
            .where('users', arrayContains: _currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching chats'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats found'));
          }

          var filteredChats = snapshot.data!.docs.where((doc) => doc.id != _aiChatId).toList(); // Filter out AI chat

          return Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundImage: AssetImage('lib/assets/images/chatcbt.webp'),
                ),
                title: const Text('AI Mental Health Assistant'),
                onTap: () {
                  if (_aiChatId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatID: _aiChatId!),
                      ),
                    );
                  }
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    var chatData = filteredChats[index];
                    var otherUserId = chatData['users'].firstWhere((u) => u != _currentUserId);
                    var chatID = chatData.id;

                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(otherUserId)
                            .get(),
                        builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const ListTile(
                              leading: CircleAvatar(),
                              title: Text('Loading...'),
                            );
                          }

                          if (userSnapshot.hasError || !userSnapshot.hasData) {
                            return const ListTile(
                              leading: CircleAvatar(),
                              title: Text('Error or no data'),
                            );
                          }

                          final otherUserDoc = userSnapshot.data!;
                          final otherUserFname = otherUserDoc['fname'];
                          final otherUserSname = otherUserDoc['sname'];
                          final String otherUserProfilePic = otherUserDoc['photoURL'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(otherUserProfilePic),
                            ),
                            title: Text('$otherUserFname $otherUserSname'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ChatScreen(chatID: chatID)),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
