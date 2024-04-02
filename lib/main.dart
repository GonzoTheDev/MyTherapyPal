import 'dart:io';

import 'package:flutter/material.dart';
import 'package:my_therapy_pal/models/notifications.dart';
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

  if (DefaultFirebaseOptions.currentPlatform != DefaultFirebaseOptions.ios) {
    
    // Initialize the PushNotificationService
    PushNotificationService pushNotificationService = PushNotificationService();
    await pushNotificationService.initialize();

  }

  // Check if the app is being opened for the first time
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
          home: homeScreen,
      );
    });
  }
}
