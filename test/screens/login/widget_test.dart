import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/screens/login_screen.dart'; 
import 'package:my_therapy_pal/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../test/services/mock_auth_service.mocks.dart';
import '../../services/mock_firebase.dart';


void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('Login Screen Tests', () {
    // Mock the AuthService
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: Provider<AuthService>(
          create: (_) => mockAuthService,
          child: const Login(),
        ),
      );
    }

    testWidgets('Successful login navigates to the dashboard', (WidgetTester tester) async {
      when(mockAuthService.login(
        email: 'test@test.com', 
        password: 'tester'
      )).thenAnswer((_) async => Future.value('Success'));

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField).first, 'test@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'tester');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify the navigation has occurred
      expect(find.byType(AccountHomePage), findsOneWidget);
    });
  });
}
