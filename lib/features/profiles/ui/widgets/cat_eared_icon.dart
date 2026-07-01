import 'package:flutter/material.dart';

import '../../../../core/neko_motion.dart';

/// An [Icon] that sprouts two small triangular cat ears above it when
/// [isSelected] is true. The ears spring in (and fold away) with the app's
/// selection-pop motion and are purely decorative (excluded from semantics).
///
/// One reusable wrapper for every nav destination — the ears simply toggle with
/// selection, so there is exactly one way to render a nav icon, eared or not,
/// rather than a hand-drawn ear variant per icon.
class CatEaredIcon extends StatelessWidget {
  const CatEaredIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.earColor,
    this.size = 26,
  });

  final IconData icon;
  final bool isSelected;

  /// Colour of the glyph itself.
  final Color color;

  /// Fill of the ears. In the nav pill the ears poke above the selection circle,
  /// so the brand coral reads against the white pill behind them.
  final Color earColor;

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Ears scale with the glyph, so nothing is pinned to a single density.
    final Size earBox = Size(size * 0.9, size * 0.52);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(icon, size: size, color: color),
        Positioned(
          // Sit above the glyph so that, centred in the 48px selection circle,
          // the ears poke clearly above the circle onto the white pill (their
          // bases merge into the coral circle). Clip.none + the pill's headroom
          // keep the spring overshoot from clipping.
          top: -earBox.height * 0.9,
          child: ExcludeSemantics(
            child: AnimatedScale(
              // Perk up from the head on selection; fold away otherwise.
              scale: isSelected ? 1.0 : 0.0,
              alignment: Alignment.bottomCenter,
              duration: reduceMotion ? Duration.zero : NekoMotion.fast,
              curve: reduceMotion ? Curves.linear : NekoMotion.pop,
              child: SizedBox.fromSize(
                size: earBox,
                child: CustomPaint(painter: _CatEarsPainter(color: earColor)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints two upright triangular ears filling the given box.
class _CatEarsPainter extends CustomPainter {
  const _CatEarsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final double w = size.width;
    final double h = size.height;
    // Left ear.
    final Path left = Path()
      ..moveTo(w * 0.02, h)
      ..lineTo(w * 0.24, 0)
      ..lineTo(w * 0.46, h)
      ..close();
    // Right ear (mirror).
    final Path right = Path()
      ..moveTo(w * 0.54, h)
      ..lineTo(w * 0.76, 0)
      ..lineTo(w * 0.98, h)
      ..close();
    canvas
      ..drawPath(left, paint)
      ..drawPath(right, paint);
  }

  @override
  bool shouldRepaint(_CatEarsPainter oldDelegate) => oldDelegate.color != color;
}
