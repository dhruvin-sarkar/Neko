import 'package:flutter/animation.dart';

/// The app's motion language. Every *repeated* duration and curve lives here so
/// the interaction feel stays consistent and tunable from one place.
///
/// Deliberately NOT a home for one-off, carefully-tuned component timings —
/// page-transition curtains, shimmer periods, the typing-dots loop, coach-mark
/// choreography and audio fades stay local to their widget, since they're
/// bespoke rather than part of the shared design language.
abstract final class NekoMotion {
  const NekoMotion._();

  // ─── Durations ──────────────────────────────────────────────────────────
  /// Press compression on a button/card tap-down.
  static const Duration pressIn = Duration(milliseconds: 80);

  /// A small state change (selected-card fill).
  static const Duration micro = Duration(milliseconds: 120);

  /// Selection feedback (coat swatch, checkmark pop).
  static const Duration fast = Duration(milliseconds: 150);

  /// Toggles, nav state, small reveals.
  static const Duration quick = Duration(milliseconds: 200);

  /// The global default for `flutter_animate` (set in `main`).
  static const Duration base = Duration(milliseconds: 250);

  /// Screen content fade-in on entry.
  static const Duration entry = Duration(milliseconds: 280);

  /// In-screen section reveals and short transitions.
  static const Duration standard = Duration(milliseconds: 300);

  // ─── Curves ─────────────────────────────────────────────────────────────
  /// Elements entering the viewport — decelerate to rest.
  static const Curve enter = Curves.easeOutCubic;

  /// A satisfying single overshoot for selection pops.
  static const Curve pop = Curves.elasticOut;

  /// General-purpose ease for small state changes.
  static const Curve standardCurve = Curves.easeOut;

  // ─── Stagger ────────────────────────────────────────────────────────────
  /// Per-item delay for staggered list/section entries.
  static const Duration staggerItem = Duration(milliseconds: 60);
}
