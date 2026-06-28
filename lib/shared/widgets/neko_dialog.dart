import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Shows a dialog with a premium reveal: the barrier blurs in while the dialog
/// scales up and fades, and reverses smoothly on dismiss. Use this instead of
/// [showDialog] so every dialog in the app shares the same polished motion.
///
/// The [builder] returns the dialog widget (typically an [AlertDialog]), just
/// like [showDialog].
Future<T?> showNekoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        Builder(builder: builder),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final double v = Curves.easeOutCubic.transform(
        animation.value.clamp(0.0, 1.0),
      );
      return FadeTransition(
        opacity: animation,
        child: Stack(
          children: <Widget>[
            // Soft blur of whatever sits behind the dialog.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6 * v, sigmaY: 6 * v),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            // The dialog itself, scaling up into place.
            Transform.scale(scale: 0.90 + 0.10 * v, child: child),
          ],
        ),
      );
    },
  );
}
