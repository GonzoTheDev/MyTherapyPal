import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<String?> registration({
    required String email,
    required String password,
    required String passwordConfirm,
    required String fname,
    required String sname,
    required String userType,
  }) async {
    if (!passwordMatch(password, passwordConfirm)) {
      return 'Passwords do not match';
    }else if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }else{
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
        const profilePicture = 'lib/assets/images/default_profile_picture.jpg';

        // generate RSA key pair
        final pair = rsaEncryption.generateRSAKeyPair();
        final public = pair.publicKey;
        final private = pair.privateKey;

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
        
        // Generate an AES key for the ai chat room
        final aesKey = aesKeyEncryptionService.generateAESKey(16);

        // Encrypt the AES key with the public key
        final encryptedAESKey = rsaEncryption.encrypt(
          key: public,
          message: aesKey.toString(),
        );

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
          });

        // Generate a chat with the ai chatbot
        GenerateChat(
          aesKey: aesKey,
          encryptedAESKey: encryptedAESKey,
          fname: fname,
          uid: uid,
        ).generateAIChat();


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

      // Get the users profile from the firestore
      final profile = await db.collection("profiles").doc(uid).get();

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