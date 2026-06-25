import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wraps [child] so it compresses on press and springs back on release, using
/// `flutter_animate`'s target-driven scale.
///
/// Shared by tappable surfaces (cat banners, the add-cat button) so they all
/// get the same satisfying press feedback.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  // Local, ephemeral press state — justified setState (see DECISIONS.md).
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) {
          _setPressed(false);
          widget.onTap();
        },
        onTapCancel: () => _setPressed(false),
        child: widget.child
            .animate(target: _pressed ? 1 : 0)
            .scaleXY(
              end: widget.pressedScale,
              duration: 80.ms,
              curve: Curves.easeOut,
            ),
      ),
    );
  }
}
