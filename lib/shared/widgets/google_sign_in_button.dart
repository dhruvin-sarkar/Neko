import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pressable.dart';

/// Google sign-in button following Google's branding (Roboto, neutral border,
/// the four-color "G"). The logo is painted directly so it needs no asset.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget surface = Container(
      height: compact ? 48 : 52,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: const Color(0xFF747775)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: _GoogleLogoPainter()),
          ),
          const SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F1F1F),
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: 'Continue with Google',
        child: Opacity(opacity: 0.6, child: surface),
      );
    }

    return Pressable(
      onTap: onPressed,
      pressedScale: 0.98,
      semanticLabel: 'Continue with Google',
      child: surface,
    );
  }
}

/// Paints the official four-color Google "G".
///
/// The mark is a thick ring split into four colored arcs (red top, yellow
/// left, green bottom, blue upper-right) plus the blue horizontal crossbar that
/// runs from the centre out to the ring on the right.
class _GoogleLogoPainter extends CustomPainter {
  static const Color _blue = Color(0xFF4285F4);
  static const Color _red = Color(0xFFEA4335);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _green = Color(0xFF34A853);

  double _rad(double degrees) => degrees * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double outer = size.shortestSide / 2;
    // Ring thickness ≈ the bar height of the real mark.
    final double stroke = outer * 0.46;
    final double radius = outer - stroke / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Clockwise from a little above the east bar opening.
    // Blue sweeps across the east (and merges with the crossbar), then green
    // along the bottom, yellow up the left, red across the top.
    arc.color = _blue;
    canvas.drawArc(rect, _rad(-75), _rad(115), false, arc);
    arc.color = _green;
    canvas.drawArc(rect, _rad(40), _rad(95), false, arc);
    arc.color = _yellow;
    canvas.drawArc(rect, _rad(135), _rad(75), false, arc);
    arc.color = _red;
    canvas.drawArc(rect, _rad(210), _rad(75), false, arc);

    // Blue crossbar: from the centre out to the ring on the right, at the
    // vertical middle, the same thickness as the ring.
    final Paint bar = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    final Rect barRect = Rect.fromLTRB(
      center.dx,
      center.dy - stroke / 2,
      center.dx + radius + stroke / 2,
      center.dy + stroke / 2,
    );
    canvas.drawRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
