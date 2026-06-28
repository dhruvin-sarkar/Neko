import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neko/app/theme/app_colors.dart';
import 'package:neko/core/widgets/neko_button.dart';

void main() {
  setUpAll(() {
    // Keep tests offline and deterministic — no network font fetches.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppColors.catColorFor', () {
    test('maps known coat types to their colors', () {
      expect(AppColors.catColorFor('ginger'), AppColors.coatGinger);
      expect(AppColors.catColorFor('black'), AppColors.coatBlack);
      expect(
        AppColors.catColorFor('tortoiseshell'),
        AppColors.coatTortoiseshell,
      );
    });

    test('falls back to the "other" color for unknown types', () {
      expect(AppColors.catColorFor('not-a-color'), AppColors.coatOther);
    });
  });

  group('NekoButton', () {
    testWidgets('shows its label and fires onPressed when tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NekoButton.primary(
              label: 'Continue',
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('CONTINUE'), findsOneWidget);

      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('does not fire onPressed when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NekoButton.primary(
              label: 'Disabled',
              enabled: false,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NekoButton));
      await tester.pumpAndSettle();

      expect(taps, 0);
    });
  });
}
