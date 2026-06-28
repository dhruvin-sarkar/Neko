import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so every screen speaks the same tactile
/// language. Stateless; call the static methods directly.
class HapticService {
  const HapticService._();

  static void selection() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();

  /// A two-stage celebratory buzz for success moments.
  static Future<void> celebrate() async {
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    HapticFeedback.mediumImpact();
  }
}
