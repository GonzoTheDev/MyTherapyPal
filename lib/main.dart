import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';


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
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.cyan,
          scaffoldBackgroundColor: const Color.fromARGB(255, 238, 235, 235),
        ),
        home: AnimatedSplashScreen(
            splashIconSize: double.infinity,
            duration: 3000,
            splash: Image.asset(
              'lib/assets/images/splash.png',
              width: 300, // Adjust the width according to your preference
              height: 300, // Adjust the height according to your preference
              fit: BoxFit.contain, // Adjust the BoxFit property as needed
            ),
            nextScreen: const Login(),
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.fade,
            backgroundColor: Colors.teal
            )
            
      );
	});
  }
}