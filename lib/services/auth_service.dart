import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_therapy_pal/config/firebase_options.dart';
import 'package:my_therapy_pal/services/encryption/AES/aes.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';
import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:my_therapy_pal/services/generate_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // Create a new instance of the RSA encryption 
  final rsaEncryption = RSAEncryption();

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Create a new instance of the firebase firestore
  var db = FirebaseFirestore.instance;

  // Logout a user in firebase
  logoutUser() async {
    await FirebaseAuth.instance.signOut();
  }
  
  // Password match check
  passwordMatch(pwd1, pwd2) {
    if (pwd1 == pwd2) {
      return true;
    } else {
      return false;
    }
  }

  Future<String> startChat(String tuid, String uid, String public) async {
    String firstUid = uid;
    String secondUid = tuid;

    if(firstUid == secondUid) {
      return 'Cannot start chat with yourself';
    }

    // Get the first user's public RSA key
    String firstUserRSAPubKey = public;

    // Get the second user's public RSA key from Firestore
    DocumentSnapshot userDoc = await db.collection("profiles").doc(secondUid).get();
    String secondUserRSAPubKey = userDoc.get("publicRSAKey");

    // Generate an AES key for the chat room
    final aesKey = aesKeyEncryptionService.generateAESKey(16);

    // Encrypt the AES key with the current user's public RSA key
    final firstUserEncryptedAESKey = rsaEncryption.encrypt(
      key: firstUserRSAPubKey,
      message: aesKey.toString(),
    );

    // Encrypt the AES key with the second user's public RSA key
    final secondUserEncryptedAESKey = rsaEncryption.encrypt(
      key: secondUserRSAPubKey,
      message: aesKey.toString(),
    );

    // Generate a new chat
    String chatIdValue = await GenerateChat(
      aesKey: aesKey,
      encryptedAESKey: firstUserEncryptedAESKey,
      uid: firstUid,
    ).generateUserChat(secondUid, secondUserEncryptedAESKey);

    if(chatIdValue != "") {
      return 'Success';
    } else {
      return 'Failed to start chat';
    }
  }

  Future<String?> registration({
    required String email,
    required String password,
    required String passwordConfirm,
    required String fname,
    required String sname,
    required String userType,
    String? address,
    String? phone,
    List<String>? disciplines,
    String? ratesFrom,
    String? ratesTo,
    bool? isTherapistListingEnabled,
    required double latitude,
    required double longitude,
  }) async {
    if (password != passwordConfirm) {
      return 'Passwords do not match';
    } 
    // Check for minimum length of 8 characters
    else if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    } 
    // Check for at least one uppercase letter
    else if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one capital letter';
    } 
    // Check for at least one number
    else if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    } 
    // Check for at least one symbol
    else if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one symbol';
    }else{
      if(userType == "Therapist"){
        if(address == null){
          return 'Address is required';
        }
        else if(disciplines == null){
          return 'At least one discipline is required';
        }
      }
      try {

        // Create a new user in firebase
        UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get the new users uid
        User? user = result.user;
        final uid = user!.uid;

        // Get the default profile picture
        const profilePicture = 'https://firebasestorage.googleapis.com/v0/b/mytherapypal.appspot.com/o/240px-Placeholder_no_text.svg.png?alt=media';

        // generate RSA key pair
        final pair = await rsaEncryption.generateRSAKeyPair();
        final public = pair.publicKey;
        final private = pair.privateKey; 

        // Obtain shared preferences.
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Save users AES private key in shared preferences
        await prefs.setString('privateKeyRSA', private);

        // Generate a random salt for the user
        final salt = rsaEncryption.generateRandomSalt();
        
        // Derive a key from the password and salt
        final derivedKeyBytes = rsaEncryption.deriveKey(password, salt);
        
        // Convert the derived key bytes to an `encrypt.Key`
        final derivedKey = encrypt.Key(derivedKeyBytes);

        // Create a new IV
        final iv = encrypt.IV.fromLength(16);
        
        // Create a new instance of the AES encryption with the derived key
        final encryptRSA = AESEncryption(derivedKey, iv);
        
        // Encrypt the RSA private key with the password derived AES key
        final encryptedRSAkey = await encryptRSA.encryptData(private);
        
        print("Generating AES key for AI Chat Room...");
        // Generate an AES key for the ai chat room
        final aesKey = aesKeyEncryptionService.generateAESKey(32);
        print("AES key generated...");
        // Encrypt the AES key with the public key
        final encryptedAESKey = rsaEncryption.encrypt(
          key: public,
          message: aesKey.toString(),
        );

        // Get the users notification token from shared preferences
        final notificationToken = prefs.getString('notifications_token');

        // If the notifications token is null, set it to 'token_not_granted'
        if (notificationToken == null) {
          await prefs.setString('notifications_token', 'not_granted');
          print("Notifications permission not granted...");
        }

        // If platform is web, get the web notification token from shared preferences
        final notificationTokenWeb = prefs.getString('notifications_token_web');

        // If the notifications token is null, set it to 'not_granted'
        if (notificationTokenWeb == null) {
          await prefs.setString('notifications_token_web', 'not_granted');
          print("Notifications web permission not granted...");
        }

        // Add a new document with the new users uid set as the document ID
        db.collection("profiles").doc(uid).set({
          "fname": fname,
          "sname": sname,
          "userType": userType,
          "photoURL": profilePicture,
          "publicRSAKey": public,
          "salt": salt,
          "encryptedRSAKey": encryptedRSAkey,
          "IV": iv.bytes,
          "notifications_token": notificationToken,
          "notifications_token_web": notificationTokenWeb,
          "last_login": Timestamp.now(),
          });

          if(userType == "Therapist"){
            db.collection("listings").doc(uid).set({
              "fname": fname,
              "sname": sname,
              "address": address,
              "phone": phone,
              "disciplines": disciplines,
              "ratesFrom": ratesFrom,
              "ratesTo": ratesTo,
              "active": isTherapistListingEnabled,
              "location": GeoPoint(latitude, longitude),
              "approved": false,
              "uid": uid,
              "pic_url": "https://firebasestorage.googleapis.com/v0/b/mytherapypal.appspot.com/o/240px-Placeholder_no_text.svg.png?alt=media",
              "clients": [0],
            });
          }

        // Generate a chat with the ai chatbot
        GenerateChat(
          aesKey: aesKey,
          encryptedAESKey: encryptedAESKey,
          fname: fname,
          uid: uid,
        ).generateAIChat();

        String demoUser;

        if(userType == "Therapist"){
          // Generate a chat with a demo user
          demoUser = "DENWmEaRrQT1JpCyUJofevPhJMD2";
        } else {
          // Generate a chat with a demo user
          demoUser = "DENWmEaRrQT1JpCyUJofevPhJMD2";
        }

        // Generate a chat with a demo user
        final demoChat = await startChat(demoUser, uid, public);

        if(demoChat == "Success"){
          print("Demo chat started successfully...");
        } else {
          print("Failed to start demo chat...");
        }

        return 'Success';

      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          return 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          return 'The account already exists for that email.';
        } else {
          return e.message;
        }
      } catch (e) {
        return e.toString();
      }
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Get the current users uid
      final uid = FirebaseAuth.instance.currentUser!.uid;

      
      // Fetch the user's profile from Firestore
      final profile = await db.collection("profiles").doc(uid).get();

      // Check if the user has a notifications token for web in their profile
      if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
        try{ 

        // Check if the 'notifications_token' field exists in the user's profile
        if (profile.data()!.containsKey('notifications_token_web')!=true) {

          print("User does not have a web notifications token in their profile..."); 

          // Try to get the notifications token from shared preferences
          String? notificationTokenWeb = prefs.getString('notifications_token_web');

          // If the token is not available in shared preferences, use 'not_granted'
          notificationTokenWeb ??= 'not_granted';

          // Update the user's profile in Firestore with the notifications token
          await db.collection("profiles").doc(uid).update({
            "notifications_token_web": notificationTokenWeb,
          });

          print("Notifications token added to the user's profile...");
        } else {
          print("User has a notifications token in their profile...");
          // Try to get the notifications token from shared preferences
          String? notificationTokenWeb = prefs.getString('notifications_token_web');
          // Get the notifications token from the user's profile
          String fetchedNotificationTokenWeb = profile.get('notifications_token_web');
          // If the shared preferences token is different from the fetched token, update the user's profile
          if (notificationTokenWeb != fetchedNotificationTokenWeb) {
            print("Updating the user's notifications token in their profile...");
            await db.collection("profiles").doc(uid).update({
              "notifications_token_web": notificationTokenWeb,
            });
          }
        }
        Timestamp currentTime = Timestamp.now();
        await db.collection("profiles").doc(uid).update({
            "last_login": currentTime,
        });
        print("Last login timestamp added to the user's profile...");
        } catch(firestoreException) {
          print(firestoreException);
        }
      } 

      // Else if the platform is not web
      else {
        try{ 

        // Check if the 'notifications_token' field exists in the user's profile
        if (profile.data()!.containsKey('notifications_token')!=true) {

          print("User does not have a notifications token in their profile..."); 

          // Try to get the notifications token from shared preferences
          String? notificationToken = prefs.getString('notifications_token');

          // If the token is not available in shared preferences, use 'not_granted'
          notificationToken ??= 'not_granted';

          // Update the user's profile in Firestore with the notifications token
          await db.collection("profiles").doc(uid).update({
            "notifications_token": notificationToken,
          });

          print("Notifications token added to the user's profile...");
        } else {
          print("User has a notifications token in their profile...");
          // Try to get the notifications token from shared preferences
          String? notificationToken = prefs.getString('notifications_token');
          // Get the notifications token from the user's profile
          String fetchedNotificationToken = profile.get('notifications_token');
          // If the shared preferences token is different from the fetched token, update the user's profile
          if (notificationToken != fetchedNotificationToken) {
            print("Updating the user's notifications token in their profile...");
            await db.collection("profiles").doc(uid).update({
              "notifications_token": notificationToken,
            });
          }
        }
        Timestamp currentTime = Timestamp.now();
        await db.collection("profiles").doc(uid).update({
            "last_login": currentTime,
        });
        print("Last login timestamp added to the user's profile...");
        } catch(firestoreException) {
          print(firestoreException);
        }
      }
      
      
      // Get the users encrypted RSA key from the firestore
      final encryptedRSAKey = profile.get('encryptedRSAKey');

      // Get the users IV from the firestore
      List<dynamic> fetchedIvBytesDynamic = profile.get('IV');

      // Cast it to a List<int>
      List<int> fetchedIvBytes = fetchedIvBytesDynamic.cast<int>();

      // Now, you can use fetchedIvBytes to create an encrypt.IV object
      final iv = encrypt.IV(Uint8List.fromList(fetchedIvBytes));

      // Get the users salt from the firestore
      List<int> intList = List<int>.from(profile.get('salt'));
      Uint8List salt = Uint8List.fromList(intList);

      print("Deriving a key from the password and salt...");

      // Derive a key from the password and salt
      final derivedKeyBytes = rsaEncryption.deriveKey(password, salt);

      print("Converting the derived key bytes to an `encrypt.Key...");

      // Convert the derived key bytes to an `encrypt.Key`
      final derivedKey = encrypt.Key(derivedKeyBytes);

      print("Creating a new instance of the RSA encryption service with the derived key...");

      // Create a new instance of the RSA encryption service with the derived key
      final encryptRSA = AESEncryption(derivedKey, iv);

      print("Decrypting the RSA key with the password derived AES key...");

      // Decrypt the RSA key with the password derived AES key
      final decryptedRSAKey = await encryptRSA.decryptData(encryptedRSAKey);

      print("RSA key decrypted...");

      // Save users AES private key in shared preferences
      await prefs.setString('privateKeyRSA', decryptedRSAKey);

      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'invalid-login-credentials') {
        return 'Wrong password provided for that user.';
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }
}