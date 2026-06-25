import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';

class NekoPillButton extends StatefulWidget {
  const NekoPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  State<NekoPillButton> createState() => _NekoPillButtonState();
}

class _NekoPillButtonState extends State<NekoPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        widget.enabled && widget.onPressed != null && !widget.isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: isEnabled
                  ? (_pressed ? NekoColors.primaryPressed : NekoColors.primary)
                  : NekoColors.primary.withValues(alpha: 0.4),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: NekoColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.label,
                      style: NekoTypography.label(
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class NekoTextButton extends StatelessWidget {
  const NekoTextButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              style: NekoTypography.body(
                size: 14,
                color: NekoColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Sign in with Google',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: widget.compact ? 44 : 52,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              border: Border.all(color: const Color(0xFF747775), width: 1),
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
                  'Sign in with Google',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
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

    // Green (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX + radius * 0.7, centerY + radius * 0.7)
        ..arcTo(rect, 0.785, 1.57, false)
        ..close(),
      paint,
    );

    // Yellow (Left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX - radius * 0.7, centerY + radius * 0.7)
        ..arcTo(rect, 2.355, 1.57, false)
        ..close(),
      paint,
    );

    // Red (Top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(centerX, centerY)
        ..lineTo(centerX - radius * 0.7, centerY - radius * 0.7)
        ..arcTo(rect, 3.925, 1.57, false)
        ..close(),
      paint,
    );

    // Blue (Right & Middle Bar)
    paint.color = const Color(0xFF4285F4);
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

    // Exact middle bar for the 'G'
    canvas.drawRect(
      Rect.fromLTWH(centerX, centerY - radius * 0.1, radius, radius * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: NekoColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('or', style: NekoTypography.caption(size: 12)),
          ),
          Expanded(
            child: Divider(
              color: NekoColors.textSecondary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
