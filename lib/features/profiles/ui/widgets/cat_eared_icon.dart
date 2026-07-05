import 'package:flutter/material.dart';

import '../../../../core/neko_motion.dart';

/// An [Icon] that pops a little paw print above it when [isSelected] is true —
/// the app's paw motif as the bottom-nav "you are here" flourish. The paw
/// springs in (and folds away) with the app's selection-pop motion and is
/// purely decorative (excluded from semantics).
///
/// One reusable wrapper for every nav destination — the paw simply toggles with
/// selection, so there is exactly one way to render a nav icon, topped or not.
class CatEaredIcon extends StatelessWidget {
  const CatEaredIcon({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.earColor,
    this.size = 26,
  });

  final IconData icon;
  final bool isSelected;

  /// Colour of the glyph itself.
  final Color color;

  /// Fill of the paw. In the nav pill it pokes above the selection circle, so
  /// the brand coral reads against the white pill behind it.
  final Color earColor;

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(icon, size: size, color: color),
        Positioned(
          // Sit above the glyph so that, centred in the 48px selection circle,
          // the paw peeks clearly above the circle onto the white pill. Clip.none
          // + the pill's headroom keep the spring overshoot from clipping.
          top: -size * 0.62,
          child: ExcludeSemantics(
            child: AnimatedScale(
              // Pop up from the head on selection; fold away otherwise.
              scale: isSelected ? 1.0 : 0.0,
              alignment: Alignment.bottomCenter,
              duration: reduceMotion ? Duration.zero : NekoMotion.fast,
              curve: reduceMotion ? Curves.linear : NekoMotion.pop,
              child: Icon(Icons.pets_rounded, size: size * 0.62, color: earColor),
            ),
          ),
        ),
      ],
    );
  }
}
