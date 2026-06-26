import 'package:flutter/material.dart';

/// The Neko mascot. We don't have the animated version yet, so I just show
/// [fallback] at the given [size].
class NekoMascot extends StatelessWidget {
  const NekoMascot({super.key, required this.size, required this.fallback});

  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: fallback);
  }
}
