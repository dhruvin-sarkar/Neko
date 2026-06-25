import 'package:flutter/material.dart';

/// A selectable activity level in the onboarding activity step.
@immutable
class ActivityOption {
  const ActivityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Stored value (e.g. `couch`), matching the Firestore `activityLevel`.
  final String value;

  /// Display label (e.g. `Couch potato`).
  final String label;

  /// Short supporting description.
  final String description;

  /// Leading icon shown in the card.
  final IconData icon;
}
