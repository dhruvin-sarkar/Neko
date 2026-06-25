import 'package:flutter/material.dart';

/// A selectable coat color in the onboarding coat step.
@immutable
class CoatOption {
  const CoatOption({
    required this.value,
    required this.label,
    required this.circleColor,
    this.needsBorder = false,
  });

  /// Stored value (e.g. `ginger`), matching the Firestore `colorType`.
  final String value;

  /// Display label (e.g. `Ginger`).
  final String label;

  /// Color of the preview circle.
  final Color circleColor;

  /// Whether the circle needs an outline to stay visible (e.g. white on white).
  final bool needsBorder;
}
