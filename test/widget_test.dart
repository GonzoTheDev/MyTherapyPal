import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart'; 
import 'package:my_therapy_pal/screens/login_screen.dart';

typedef Callback = void Function(MethodCall call);

Future<void> setupFirebaseAuthMocks([Callback? customHandlers]) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
}

void main() {
  
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

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
}
