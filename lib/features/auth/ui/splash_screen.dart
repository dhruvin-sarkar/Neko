import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/motion/springs.dart';

/// First screen shown on launch. The wordmark springs in from 0.7→1.0 scale.
///
/// No navigation happens here — the router holds the app on `/splash` until
/// the auth state resolves, then redirects. The progress indicator simply
/// signals that work is happening.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 0.7,
  );

  @override
  void initState() {
    super.initState();
    _scale.animateWith(SpringSimulation(Springs.nekoBounce, 0.7, 1.0, 0));
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scale,
              builder: (context, child) =>
                  Transform.scale(scale: _scale.value, child: child),
              child: Text(
                'Neko',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 56,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
