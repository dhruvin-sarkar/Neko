import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// The app's blocking loader — a looping cat animation used in place of a
/// spinner for full-screen / centred waits (auth checks, fetches, AI replies).
///
/// Wrapped in a [RepaintBoundary] so its repaints never bleed into the rest of
/// the tree.
class NekoLoader extends StatelessWidget {
  const NekoLoader({super.key, this.size = 120});

  /// A smaller inline loader, e.g. inside a button or list footer.
  const NekoLoader.small({super.key}) : size = 32;

  final double size;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Lottie.asset(
        'assets/animations/loading_cat.json',
        width: size,
        height: size,
        frameRate: FrameRate.max,
        fit: BoxFit.contain,
      ),
    );
  }
}
