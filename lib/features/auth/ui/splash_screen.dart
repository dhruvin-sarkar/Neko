import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/neko_loader.dart';

/// First screen on launch. The wordmark springs in with an elastic overshoot.
///
/// No navigation happens here — the router holds the app on `/splash` until
/// auth resolves and a short minimum display time elapses, then redirects.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                  'Neko',
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 56,
                    color: AppColors.darkBanner,
                  ),
                )
                .animate()
                .scaleXY(
                  begin: 0.7,
                  end: 1.0,
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 28),
            const NekoLoader(
              size: 72,
            ).animate(delay: 250.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
