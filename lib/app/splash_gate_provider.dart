import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'splash_gate_provider.g.dart';

/// Minimum time the splash screen stays visible so it never flashes — also
/// gives auth and the onboarding-status confirmation room to settle before the
/// router commits to a destination.
const Duration _minSplashDuration = Duration(milliseconds: 1200);

/// Becomes `true` once the minimum splash duration has elapsed. The router
/// keeps the app on `/splash` until this is `true` (and auth has resolved).
@Riverpod(keepAlive: true)
class SplashGate extends _$SplashGate {
  @override
  bool build() {
    final Timer timer = Timer(_minSplashDuration, () => state = true);
    ref.onDispose(timer.cancel);
    return false;
  }
}
