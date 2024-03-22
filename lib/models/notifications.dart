import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_therapy_pal/config/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    
      // Request permission for push notifications
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        await _updateUserToken();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('User declined or has not accepted permission');
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('notifications_token', 'not_granted');
      } else {
        print('Permission not determined, requesting...');
        // Handle not determined permission state if needed, it's included in the initial permission request
        await _updateUserToken();
      }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  }

  Future<void> backgroundHandler(RemoteMessage message) async {
    print('Handling a background message ${message.messageId}');
  }

  Future<void> _updateUserToken() async {

    String? token;
    const vapidKey = "BIo28pk5GfuPkYHfZ1du1i_cNJa2Vxw8JpNA5yt0OEtW_uKxMNfBfwBZ0bkpvA3FsSgV2YN_QurC2lkzi4gJ5Hw";

    if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
      token = await _fcm.getToken(
        vapidKey: vapidKey,
      );
      if (token != null) {
      // Save the token in SharedPreferences for later use
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('notifications_token_web', token);
      print('Web token saved in SharedPreferences for later use: $token');
    }
    } else {
      token = await _fcm.getToken();
      if (token != null) {
        // Save the token in SharedPreferences for later use
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('notifications_token', token);
        print('Token saved in SharedPreferences for later use: $token');
      }
    }

    
  }
}