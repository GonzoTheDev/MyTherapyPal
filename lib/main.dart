//import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_therapy_pal/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'config/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

FirebaseAuth auth = FirebaseAuth.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /*
  final messaging = FirebaseMessaging.instance;


  // Request permission for notifications if supported
  if (await messaging.isSupported()) {


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
    
    // Set vapid key
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
  }
*/

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  runApp(MyApp(isFirstTime: isFirstTime));
  if (isFirstTime) {
    await prefs.setBool('isFirstTime', false);
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  static const String title = 'MyTherapyPal';
  
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MainApp(isFirstTime: isFirstTime),
    );
  }
}

class MainApp extends StatelessWidget {
  final bool isFirstTime;
  static const String title = 'MyTherapyPal';
  const MainApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    Widget homeScreen = isFirstTime
        ? AnimatedSplashScreen(
            splashIconSize: double.infinity,
            duration: 3000,
            splash: Image.asset(
              'assets/images/splash.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            nextScreen: const Login(),
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.fade,
            backgroundColor: Colors.teal)
        : const Login();

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
          title: MainApp.title,
          theme: ThemeData(
            useMaterial3: false,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor: Colors.white,
          ),
          home: homeScreen);
    });
  }
}
