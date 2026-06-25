import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';
import '../widgets/neko_buttons.dart';
import '../widgets/particle_effects.dart';

class HeroScreen extends StatefulWidget {
  const HeroScreen({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  State<HeroScreen> createState() => _HeroScreenState();
}

class _HeroScreenState extends State<HeroScreen> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _taglineController;
  late AnimationController _bgController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _taglineFade;

  bool _showParticles = false;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _fadeAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack));
    _taglineFade = CurvedAnimation(parent: _taglineController, curve: Curves.easeOut);

    _entryController.forward();
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted || !_active) return;
      _taglineController.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || !_active) return;
      setState(() => _showParticles = true);
    });
  }

  @override
  void dispose() {
    _active = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _entryController.dispose();
    _taglineController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    widget.onGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _DynamicBackground(controller: _bgController),
          const GrainOverlay(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_showParticles)
                        const Positioned.fill(
                          child: ParticleEffect(
                            type: ParticleEffectType.dustMotes,
                            duration: Duration(seconds: 10),
                          ),
                        ),
                      Positioned(
                        top: MediaQuery.sizeOf(context).height * 0.25,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                const SizedBox(height: 64),
                                Text(
                                  'Neko',
                                  style: NekoTypography.display(size: 64).copyWith(
                                    letterSpacing: -1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FadeTransition(
                                  opacity: _taglineFade,
                                  child: Text(
                                    "A notch that doubles as a cat tracker app",
                                    textAlign: TextAlign.center,
                                    style: NekoTypography.body(
                                      size: 18,
                                      color: NekoColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      NekoPillButton(
                        label: 'Get Started',
                        onPressed: _onGetStarted,
                      ),
                      const SizedBox(height: 12),
                      NekoTextButton(
                        label: 'I already have an account',
                        onPressed: widget.onSignIn,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicBackground extends StatelessWidget {
  const _DynamicBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _MeshGradientPainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  _MeshGradientPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = NekoColors.background);

    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    void drawBlob(Color color, double xMult, double yMult, double radius, double phase) {
      final x = size.width * (xMult + 0.15 * math.sin(progress * 2 * math.pi + phase));
      final y = size.height * (yMult + 0.1 * math.cos(progress * 2 * math.pi + phase));
      paint.color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    drawBlob(NekoColors.primary.withValues(alpha: 0.15), 0.2, 0.3, 250, 0);
    drawBlob(NekoColors.secondary.withValues(alpha: 0.2), 0.8, 0.2, 300, math.pi / 2);
    drawBlob(NekoColors.accent.withValues(alpha: 0.12), 0.5, 0.7, 350, math.pi);
    drawBlob(NekoColors.success.withValues(alpha: 0.08), 0.3, 0.8, 200, 3 * math.pi / 2);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
