import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';
import 'package:intl/intl.dart';

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

  // Helper function to format the timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(timestamp); 
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MM/dd/yyyy').format(timestamp); 
    }
  }

  Future<String?> getChatbotChatId() async {
    try {
      QuerySnapshot chatSnapshot = await _firestore
          .collection('chat')
          .where('users', arrayContains: _currentUserId)
          .where('active', isEqualTo: true)
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
          .where('active', isEqualTo: true)
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

        var chats = snapshot.data!.docs
            .where((doc) => doc.id != _aiChatId) // Filter out AI chat
            .toList();

        // Assuming 'lastMessage' contains 'unread' (bool) & 'timestamp' (Timestamp)
        // Sort: Unread chats first, then by timestamp (newest first)
        chats.sort((a, b) {
          var aData = a['lastMessage'] as Map<String, dynamic>?;
          var bData = b['lastMessage'] as Map<String, dynamic>?;
          var aUnread = aData != null && aData['status'] == 'delivered'; // Assuming 'delivered' means unread
          var bUnread = bData != null && bData['status'] == 'delivered';
          if (aUnread == bUnread) { // If both are read or unread, sort by timestamp
            var aTimestamp = aData?['timestamp']?.toDate() ?? DateTime.now();
            var bTimestamp = bData?['timestamp']?.toDate() ?? DateTime.now();
            return bTimestamp.compareTo(aTimestamp); // Newest first
          }
          return aUnread ? -1 : 1; // Unread first
        });

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
              // Expanded ListView to display the chats
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chatData = chats[index];
                    var otherUserId = chatData['users'].firstWhere((u) => u != _currentUserId);
                    var chatID = chatData.id;

                    // Extracting lastMessage details
                    var lastMessage = chatData['lastMessage'] != null ? chatData['lastMessage'] as Map<String, dynamic> : null;
                    var lastMessageText = lastMessage?['message'] ?? '';
                    var lastMessageTimestamp = lastMessage?['timestamp'] != null ? (lastMessage!['timestamp'] as Timestamp).toDate() : DateTime.now();
                    var lastMessageStatus = lastMessage?['status'] ?? '';
                    var isUnread = lastMessageStatus == 'delivered'; // Assuming 'delivered' means unread
                    late String timestampText;

                    // Formatting timestamp
                    if(isUnread){
                      timestampText = "● ${_formatTimestamp(lastMessageTimestamp)}";
                    } else {
                      timestampText = _formatTimestamp(lastMessageTimestamp);
                    }

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
                            title: Text(
                              '$otherUserFname $otherUserSname',
                              style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                              ),
                            subtitle: Text(
                              lastMessageText,
                              style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                            ),
                            trailing: Text(
                              timestampText,
                              style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                            ),
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
