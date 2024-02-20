import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/services/generate_chat.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:my_therapy_pal/services/encryption/AES/aes.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';

class StartChat extends StatefulWidget {
  const StartChat({super.key});

  @override
  _StartChatState createState() => _StartChatState();
}

class _StartChatState extends State<StartChat> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();

  // Create a new instance of the firebase firestore
  var db = FirebaseFirestore.instance;

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Create a new instance of the RSA encryption 
  final rsaEncryption = RSAEncryption();

  // Get the user's profile data
  final uid = FirebaseAuth.instance.currentUser!.uid;
  
  

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {

      Future<String> chatId;
      String ouid = _userIdController.text;

      // Get the current user's public RSA key from the firestore
      final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
      final currentUserRSAPubKey = userProfileDoc['publicRSAKey'];

      // Get the other user's public RSA key from the firestore
      DocumentSnapshot userDoc = await db.collection("profiles").doc(ouid).get();
      String otherUserRSAPubKey = userDoc.get("publicRSAKey");

      // Generate an AES key for the ai chat room
      final aesKey = aesKeyEncryptionService.generateAESKey(16);

      // Encrypt the AES key with the current users public RSA key
      final currentUserEncryptedAESKey = rsaEncryption.encrypt(
        key: currentUserRSAPubKey,
        message: aesKey.toString(),
      );
      // Encrypt the AES key with the current users public RSA key
      final otherUserEncryptedAESKey = rsaEncryption.encrypt(
        key: otherUserRSAPubKey,
        message: aesKey.toString(),
      );

      // Generate a new chat with the ai chatbot
      chatId = GenerateChat(
        aesKey: aesKey,
        encryptedAESKey: currentUserEncryptedAESKey,
        uid: uid,
      ).generateUserChat(ouid, otherUserEncryptedAESKey); 

      
      // If the chat is successfully created, navigate to the chat list
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(
            builder: (context) => FutureBuilder<String>(
              future: chatId,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const Text('Error');
                } else {
                  return const AccountHomePage(initialIndex: 2);
                }
              },
            ),
              ),
              (route) => false,
            );
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start New Chat')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a User ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}