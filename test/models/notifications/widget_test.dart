// Import the required packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_therapy_pal/models/notifications.dart';

import 'unit_test.mocks.dart';

// Create a mock class for FirebaseMessaging
class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

// Create a mock class for SharedPreferences
//class MockSharedPreferences extends Mock implements SharedPreferences {}

typedef Callback = void Function(MethodCall call);

Future<void> setupFirebaseMocks([Callback? customHandlers]) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

void main() {

  setupFirebaseMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });
  
  group('PushNotificationService', () {
    late PushNotificationService service;
    late MockFirebaseMessaging mockMessaging;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockMessaging = MockFirebaseMessaging();
      mockPrefs = MockSharedPreferences();
      service = PushNotificationService();
    });

    test('initialize() requests permission and updates token', () async {
      // Arrange
      when(mockMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).thenAnswer((_) async => Future.value(const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.disabled,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.disabled,
          criticalAlert: AppleNotificationSetting.disabled,
          sound: AppleNotificationSetting.enabled, 
          lockScreen: AppleNotificationSetting.disabled, 
          notificationCenter: AppleNotificationSetting.disabled, 
          showPreviews: AppleShowPreviewSetting.always, 
          timeSensitive: AppleNotificationSetting.disabled,
          )));
      when(mockMessaging.getToken()).thenAnswer((_) async => 'test_token');
      when(SharedPreferences.getInstance()).thenAnswer((_) async => mockPrefs);

      // Act
      await service.initialize();

      // Assert
      verify(mockMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
      verify(mockMessaging.getToken()).called(1);
      verify(mockPrefs.setString('notifications_token', 'test_token')).called(1);
    }, skip: true);

    test('initialize() updates token when permission is denied', () async {
      // Arrange
      when(mockMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).thenAnswer((_) async => Future.value(const NotificationSettings(
            authorizationStatus: AuthorizationStatus.denied,
            alert: AppleNotificationSetting.enabled,
            announcement: AppleNotificationSetting.disabled,
            badge: AppleNotificationSetting.enabled,
            carPlay: AppleNotificationSetting.disabled,
            criticalAlert: AppleNotificationSetting.disabled,
            sound: AppleNotificationSetting.enabled, 
            lockScreen: AppleNotificationSetting.disabled, 
            notificationCenter: AppleNotificationSetting.disabled, 
            showPreviews: AppleShowPreviewSetting.always, 
            timeSensitive: AppleNotificationSetting.disabled,
          )));
      when(SharedPreferences.getInstance())
          .thenAnswer((_) async => mockPrefs);

      // Act
      await service.initialize();

      // Assert
      verify(mockMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
      verify(mockPrefs.setString('notifications_token', 'not_granted')).called(1);
    }, skip: true);

    test('backgroundHandler() logs the message ID', () async {
      // Arrange
      const message = RemoteMessage(messageId: 'test_message_id');

      // Act
      await service.backgroundHandler(message);

      // Assert
      expect(service.backgroundHandlerCalled, true);
    });
  });
}