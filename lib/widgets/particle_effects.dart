import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/neko_colors.dart';

class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.life,
  });

  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;
  double life;
}

enum ParticleEffectType { dustMotes, confetti }

class ParticleEffect extends StatefulWidget {
  const ParticleEffect({
    super.key,
    required this.type,
    this.duration = const Duration(milliseconds: 600),
    this.particleCount,
    this.autoStart = true,
  });

  final ParticleEffectType type;
  final Duration duration;
  final int? particleCount;
  final bool autoStart;

  @override
  State<ParticleEffect> createState() => ParticleEffectState();
}

class ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _particles = _createParticles();
    if (widget.autoStart) {
      _controller.forward();
    }
  }

  List<Particle> _createParticles() {
    final count = widget.particleCount ??
        (widget.type == ParticleEffectType.dustMotes ? 6 : 5);
    final colors = widget.type == ParticleEffectType.dustMotes
        ? [
            NekoColors.secondary.withValues(alpha: 0.6),
            NekoColors.primary.withValues(alpha: 0.4),
            NekoColors.accent.withValues(alpha: 0.3),
          ]
        : [
            NekoColors.primary,
            NekoColors.secondary,
            NekoColors.accent,
            NekoColors.success,
          ];

    return List.generate(count, (i) {
      if (widget.type == ParticleEffectType.dustMotes) {
        return Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          vx: (_random.nextDouble() - 0.5) * 0.0008,
          vy: -_random.nextDouble() * 0.001 - 0.0003,
          radius: _random.nextDouble() * 3 + 2,
          color: colors[i % colors.length],
          life: 1.0,
        );
      }
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = _random.nextDouble() * 0.008 + 0.004;
      return Particle(
        x: 0.5 + (_random.nextDouble() - 0.5) * 0.1,
        y: 0.5,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 0.006,
        radius: _random.nextDouble() * 5 + 3,
        color: colors[i % colors.length],
        life: 1.0,
      );
    });
  }

  void burst() {
    setState(() {
      _particles = _createParticles();
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            type: widget.type,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.type,
  });

  final List<Particle> particles;
  final double progress;
  final ParticleEffectType type;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final lifeFactor = type == ParticleEffectType.confetti
          ? (1.0 - progress).clamp(0.0, 1.0)
          : 1.0;

      if (lifeFactor <= 0) continue;

      final x = (p.x + p.vx * progress * 100) * size.width;
      final y = (p.y + p.vy * progress * 100) * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: p.color.a * lifeFactor * 0.9);

      if (type == ParticleEffectType.confetti) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * math.pi * 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.radius * 2, height: p.radius),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _GrainPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 800; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final opacity = _random.nextDouble() * 0.03;
      paint.color = NekoColors.textPrimary.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadialGlow extends StatelessWidget {
  const RadialGlow({super.key, this.size = 200});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            NekoColors.primary.withValues(alpha: 0.25),
            NekoColors.primary.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
