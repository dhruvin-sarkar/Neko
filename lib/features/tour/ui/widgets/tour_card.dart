import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

const double _kCardMaxWidth = 320;
const double _kSideMargin = 16;
const double _kCaretWidth = 24;
const double _kCaretHeight = 11;

/// A single premium coaching card shown next to a spotlighted target.
///
/// A white rounded surface with a soft shadow, a Fredoka title and Nunito
/// body, step dots, and Back / Skip / Next controls. A small pointer (caret)
/// connects the card to its target, and the card slides horizontally to keep
/// that pointer aimed at the target's centre. The whole thing eases in (fade +
/// lift + gentle scale) every time it appears so steps glide into place.
class TourCard extends StatelessWidget {
  const TourCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.stepIndex,
    required this.stepCount,
    required this.pointerUp,
    required this.onNext,
    required this.onSkip,
    this.onBack,
    this.targetCenterX,
    this.availableWidth,
  });

  final IconData icon;
  final String title;
  final String body;
  final int stepIndex;
  final int stepCount;

  /// Whether the pointer sits on top of the card (target is above the card).
  final bool pointerUp;

  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onBack;

  /// Global x of the target's centre, used to aim the pointer.
  final double? targetCenterX;

  /// Width available to lay the card out within (usually the screen width).
  final double? availableWidth;

  bool get _isLast => stepIndex == stepCount - 1;

  @override
  Widget build(BuildContext context) {
    final double available =
        availableWidth ?? MediaQuery.of(context).size.width;
    final double cardWidth = math.min(
      _kCardMaxWidth,
      available - _kSideMargin * 2,
    );

    // Slide the card so its pointer can sit over the target centre, while
    // keeping the whole card comfortably on screen.
    final double anchorX = targetCenterX ?? available / 2;
    final double cardLeft = (anchorX - cardWidth / 2).clamp(
      _kSideMargin,
      available - cardWidth - _kSideMargin,
    );
    final double caretCenter = (anchorX - cardLeft).clamp(
      24.0,
      cardWidth - 24.0,
    );

    final Widget caret = Padding(
      padding: EdgeInsets.only(left: caretCenter - _kCaretWidth / 2),
      child: CustomPaint(
        size: const Size(_kCaretWidth, _kCaretHeight),
        painter: _CaretPainter(up: pointerUp),
      ),
    );

    final Widget card = _buildCard();

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pointerUp ? [caret, card] : [card, caret],
    );

    return SizedBox(
          width: available,
          child: Padding(
            padding: EdgeInsets.only(
              left: cardLeft,
              top: pointerUp ? 6 : 0,
              bottom: pointerUp ? 0 : 6,
            ),
            child: SizedBox(width: cardWidth, child: column),
          ),
        )
        .animate()
        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
        .slideY(
          begin: pointerUp ? 0.08 : -0.08,
          end: 0,
          duration: 360.ms,
          curve: Curves.easeOutCubic,
        )
        .scaleXY(
          begin: 0.97,
          end: 1,
          duration: 380.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.snowWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.headlineLarge)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.charcoal,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Scale the dots down rather than let them overflow when a step
              // count is large enough to outgrow the space the controls leave.
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _StepDots(index: stepIndex, count: stepCount),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBack != null) ...[
                    _BackButton(onTap: onBack!),
                    const SizedBox(width: 6),
                  ],
                  // The final step needs no "Skip" — "Got it" closes the tour.
                  if (!_isLast) ...[
                    _SkipButton(onTap: onSkip),
                    const SizedBox(width: 6),
                  ],
                  _NextButton(
                    label: _isLast ? 'Got it' : 'Next',
                    onTap: onNext,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The coral pill "Next" / "Got it" button.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.buttonLabel.copyWith(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

/// A subtle circular "back" control.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: AppColors.charcoal,
          ),
        ),
      ),
    );
  }
}

/// The understated "Skip" text control.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.silver,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Skip',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.silver),
      ),
    );
  }
}

/// The animated step progress dots.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(count, (i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 6),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.cloudGray,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Paints the little triangle that connects the card to its target.
class _CaretPainter extends CustomPainter {
  const _CaretPainter({required this.up});

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.snowWhite
      ..style = PaintingStyle.fill;

    final Path path = Path();
    if (up) {
      // Points upward toward a target above the card.
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Points downward toward a target below the card.
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CaretPainter oldDelegate) => oldDelegate.up != up;
}
