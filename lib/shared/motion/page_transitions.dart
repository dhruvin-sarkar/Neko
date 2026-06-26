import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page transition helpers that give every route the same "slide from the
/// right" feel instead of the default Material push.
abstract final class PageTransitions {
  const PageTransitions._();

  static const Duration _duration = Duration(milliseconds: 280);
  static const Duration _reverseDuration = Duration(milliseconds: 240);

  /// Wraps [child] in a [CustomTransitionPage] that slides in from the right
  /// with a quick fade, and slides back out on pop.
  static CustomTransitionPage<void> slideFromRight({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: _duration,
      reverseTransitionDuration: _reverseDuration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final Animation<Offset> position = animation.drive(
          Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );
        return SlideTransition(
          position: position,
          child: FadeTransition(
            opacity: animation.drive(
              Tween<double>(begin: 0, end: 1).chain(
                CurveTween(
                  curve: const Interval(0, 0.5, curve: Curves.easeOut),
                ),
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// A fade-only transition for the splash → first-route handoff, where a
  /// horizontal slide would feel abrupt.
  static CustomTransitionPage<void> fade({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: _duration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
