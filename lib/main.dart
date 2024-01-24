import 'package:flutter/material.dart';
import 'package:my_therapy_pal/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:dcdg/dcdg.dart';

FirebaseAuth auth = FirebaseAuth.instance;

// Main program function
void main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
	runApp(const MainApp());
}

/*
passwordMatch(pwd1, pwd2) {
  if (pwd1 == pwd2) {
    return true;
  } else {
    return false;
  }
}

// Create a user in firebase
createUser(user, pass) async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: user,
      password: pass,
    );
} on FirebaseAuthException catch (e) {
  if (e.code == 'weak-password') {
    print('The password provided is too weak.');
  } else if (e.code == 'email-already-in-use') {
    print('The account already exists for that email.');
  }
} catch (e) {
  print(e);
}
}

// Login a user in firebase
loginUser(user, pass) async {

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: user,
    password: pass
  );
  
}

// Logout a user in firebase
logoutUser() async {
  await FirebaseAuth.instance.signOut();
}
*/
// Main app widget
class MainApp extends StatelessWidget {
  final String title = 'MyTherapyPal';	
  const MainApp({Key? key}) : super(key: key);
	@override
	Widget build(BuildContext context) {
    return FlutterSizer(
      builder: (context, orientation, screenType) {
      return MaterialApp(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.cyan,
          scaffoldBackgroundColor: Color.fromARGB(255, 238, 235, 235),
        ),
        home: const Login(),
      );
	});
  }
}