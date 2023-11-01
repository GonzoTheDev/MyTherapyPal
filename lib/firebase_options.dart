// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'firebase_options.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDkImHd39IMfQNdytRVxFY3yhzQwcEwvrQ',
    appId: '1:159382536980:web:ec2dcfab18de1498333801',
    messagingSenderId: '159382536980',
    projectId: 'mytherapypal',
    authDomain: 'mytherapypal.firebaseapp.com',
    storageBucket: 'mytherapypal.appspot.com',
    measurementId: 'G-BRSDP2FNM2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqtGFY94S4kHd0rfuhPSzxjkPhfjKHcjw',
    appId: '1:159382536980:android:fe2a494fc91b980f333801',
    messagingSenderId: '159382536980',
    projectId: 'mytherapypal',
    storageBucket: 'mytherapypal.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCYGvhhUZWwWaDFZz8Aw03kAJxPLojDmN4',
    appId: '1:159382536980:ios:61703fb25c78994e333801',
    messagingSenderId: '159382536980',
    projectId: 'mytherapypal',
    storageBucket: 'mytherapypal.appspot.com',
    iosBundleId: 'com.example.myTherapyPal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCYGvhhUZWwWaDFZz8Aw03kAJxPLojDmN4',
    appId: '1:159382536980:ios:6e76b7d0b0b3b34a333801',
    messagingSenderId: '159382536980',
    projectId: 'mytherapypal',
    storageBucket: 'mytherapypal.appspot.com',
    iosBundleId: 'com.example.myTherapyPal.RunnerTests',
  );
}

