import 'package:flutter/material.dart';

/// The Neko mascot.
///
/// Renders [fallback] (a placeholder mark) sized to [size]. A Rive-animated
/// version will be wired in here once a real `.riv` animation file exists; for
/// now there is no animation asset, so this stays a lightweight placeholder.
class NekoMascot extends StatelessWidget {
  const NekoMascot({super.key, required this.size, required this.fallback});

  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: fallback);
  }
}
