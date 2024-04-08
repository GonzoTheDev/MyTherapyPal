import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/config/firebase_options.dart';

void main() {
  group('DefaultFirebaseOptions', () {
    test('currentPlatform returns correct options for android', () {
      final options = DefaultFirebaseOptions.currentPlatform;
      expect(options, equals(DefaultFirebaseOptions.android));
    });

    test('web options are correct', () {
      expect(DefaultFirebaseOptions.web.apiKey,
          'AIzaSyDkImHd39IMfQNdytRVxFY3yhzQwcEwvrQ');
      expect(DefaultFirebaseOptions.web.appId,
          '1:159382536980:web:ec2dcfab18de1498333801');
      expect(DefaultFirebaseOptions.web.messagingSenderId, '159382536980');
      expect(DefaultFirebaseOptions.web.projectId, 'mytherapypal');
      expect(DefaultFirebaseOptions.web.authDomain,
          'mytherapypal.firebaseapp.com');
      expect(DefaultFirebaseOptions.web.storageBucket, 'mytherapypal.appspot.com');
      expect(DefaultFirebaseOptions.web.measurementId, 'G-BRSDP2FNM2');
    });

    test('android options are correct', () {
      expect(DefaultFirebaseOptions.android.apiKey,
          'AIzaSyDqtGFY94S4kHd0rfuhPSzxjkPhfjKHcjw');
      expect(DefaultFirebaseOptions.android.appId,
          '1:159382536980:android:48e66458ba74bfb0333801');
      expect(DefaultFirebaseOptions.android.messagingSenderId, '159382536980');
      expect(DefaultFirebaseOptions.android.projectId, 'mytherapypal');
      expect(DefaultFirebaseOptions.android.storageBucket, 'mytherapypal.appspot.com');
    });

    test('iOS options are correct', () {
      expect(DefaultFirebaseOptions.ios.apiKey,
          'AIzaSyCYGvhhUZWwWaDFZz8Aw03kAJxPLojDmN4');
      expect(DefaultFirebaseOptions.ios.appId,
          '1:159382536980:ios:fda062a6a35c217a333801');
      expect(DefaultFirebaseOptions.ios.messagingSenderId, '159382536980');
      expect(DefaultFirebaseOptions.ios.projectId, 'mytherapypal');
      expect(DefaultFirebaseOptions.ios.storageBucket, 'mytherapypal.appspot.com');
      expect(DefaultFirebaseOptions.ios.iosBundleId, 'com.myTherapyPal');
    });

    test('macOS options are correct', () {
      expect(DefaultFirebaseOptions.macos.apiKey,
          'AIzaSyCYGvhhUZWwWaDFZz8Aw03kAJxPLojDmN4');
      expect(DefaultFirebaseOptions.macos.appId,
          '1:159382536980:ios:bed67e6e406d2f1f333801');
      expect(DefaultFirebaseOptions.macos.messagingSenderId, '159382536980');
      expect(DefaultFirebaseOptions.macos.projectId, 'mytherapypal');
      expect(DefaultFirebaseOptions.macos.storageBucket, 'mytherapypal.appspot.com');
      expect(DefaultFirebaseOptions.macos.iosBundleId,
          'com.myTherapyPal.RunnerTests');
    });

    test('Windows options are correct', () {
      expect(DefaultFirebaseOptions.windows.apiKey,
          'AIzaSyCYGvhhUZWwWaDFZz8Aw03kAJxPLojDmN4');
      expect(DefaultFirebaseOptions.windows.appId,
          '1:159382536980:ios:bed67e6e406d2f1f333801');
      expect(DefaultFirebaseOptions.windows.messagingSenderId, '159382536980');
      expect(DefaultFirebaseOptions.windows.projectId, 'mytherapypal');
      expect(DefaultFirebaseOptions.windows.storageBucket, 'mytherapypal.appspot.com');
      expect(DefaultFirebaseOptions.windows.iosBundleId,
          'com.myTherapyPal.RunnerTests');
    });

    test('Windows options are correct', () {
      expect(DefaultFirebaseOptions.linux.apiKey,
          'AIzaSyCYGvhhUZWwWaDFZz8Aw03kAJxPLojDmN4');
      expect(DefaultFirebaseOptions.linux.appId,
          '1:159382536980:ios:bed67e6e406d2f1f333801');
      expect(DefaultFirebaseOptions.linux.messagingSenderId, '159382536980');
      expect(DefaultFirebaseOptions.linux.projectId, 'mytherapypal');
      expect(DefaultFirebaseOptions.linux.storageBucket, 'mytherapypal.appspot.com');
      expect(DefaultFirebaseOptions.linux.iosBundleId,
          'com.myTherapyPal.RunnerTests');
    });

    test('unsupported platform throws UnsupportedError', () {
      expect(() {
        debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
        DefaultFirebaseOptions.currentPlatform;
      }, throwsUnsupportedError);
    });
  });
}