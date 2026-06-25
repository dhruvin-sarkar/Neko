import 'package:flutter/material.dart';

import '../theme/neko_colors.dart';
import '../theme/neko_typography.dart';
import '../widgets/particle_effects.dart';

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({
    super.key,
    required this.catName,
    required this.onComplete,
  });

  final String catName;
  final VoidCallback onComplete;

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NekoColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _fadeAnim,
            child: const RadialGlow(size: 280),
          ),
          Positioned.fill(
            child: ParticleEffect(
              type: ParticleEffectType.confetti,
              duration: const Duration(milliseconds: 1800),
              particleCount: 8,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NekoChan removed
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _titleFade,
                child: Text(
                  '${widget.catName} is waiting for you',
                  style: NekoTypography.title(size: 22),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
