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
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Widget wordmark = Text(
      'Neko',
      style: AppTextStyles.displayLarge.copyWith(
        fontSize: 56,
        color: AppColors.darkBanner,
      ),
    );
    const Widget loader = NekoLoader(size: 72);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Under reduce-motion just fade in; otherwise the wordmark springs.
            reduceMotion
                ? wordmark.animate().fadeIn(duration: 300.ms)
                : wordmark
                      .animate()
                      .scaleXY(
                        begin: 0.7,
                        end: 1.0,
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 300.ms),
            const SizedBox(height: 28),
            reduceMotion
                ? loader.animate().fadeIn(duration: 300.ms)
                : loader.animate(delay: 250.ms).fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
