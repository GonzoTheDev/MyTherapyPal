import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/screens/login_screen.dart'; 
import 'package:my_therapy_pal/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../services/mock_auth_service.mocks.dart';
import '../../services/mock_firebase.dart';

class MockUser extends Mock implements auth.User {}
class MockAuthService extends Mock implements AuthService {
  @override
  Stream<auth.User?> authStateChanges() {
    return super.noSuchMethod(
      Invocation.method(#authStateChanges, []),
      returnValue: Stream.value(null),
      returnValueForMissingStub: Stream.value(null),
    );
  }

  @override
  Future<String?> login({required String email, required String password}) async {
    // Return a mock response or perform any necessary logic
    return 'Success';
  }
}

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

     testWidgets('Logged in user is navigated to AccountHomePage', (WidgetTester tester) async {
      // Create an instance of the MockAuthService
      final mockAuthService = MockAuthService();

      // Stub the authStateChanges method to return a mock user
      when(mockAuthService.authStateChanges()).thenAnswer((_) => Stream.value(MockUser()));

      await tester.pumpWidget(
        Provider<AuthService>.value(
          value: mockAuthService,
          child: const MaterialApp(home: Login()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the user is navigated to AccountHomePage
      expect(find.byType(AccountHomePage), findsOneWidget);
    });

    testWidgets('_submitForm() logs in the user and navigates to AccountHomePage', (WidgetTester tester) async {
      final mockAuthService = MockAuthService();
      when(mockAuthService.login(
        email: 'test@example.com',
        password: 'password',
      )).thenAnswer((_) async => 'Success');

      await tester.pumpWidget(
        Provider<AuthService>.value(
          value: mockAuthService,
          child: const MaterialApp(home: Login()),
        ),
      );

      // Enter email and password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password');

      // Tap the sign-in button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify that the login method is called with the correct arguments
      verify(mockAuthService.login(
        email: 'test@example.com',
        password: 'password',
      )).called(1);

      // Verify that the user is navigated to AccountHomePage
      expect(find.byType(AccountHomePage), findsOneWidget);
    });

    testWidgets('Successful login navigates to the dashboard', (WidgetTester tester) async {
      // Set up the behavior of the mocked login method
      when(mockAuthService.login(
        email: 'login_widget@test.com',
        password: 'WidgetTest1.',
      )).thenAnswer((_) async => 'Success');

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField).first, 'login_widget@test.com');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), 'WidgetTest1.');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify that the AccountHomePage is present
      expect(find.byType(AccountHomePage), findsOneWidget);
    });
  });
}
