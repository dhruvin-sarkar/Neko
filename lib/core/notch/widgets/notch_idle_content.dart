import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The idle notch: a 36×36 near-black circle with two faint cat-ear triangles
/// in the top, breathing gently. It reads as a ring around the punch-hole — the
/// cat is always watching. Purely decorative; no interaction in idle.
class NotchIdleContent extends StatelessWidget {
  const NotchIdleContent({super.key});

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    const Widget ears = SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _CatEarPainter()),
    );
    if (reduceMotion) return ears;
    // Gentle opacity breathe so the ears feel alive without pulling focus.
    return ears
        .animate(onPlay: (AnimationController c) => c.repeat(reverse: true))
        .fade(
          begin: 0.55,
          end: 0.9,
          duration: 2200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _CatEarPainter extends CustomPainter {
  const _CatEarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF2A2A2A) // barely visible against the black pill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path leftEar = Path()
      ..moveTo(size.width * 0.20, size.height * 0.24)
      ..lineTo(size.width * 0.10, size.height * 0.04)
      ..lineTo(size.width * 0.38, size.height * 0.14)
      ..close();

    final Path rightEar = Path()
      ..moveTo(size.width * 0.80, size.height * 0.24)
      ..lineTo(size.width * 0.90, size.height * 0.04)
      ..lineTo(size.width * 0.62, size.height * 0.14)
      ..close();

    canvas
      ..drawPath(leftEar, paint)
      ..drawPath(rightEar, paint);
  }

  @override
  bool shouldRepaint(covariant _CatEarPainter oldDelegate) => false;
}
