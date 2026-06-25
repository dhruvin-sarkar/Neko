import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neko/app/theme/app_colors.dart';
import 'package:neko/shared/widgets/neko_pill_button.dart';

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

  group('NekoPillButton', () {
    testWidgets('shows its label and fires onPressed when tapped', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NekoPillButton(label: 'Continue', onPressed: () => taps++),
          ),
        ),
      );

      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('does not fire onPressed while loading', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NekoPillButton(
              label: 'Saving',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(NekoPillButton));
      await tester.pump();

      expect(taps, 0);
    });
  });
}
