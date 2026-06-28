import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neko/app/theme/neko_palette.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Every theme must keep its text readable on its own surfaces. These guard
/// against a palette regressing into an unreadable combination.
void main() {
  // (label, foreground, background, minimum ratio)
  List<(String, Color, Color, double)> checks(NekoPalette p) => <(
    String,
    Color,
    Color,
    double,
  )>[
    ('textPrimary on background', p.textPrimary, p.background, 7.0),
    ('textPrimary on surface', p.textPrimary, p.surface, 7.0),
    ('textPrimary on surfaceElevated', p.textPrimary, p.surfaceElevated, 7.0),
    ('textSecondary on surface', p.textSecondary, p.surface, 4.5),
    ('textSecondary on background', p.textSecondary, p.background, 4.0),
    ('textTertiary on surface', p.textTertiary, p.surface, 3.0),
    ('textOnPrimary on primary', p.textOnPrimary, p.primary, 3.0),
    ('navInactive on surface', p.navInactive, p.surface, 3.0),
    ('primary on background', p.primary, p.background, 2.0),
    ('error on surface', p.error, p.surface, 3.0),
  ];

  test('every palette passes its contrast floors', () {
    final List<String> failures = <String>[];
    for (final NekoPalette p in NekoPalettes.all) {
      for (final (String name, Color fg, Color bg, double min) in checks(p)) {
        final double ratio = _contrast(fg, bg);
        if (ratio < min) {
          failures.add(
            '${p.id}: $name = ${ratio.toStringAsFixed(2)} (need $min)',
          );
        }
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'Contrast failures:\n${failures.join('\n')}',
    );
  });
}
