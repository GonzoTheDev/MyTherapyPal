import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_therapy_pal/config/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool isInitialized = false;
  bool backgroundHandlerCalled = false;

  Future<void> initialize() async {
      isInitialized = true;
    
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
        await updateUserToken();
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('notifications_token', 'not_granted');
      } else {
        await updateUserToken();
      }

    // Handle messages in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Handle messages in the background
    FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  }

  Future<void> backgroundHandler(RemoteMessage message) async {
    print('Handling a background message ${message.messageId}');
    backgroundHandlerCalled = true;
  }

  Future<void> updateUserToken() async {

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