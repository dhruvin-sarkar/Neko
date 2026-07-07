import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/app_spacing.dart';
import 'pressable.dart';

/// Google sign-in button following Google's branding (Roboto, neutral border,
/// the four-color "G"). The logo is painted directly so it needs no asset.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget surface = Container(
      height: compact ? 48 : 52,
      width: double.infinity,
      decoration: BoxDecoration(
        // Match the chiclet CTA + text-field radius it stacks with (not a pill).
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: Colors.white,
        border: Border.all(color: const Color(0xFF747775)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: SvgPicture.asset(
              'assets/images/google-icon.svg',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Continue with Google',
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F1F1F),
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );

    if (!enabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: 'Continue with Google',
        child: Opacity(opacity: 0.6, child: surface),
      );
    }

    return Pressable(
      onTap: onPressed,
      pressedScale: 0.98,
      semanticLabel: 'Continue with Google',
      child: surface,
    );
  }
}
