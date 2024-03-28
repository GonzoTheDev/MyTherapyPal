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

  // Set to true to disable tests
  const disabled = true; 
  
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
        email: 'login_widget@test.com', 
        password: 'WidgetTest1.'
      )).thenAnswer((_) async => Future.value('Success'));
      

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField).first, 'login_widget@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'WidgetTest1.');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 30)); // Increases the timeout


      /*/ Add a print statement to list all widgets found
      tester.allWidgets.forEach((widget) {
        print(widget.toString());
      });*/

      // Verify the navigation has occurred
      expect(find.byType(AccountHomePage), findsOneWidget);
    }, skip: disabled);
  });
}
