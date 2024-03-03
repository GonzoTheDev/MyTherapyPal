import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/services/generate_chat.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';

class StartChat extends StatefulWidget {
  const StartChat({super.key});

  @override
  State<StartChat> createState() => _StartChatState();
}

class _StartChatState extends State<StartChat> {
  final _formKey = GlobalKey<FormState>();
  final _firstUserIdController = TextEditingController();
  final _secondUserIdController = TextEditingController();

  // Create a new instance of the Firebase Firestore
  var db = FirebaseFirestore.instance;

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Create a new instance of the RSA encryption
  final rsaEncryption = RSAEncryption();

  // Get the user's profile data
  //final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _firstUserIdController.dispose();
    _secondUserIdController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      Future<String> chatId;
      bool isAIChatbot = false;
      String firstUid = _firstUserIdController.text;
      String secondUid = _secondUserIdController.text;
      String firstUserRSAPubKey = "";
      String secondUserRSAPubKey = "";
      String targetUid = "";
      String secondUserEncryptedAESKey = "";

      

      if(firstUid == "ai-mental-health-assistant" || secondUid == "ai-mental-health-assistant") {

        // Set the chatbot flag to true
        isAIChatbot = true;

        // Check which user is the AI chatbot
        targetUid = firstUid != "ai-mental-health-assistant" ? firstUid : secondUid;

        print("Target UID: $targetUid");

        // Get the real user's public RSA key from Firestore
        final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(targetUid).get();
        firstUserRSAPubKey = userProfileDoc['publicRSAKey'];

        print("User RSA Public Key: $firstUserRSAPubKey");

      }else {

        // Get the first user's public RSA key from Firestore
      final userProfileDoc =
        await FirebaseFirestore.instance.collection('profiles').doc(firstUid).get();
        firstUserRSAPubKey = userProfileDoc['publicRSAKey'];

        // Get the second user's public RSA key from Firestore
      DocumentSnapshot userDoc =
        await db.collection("profiles").doc(secondUid).get();
        secondUserRSAPubKey = userDoc.get("publicRSAKey");

      }
      

      // Generate an AES key for the chat room
      final aesKey = aesKeyEncryptionService.generateAESKey(16);

      print("AES key generated.");

      // Encrypt the AES key with the current user's public RSA key
      final firstUserEncryptedAESKey = rsaEncryption.encrypt(
        key: firstUserRSAPubKey,
        message: aesKey.toString(),
      );

      print("AES key encrypted.");

      if(!isAIChatbot) {
        // Encrypt the AES key with the other user's public RSA key
          secondUserEncryptedAESKey = rsaEncryption.encrypt(
          key: secondUserRSAPubKey,
          message: aesKey.toString(),
        );
      }

      // Generate a new chat
      if(isAIChatbot) {
        chatId = GenerateChat(
          aesKey: aesKey,
          encryptedAESKey: firstUserEncryptedAESKey,
          uid: targetUid,
        ).generateAIChat();
      } else {
      chatId = GenerateChat(
        aesKey: aesKey,
        encryptedAESKey: firstUserEncryptedAESKey,
        uid: firstUid,
      ).generateUserChat(secondUid, secondUserEncryptedAESKey);
      }

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
                controller: _firstUserIdController,
                decoration: const InputDecoration(
                  labelText: 'First User ID',
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
              TextFormField(
                controller: _secondUserIdController,
                decoration: const InputDecoration(
                  labelText: 'Second User ID',
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
