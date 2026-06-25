import 'package:flutter_test/flutter_test.dart';
import 'package:neko/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const NekoMain());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
  }

  testWidgets('Hero screen displays correctly', (tester) async {
    await pumpApp(tester);

    expect(find.text('neko'), findsOneWidget);
    expect(find.text("Your cat's favorite app"), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('Navigation to onboarding works', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Get Started'));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('First, tell us about your cat'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Navigation to sign in works', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('I already have an account'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
