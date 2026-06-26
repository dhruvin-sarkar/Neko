import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The app-wide background: the warm amber fill with a faint pattern of cat
/// paws that drifts slowly and diagonally, looping forever. It sits behind
/// every screen (the screens themselves are transparent), so the motion is
/// continuous as you move between pages.
///
/// Kept deliberately subtle — low opacity and a slow drift — so it reads as
/// texture, never as something competing with the content.
class PawBackground extends StatefulWidget {
  const PawBackground({super.key, required this.child});

  final Widget child;

  @override
  State<PawBackground> createState() => _PawBackgroundState();
}

class _PawBackgroundState extends State<PawBackground>
    with SingleTickerProviderStateMixin {
  // One slow loop = the pattern drifts exactly one tile, so it wraps seamlessly.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBg,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PawPainter(_controller)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  static const double _tile = 132;
  static const double _pawSize = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08);

    final double t = progress.value;
    final double shiftX = t * _tile;
    final double shiftY = t * _tile;

    final int cols = (size.width / _tile).ceil() + 2;
    final int rows = (size.height / _tile).ceil() + 2;

    for (int r = -1; r <= rows; r++) {
      // Offset every other row so the paws don't line up in a rigid grid.
      final double rowStagger = r.isEven ? 0 : _tile / 2;
      for (int c = -1; c <= cols; c++) {
        final double x = c * _tile + rowStagger + shiftX;
        final double y = r * _tile + shiftY;
        // A small deterministic tilt per paw makes the field feel organic.
        final double angle = (((r * 31 + c * 17) % 5) - 2) * 0.16;
        _drawPaw(canvas, Offset(x, y), angle, paint);
      }
    }
  }

  void _drawPaw(Canvas canvas, Offset center, double angle, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    const double s = _pawSize;
    // Main pad.
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, s * 0.34),
        width: s * 0.95,
        height: s * 0.8,
      ),
      paint,
    );
    // Four toe beans in an arc above the pad.
    const double tw = s * 0.3;
    const double th = s * 0.4;
    const List<Offset> toes = [
      Offset(-s * 0.4, -s * 0.12),
      Offset(-s * 0.14, -s * 0.36),
      Offset(s * 0.14, -s * 0.36),
      Offset(s * 0.4, -s * 0.12),
    ];
    for (final Offset toe in toes) {
      canvas.drawOval(
        Rect.fromCenter(center: toe, width: tw, height: th),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) => false;
}
