import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/neko_motion.dart';

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
    this.selected,
  });

  final Widget child;
  final VoidCallback onTap;
  final double pressedScale;
  final String? semanticLabel;

  /// Optional selected state, surfaced to accessibility (e.g. a chosen card).
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  // Just the pressed state for the animation, so I keep it in local state.
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      selected: widget.selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
              duration: NekoMotion.pressIn,
              curve: NekoMotion.standardCurve,
            ),
      ),
    );
  }
}
