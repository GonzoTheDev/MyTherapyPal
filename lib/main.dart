import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
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