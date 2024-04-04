
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/config/firebase_options.dart';
import 'package:my_therapy_pal/models/notifications.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  group('PushNotificationService', () {

    late PushNotificationService service;

    setUp(() {
      service = PushNotificationService();
    });

    test('pushNotificationService() initializes successfully', () async {
      // Assert success
      expect(service, isNotNull);
      expect(service, isA<PushNotificationService>());
    });


  });
}