import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
      ),
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

          return Column(
            children: [
              // Add ListTile for AI chat at the top
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: Image.asset(
                    'lib/assets/images/chatcbt.webp',
                    scale: 1, 
                  ).image,
                ),
                title: const Text('AI Mental Health Assistant'),
                onTap: () {
                  // Implement navigation to the AI chat room
                  // Navigator.push(...);
                },
              ),
              // Use ListView.builder for the rest of the chat list
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var chatData = snapshot.data!.docs[index];
                    var otherUserId =
                        chatData['users'].firstWhere((u) => u != _currentUserId);

                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(otherUserId)
                            .get(),
                        builder: (context,
                            AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              leading: const CircleAvatar(),
                              title: const Text('Loading...'),
                              onTap: () {
                                // Implement onTap functionality
                              },
                            );
                          }

                          if (userSnapshot.hasError ||
                              !userSnapshot.hasData) {
                            return ListTile(
                              leading: const CircleAvatar(),
                              title: const Text('Error or no data'),
                              onTap: () {
                                // Implement onTap functionality
                              },
                            );
                          }

                          final otherUserDoc = userSnapshot.data!;
                          final otherUserFname = otherUserDoc['fname'];
                          final otherUserSname = otherUserDoc['sname'];
                          final String otherUserProfilePic = otherUserDoc['photoURL'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(otherUserProfilePic, scale: 1),
                            ),
                            title: Text('$otherUserFname $otherUserSname'),
                            onTap: () {
                              // Implement navigation to the specific chat room
                              // Navigator.push(...);
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
