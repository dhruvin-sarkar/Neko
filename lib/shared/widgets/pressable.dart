import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../motion/springs.dart';

/// Wraps [child] so it compresses on press and springs back on release.
///
/// Shared by tappable surfaces (cat banners, the add-cat button) so they all
/// get the same satisfying [Springs.nekoBounce] feedback.
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

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() => _press.animateTo(
    1,
    duration: const Duration(milliseconds: 80),
    curve: Curves.easeOut,
  );

  void _release() => _press.animateWith(
    SpringSimulation(Springs.nekoBounce, _press.value, 0, 0),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => _down(),
        onTapUp: (_) {
          _release();
          widget.onTap();
        },
        onTapCancel: _release,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            final double scale = (1 - (1 - widget.pressedScale) * _press.value)
                .clamp(0.9, 1.0);
            return Transform.scale(scale: scale, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
