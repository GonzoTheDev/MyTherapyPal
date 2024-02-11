import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

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

        // Add a new document with the new users uid set as the document ID
        db.collection("profiles").doc(uid).set({
          "fname": fname,
          "sname": sname,
          "userType": userType
          });

        // Add a new document to the chat collection for the new user to interact with the ai chatbot
        db.collection("chat").doc(uid).set({
          "lastMessage": {
            "lastMessageId": "",
            "message": "",
            "sender": "",
            "status": "",
            "timestamp": "",
          },
          "typingStatus": {
            "ai-mental-health-assistant": false,
            uid: false,
          },
          "users": ["ai-mental-health-assistant", uid],
        });

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
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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