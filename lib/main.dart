import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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

  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Request permission for notifications
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
  alert: true,
  announcement: false,
  badge: true,
  carPlay: false,
  criticalAlert: false,
  provisional: false,
  sound: true,
  );

  // Print permission status
  if (kDebugMode) {
    print('Permission granted: ${settings.authorizationStatus}');
  }
  
  // TODO: replace with your own VAPID key
  const vapidKey = "BIo28pk5GfuPkYHfZ1du1i_cNJa2Vxw8JpNA5yt0OEtW_uKxMNfBfwBZ0bkpvA3FsSgV2YN_QurC2lkzi4gJ5Hw";

  // use the registration token to send messages to users from your trusted server environment
  String? token;

  if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
    token = await messaging.getToken(
      vapidKey: vapidKey,
    );
  } else {
    token = await messaging.getToken();
  }

  if (kDebugMode) {
    print('Registration Token=$token');
  }
  // Run the app
	runApp(const MainApp());

}

// Main app widget
class MainApp extends StatelessWidget {
  final String title = 'MyTherapyPal';	
  const MainApp({super.key});
	@override
	Widget build(BuildContext context) {
    return FlutterSizer(
      builder: (context, orientation, screenType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
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
          useMaterial3: false,
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color.fromARGB(255, 238, 235, 235),
        ),
        home: AnimatedSplashScreen(
            splashIconSize: double.infinity,
            duration: 3000,
            splash: Image.asset(
              'assets/images/splash.png',
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