import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_therapy_pal/models/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../test_settings.dart';
import 'unit_test.mocks.dart';

//@GenerateNiceMocks([MockSpec<FirebaseMessaging>()])
//@GenerateMocks([SharedPreferences])

final TestSettings testSettings = TestSettings();

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
  
  late PushNotificationService pushNotificationService;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockSharedPreferences = MockSharedPreferences();
    pushNotificationService = PushNotificationService();
  });

  
  test('initialize should request permission and update user token', () async {
    // Arrange
    const settings = NotificationSettings(
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
    );
    when(mockFirebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    )).thenAnswer((_) async => settings);
    when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => 'mock_token');
    when(mockSharedPreferences.setString('notifications_token', 'mock_token'))
        .thenAnswer((_) async => true);

    // Act
    await pushNotificationService.initialize();

    // Assert
    verify(mockFirebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    )).called(1);
    verify(mockFirebaseMessaging.getToken()).called(1);
    verify(mockSharedPreferences.setString('notifications_token', 'mock_token')).called(1);
  }, skip: TestSettings.notifications[0]['skip'] as bool);

  test('updateUserToken should save the token in SharedPreferences', () async {
    // Arrange
    const mockToken = 'mock_token';
    when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => mockToken);
    
    // Act
    await pushNotificationService.updateUserToken();

    // Assert
    verify(mockFirebaseMessaging.getToken()).called(1);
    verify(mockSharedPreferences.setString('notifications_token', mockToken)).called(1);
  }, skip: TestSettings.notifications[1]['skip'] as bool);
}