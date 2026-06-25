import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Google-branded sign-in button.
///
/// Intentionally follows Google's sign-in branding (Roboto, neutral border,
/// the multi-color "G") rather than the app's coral theme, as required by
/// Google's brand guidelines. The logo is painted directly so no asset is
/// needed.
class GoogleSignInButton extends StatefulWidget {
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
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: 'Continue with Google',
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: widget.compact ? 48 : 52,
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
                  width: 18,
                  height: 18,
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
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double centerX = w / 2;
    final double centerY = h / 2;
    final double radius = w / 2;
    final Rect rect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    );
    final Paint paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF34A853); // Green
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX + radius * 0.7, centerY + radius * 0.7)
        ..arcTo(rect, 0.785, 1.57, false)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFFBBC05); // Yellow
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX - radius * 0.7, centerY + radius * 0.7)
        ..arcTo(rect, 2.355, 1.57, false)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFEA4335); // Red
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX - radius * 0.7, centerY - radius * 0.7)
        ..arcTo(rect, 3.925, 1.57, false)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFF4285F4); // Blue
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX + radius * 0.7, centerY - radius * 0.7)
        ..arcTo(rect, 5.495, 0.785, false)
        ..lineTo(centerX + radius, centerY + radius * 0.1)
        ..lineTo(centerX, centerY + radius * 0.1)
        ..close(),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX, centerY - radius * 0.1, radius, radius * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
