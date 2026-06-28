import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

import '../../app/theme/app_colors.dart';

/// The app-wide background: the warm amber fill with a faint, repeating pattern
/// of our paw image that drifts slowly and diagonally, looping forever. It sits
/// behind every screen (the screens themselves are transparent), so the motion
/// is continuous as you move between pages.
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
  // One loop drifts the field exactly two tiles diagonally. The pattern (row
  // stagger + per-paw tilt) repeats every two tiles, so a two-tile drift wraps
  // perfectly with no jump when the controller repeats.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  // The paw artwork, decoded once and reused for every tile. Null until the
  // asset finishes loading; we just paint the plain amber fill until then.
  ui.Image? _pawImage;

  @override
  void initState() {
    super.initState();
    _loadPaw();
  }

  Future<void> _loadPaw() async {
    final ByteData data = await rootBundle.load('assets/images/paw.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _pawImage = frame.image);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pawImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: AppColors.homeBg,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PawPainter(_controller, _pawImage)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  _PawPainter(this.progress, this.image) : super(repaint: progress);

  final Animation<double> progress;
  final ui.Image? image;

  static const double _tile = 124;
  // The drawn size of each paw. The artwork carries its own detail, so I keep
  // it a touch larger than the old vector paw but still small enough to read as
  // a repeating texture.
  static const double _pawSize = 46;

  @override
  void paint(Canvas canvas, Size size) {
    final ui.Image? img = image;
    if (img == null) return;

    // Modulate keeps the image's own colours but drops it to a low opacity so
    // it stays texture, not noise.
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: 0.16),
        BlendMode.modulate,
      );

    final double t = progress.value;
    // Drift two tiles per loop so the (period-two) pattern wraps seamlessly.
    final double shiftX = t * 2 * _tile;
    final double shiftY = t * 2 * _tile;

    final int cols = (size.width / _tile).ceil() + 2;
    final int rows = (size.height / _tile).ceil() + 2;

    final Rect src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );

    // Start two tiles back so the area the drift vacates stays filled.
    for (int r = -2; r <= rows; r++) {
      // Offset every other row so the paws don't line up in a rigid grid.
      final double rowStagger = r.isEven ? 0 : _tile / 2;
      for (int c = -2; c <= cols; c++) {
        final double x = c * _tile + rowStagger + shiftX;
        final double y = r * _tile + shiftY;
        // A small per-paw tilt makes the field feel organic. Keyed to the
        // cell parity (period two) so it realigns exactly after the two-tile
        // drift — the loop is therefore seamless.
        final int h = (c % 2).abs() + (r % 2).abs() * 2;
        final double angle = (h - 1.5) * 0.18;
        _drawPaw(canvas, Offset(x, y), angle, src, img, paint);
      }
    }
  }

  void _drawPaw(
    Canvas canvas,
    Offset center,
    double angle,
    Rect src,
    ui.Image img,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final Rect dst = Rect.fromCenter(
      center: Offset.zero,
      width: _pawSize,
      height: _pawSize,
    );
    canvas.drawImageRect(img, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PawPainter oldDelegate) =>
      oldDelegate.image != image;
}
