import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:my_therapy_pal/services/encryption/AES/aes.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String? _aiChatId; // Store the AI chat ID

  // Create a new instance of the RSA encryption 
  final rsaEncryption = RSAEncryption();

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

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

  Future<Uint8List> _decryptAESKey(String encryptedAESKey) async {
    // Decrypt the AES key using the user's private RSA key
    final prefs = await SharedPreferences.getInstance();
    final privateKeyRSA = prefs.getString('privateKeyRSA');
    if (privateKeyRSA == null) {
      throw 'Private key not found';
    }
    final decryptedAESKeyString = RSAEncryption().decrypt(key: privateKeyRSA, message: encryptedAESKey);
      // Remove the brackets and split by comma
      List<String> byteStrings = decryptedAESKeyString.substring(1, decryptedAESKeyString.length - 1).split(", ");
      // Convert each substring to an integer and then to a Uint8List
    final decryptedAESKey = Uint8List.fromList(byteStrings.map((s) => int.parse(s)).toList());
    return decryptedAESKey;
  }

  String _decryptMessage(String encryptedMessage, Uint8List key, String messageID) {
    String decryptedMessage;
    try {
          final utfToKey = encrypt.Key(key);
          Uint8List ivGen = aesKeyEncryptionService.generateIVFromDocId(messageID);
          final iv = encrypt.IV(ivGen);
          decryptedMessage = AESEncryption(utfToKey, iv).decryptData(encryptedMessage);
        } catch (e) {
          // Handle decryption errors or leave encrypted if decryption fails
          decryptedMessage = "[Encrypted message]";
        }
    return decryptedMessage;
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
  
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete chat from the chat collection
      await _firestore.collection('chat').doc(chatId).delete();
    } catch (e) {
      print('Error deleting chat: $e');
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

        // Filter out the AI chat from the list of chats
        var chats = snapshot.data!.docs
            .where((doc) => doc.id != _aiChatId)
            .toList();

        // Sort the chats by unread status and timestamp
        chats.sort((a, b) {
          var aData = a['lastMessage'] as Map<String, dynamic>?;
          var bData = b['lastMessage'] as Map<String, dynamic>?;
          var aUnread = aData != null && aData['status'] == 'delivered'; 
          var bUnread = bData != null && bData['status'] == 'delivered';

          // If both are read or unread, sort by timestamp
          if (aUnread == bUnread) { 
            var aTimestamp = aData?['timestamp']?.toDate() ?? DateTime.now();
            var bTimestamp = bData?['timestamp']?.toDate() ?? DateTime.now();
            return bTimestamp.compareTo(aTimestamp);
          }

          // Return unread first
          return aUnread ? -1 : 1; 
        });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0), 
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/chatcbt.webp'),
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
              ),

              // Expanded ListView to display the chats
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    var chatData = chats[index];
                    var otherUserId = chatData['users'].firstWhere((u) => u != _currentUserId);
                    var chatID = chatData.id;
                    var chatAESKey = chatData['keys'][_currentUserId];

                  // Using FutureBuilder to handle the asynchronous decryption
                  return FutureBuilder<Uint8List>(
                    future: _decryptAESKey(chatAESKey),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          leading: CircleAvatar(),
                          title: Text('Decrypting...'),
                        );
                      } else if (snapshot.hasError) {
                        return const ListTile(
                          leading: CircleAvatar(),
                          title: Text('Error decrypting'),
                        );
                      }

                      // Setup chat variables
                      var decryptedAESKey = snapshot.data!;
                      var lastMessage = chatData['lastMessage'] != null ? chatData['lastMessage'] as Map<String, dynamic> : null;
                      var lastMessageText = lastMessage?['message'] ?? '';
                      var lastMessageTimestamp = lastMessage?['timestamp'] != null ? (lastMessage!['timestamp'] as Timestamp).toDate() : DateTime.now();
                      var lastMessageStatus = lastMessage?['status'] ?? '';
                      var isUnread = lastMessageStatus == 'delivered' && lastMessage?['sender'] != _currentUserId;
                      var lastMessageID = lastMessage?['lastMessageId'] ?? '';
                      var decryptedMessage = _decryptMessage(lastMessageText, decryptedAESKey, lastMessageID);
                      var timestampText = _formatTimestamp(lastMessageTimestamp);

                      if(decryptedMessage == "[Encrypted message]"){
                        decryptedMessage = "";
                      }

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

                          return GestureDetector(
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Chat'),
                                  content: const Text('Are you sure you want to delete this chat?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop(); 
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Delete'),
                                      onPressed: () async {
                                        await deleteChat(chatID);
                                        Navigator.of(context).pop(); 
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(otherUserProfilePic),
                            ),
                            title: Text(
                              '$otherUserFname $otherUserSname',
                              style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.normal),
                              ),
                            subtitle: Text(
                              decryptedMessage,
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
                          ));
                        },
                      ),
                    );
                  });
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
