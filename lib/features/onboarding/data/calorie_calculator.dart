import 'dart:math' as math;

/// Computes a cat's suggested daily calorie target from weight and activity.
///
/// Uses the Resting Energy Requirement (RER = 70 × weight^0.75) scaled by an
/// activity factor, rounded to whole kcal. Shared by onboarding and editing so
/// the target stays consistent.
abstract final class CalorieCalculator {
  const CalorieCalculator._();

  static int dailyTarget({required double weightKg, required String activity}) {
    if (weightKg <= 0) return 0;
    final double rer = 70 * math.pow(weightKg, 0.75).toDouble();
    final double factor = switch (activity) {
      'couch' => 1.0,
      'outdoor' => 1.4,
      _ => 1.2,
    };
    return (rer * factor).round();
  }
}
