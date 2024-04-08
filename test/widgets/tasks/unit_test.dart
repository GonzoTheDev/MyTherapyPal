import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_therapy_pal/widgets/tasks.dart';

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
  group('Tasks', () {
    testWidgets('Tasks widget renders correctly', (WidgetTester tester) async {
      // Build the Tasks widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Tasks(),
        ),
      );

      // Verify that the Tasks widget is rendered
      expect(find.byType(Tasks), findsOneWidget);
    });

  });
}