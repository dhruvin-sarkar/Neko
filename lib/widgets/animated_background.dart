import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final Color primaryColor;
  final Color secondaryColor;

  const AnimatedBackground({
    super.key,
    this.child,
    this.primaryColor = const Color(0xFFF28C4B),
    this.secondaryColor = const Color(0xFFFF9ECD),
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Create controllers
    _controller1 = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _controller2 = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );

    _controller3 = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    // Schedule animations to start on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller1.repeat();
        _controller2.repeat();
        _controller3.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFF8F0),
                widget.primaryColor.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
        // Animated shapes layer
        AnimatedBuilder(
          animation: Listenable.merge([_controller1, _controller2, _controller3]),
          builder: (context, child) {
            return CustomPaint(
              painter: AnimatedBackgroundPainter(
                animation1: _controller1.value,
                animation2: _controller2.value,
                animation3: _controller3.value,
                primaryColor: widget.primaryColor,
                secondaryColor: widget.secondaryColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Content on top
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final double animation1;
  final double animation2;
  final double animation3;
  final Color primaryColor;
  final Color secondaryColor;

  AnimatedBackgroundPainter({
    required this.animation1,
    required this.animation2,
    required this.animation3,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = primaryColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = secondaryColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final paint3 = Paint()
      ..color = primaryColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Floating circles (paw pad inspired)
    final circle1X = size.width * 0.2 + (animation1 * size.width * 0.3);
    final circle1Y = size.height * 0.15 + math.sin(animation1 * 2 * math.pi) * 40;
    canvas.drawCircle(Offset(circle1X, circle1Y), 35, paint1);

    final circle2X = size.width * 0.75 - (animation2 * size.width * 0.2);
    final circle2Y = size.height * 0.3 + math.cos(animation2 * 2 * math.pi) * 50;
    canvas.drawCircle(Offset(circle2X, circle2Y), 28, paint2);

    final circle3X = size.width * 0.5 + math.sin(animation3 * 2 * math.pi) * 80;
    final circle3Y = size.height * 0.6 + (animation3 * size.height * 0.2);
    canvas.drawCircle(Offset(circle3X, circle3Y), 32, paint1);

    final circle4X = size.width * 0.15 - (animation1 * size.width * 0.1);
    final circle4Y = size.height * 0.8 + math.sin(animation1 * 2 * math.pi) * 30;
    canvas.drawCircle(Offset(circle4X, circle4Y), 24, paint3);

    final circle5X = size.width * 0.85 + math.cos(animation2 * 2 * math.pi) * 50;
    final circle5Y = size.height * 0.7 - (animation2 * size.height * 0.15);
    canvas.drawCircle(Offset(circle5X, circle5Y), 30, paint2);

    // Flowing wavy lines
    _drawWavyLine(canvas, size, animation1, paint1);
    _drawWavyLine(canvas, size, animation2 + 0.33, paint2);
    _drawWavyLine(canvas, size, animation3 + 0.66, paint3);

    // Small accent dots (cat whiskers inspired)
    _drawAccentDots(canvas, size, animation1, paint1);
  }

  void _drawWavyLine(Canvas canvas, Size size, double animation, Paint paint) {
    final path = Path();
    final points = <Offset>[];

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      final y = size.height * 0.5 +
          math.sin((x / size.width + animation) * 2 * math.pi) * 30 +
          math.cos((animation) * 2 * math.pi) * 20;
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint..strokeWidth = 2);
  }

  void _drawAccentDots(Canvas canvas, Size size, double animation, Paint paint) {
    for (int i = 0; i < 6; i++) {
      final angle = (animation * 2 * math.pi) + (i * (2 * math.pi / 6));
      final distance = 100 + math.sin(angle) * 50;
      final x = size.width * 0.5 + math.cos(angle) * distance;
      final y = size.height * 0.5 + math.sin(angle) * distance;
      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.animation1 != animation1 ||
        oldDelegate.animation2 != animation2 ||
        oldDelegate.animation3 != animation3;
  }
}
