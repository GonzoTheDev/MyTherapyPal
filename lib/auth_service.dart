import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

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
  }) async {
    if (!passwordMatch(password, passwordConfirm)) {
      return 'Passwords do not match';
    }else if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }else{
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
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