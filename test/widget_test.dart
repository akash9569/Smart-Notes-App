import 'package:flutter_test/flutter_test.dart';
import 'package:smart_notes/main.dart';

void main() {
  testWidgets('LifeOS smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartNotesApp(hasSeenWelcome: true));

    // Verify that we start at the Login Screen.
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
