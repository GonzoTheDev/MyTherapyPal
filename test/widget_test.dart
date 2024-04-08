import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/models/notifications.dart'; 
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef Callback = void Function(MethodCall call);

Future<void> setupFirebaseAuthMocks([Callback? customHandlers]) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseAuthMocks();
    setUpAll(() async {
      await Firebase.initializeApp();
    });
    testWidgets('main initializes Firebase and PushNotificationService', (WidgetTester tester) async {

      
      initializeApp();

      // Pump the widget
      await tester.pumpWidget(const MainApp(isFirstTime: false));
      await tester.pumpAndSettle();

      // Verify that PushNotificationService is initialized
      expect(PushNotificationService().isInitialized, true);
    }, skip: true);

    testWidgets('main sets isFirstTime flag correctly', (WidgetTester tester) async {
      // Pump the widget
      await tester.pumpWidget(const MainApp(isFirstTime: true));

      // Verify that isFirstTime is set to true on first time running the app
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('isFirstTime'), false);
    }, skip: true);

    testWidgets('Displays Splash Screen when first time', (WidgetTester tester) async {
      // Pump the widget
      await tester.pumpWidget(const MainApp(isFirstTime: true));

      // Verify Splash Screen is shown
      expect(find.byType(AnimatedSplashScreen), findsOneWidget);
    });

    testWidgets('Displays Login Screen when not first time', (WidgetTester tester) async {
      // Pump the widget
      await tester.pumpWidget(const MainApp(isFirstTime: false));

      // Verify Login Screen is shown
      expect(find.byType(Login), findsOneWidget);
    });

    testWidgets('App should have correct MaterialApp properties', (WidgetTester tester) async {
      await tester.pumpWidget(const MainApp(isFirstTime: false));

      // Verify MaterialApp properties
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
      expect(app.title, 'MyTherapyPal');
    });

    group('MainApp', () {
    testWidgets('displays Splash Screen when first time', (WidgetTester tester) async {
      // Pump the widget
      await tester.pumpWidget(const MainApp(isFirstTime: true));

      // Verify Splash Screen is shown
      expect(find.byType(AnimatedSplashScreen), findsOneWidget);
    });

    testWidgets('displays Login Screen when not first time', (WidgetTester tester) async {
      // Pump the widget
      await tester.pumpWidget(const MainApp(isFirstTime: false));

      // Verify Login Screen is shown
      expect(find.byType(Login), findsOneWidget);
    });

    testWidgets('has correct MaterialApp properties', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp(isFirstTime: false));

      // Verify MaterialApp properties
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, false);
      expect(app.title, 'MyTherapyPal');
    });
  });
}
