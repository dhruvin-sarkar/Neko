import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/neko_motion.dart';

/// The pill's natural (max) width; it shrinks to fit unusually narrow screens.
const double _kPillMaxWidth = 232;
const double _kPillHeight = 64;

/// Headroom above the pill so the selected tab's cat ears (which poke above the
/// selection circle) are never clipped, spring overshoot included.
const double _kEarHeadroom = 16;

/// The custom bottom navigation pill: a white rounded pill (Duolingo-style)
/// where the selected destination sits inside a filled coral circle that sprouts
/// two coral cat ears above it.
///
/// Stateless — the ears use implicit animation, so no [AnimationController].
class NekoNavPill extends StatelessWidget {
  const NekoNavPill({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.homeKey,
    this.chatKey,
    this.settingsKey,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Optional keys used by the first-run guided tour to spotlight each item.
  final Key? homeKey;
  final Key? chatKey;
  final Key? settingsKey;

  @override
  Widget build(BuildContext context) {
    // Shrink to fit narrow devices; stay a centred island on wide ones.
    final double width = math.min(
      _kPillMaxWidth,
      MediaQuery.sizeOf(context).width - 48,
    );
    return SizedBox(
      width: width,
      height: _kPillHeight + _kEarHeadroom,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: _NavPill(
          width: width,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          homeKey: homeKey,
          chatKey: chatKey,
          settingsKey: settingsKey,
        ),
      ),
    );
  }
}

/// The rounded pill itself with its three destinations.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.width,
    required this.selectedIndex,
    required this.onSelect,
    this.homeKey,
    this.chatKey,
    this.settingsKey,
  });

  final double width;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Key? homeKey;
  final Key? chatKey;
  final Key? settingsKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: _kPillHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.snowWhite,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            key: homeKey,
            selectedIcon: Icons.home_rounded,
            unselectedIcon: Icons.home_outlined,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _NavItem(
            key: chatKey,
            selectedIcon: Icons.auto_awesome_rounded,
            unselectedIcon: Icons.auto_awesome_outlined,
            label: 'Neko Assistant',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _NavItem(
            key: settingsKey,
            selectedIcon: Icons.settings_rounded,
            unselectedIcon: Icons.settings_outlined,
            label: 'Settings',
            selected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The selection marker is a cat-head silhouette — a circle with
              // two ears breaking its top rim (the shape _kEarHeadroom was
              // always reserved for). A highlight sized just a little larger
              // than the destination glyphs (not filling the whole tap
              // target), springing up when the tab is chosen so it reads as a
              // cohesive part of the pill. Unlike the old bottom-heavy paw
              // glyph, the head is symmetric, so no optical-centring nudges.
              AnimatedScale(
                scale: selected ? 1.0 : 0.0,
                duration: reduceMotion ? Duration.zero : NekoMotion.quick,
                curve: reduceMotion ? Curves.linear : NekoMotion.pop,
                child: CustomPaint(
                  size: const Size(40, 40),
                  painter: _CatHeadPainter(color: AppColors.primary),
                ),
              ),
              // The destination glyph: white and centred on the head circle
              // when selected (the head sits a touch low in its box to leave
              // ear room, hence the small positive y), a muted outline icon
              // otherwise.
              Align(
                alignment: selected
                    ? const Alignment(0, 0.11)
                    : Alignment.center,
                child: Icon(
                  selected ? selectedIcon : unselectedIcon,
                  size: selected ? 15 : 24,
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.navInactive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the nav pill's selection marker: a cat-head silhouette — a filled
/// circle with two softly-rounded ears breaking its top rim. Drawn as one
/// flat fill (ears first, head over their bases) so it reads as a single
/// chunky shape at nav-icon size, matching the chiclet system's rounded look.
class _CatHeadPainter extends CustomPainter {
  const _CatHeadPainter({required this.color});

  final Color color;

  // Geometry, as fractions of the head radius / box. The head sits slightly
  // below centre so the ears stay inside the box (with the pop overshoot
  // covered by the pill's _kEarHeadroom).
  static const double _headRadiusFactor = 0.325; // of box width
  static const double _headCenterYFactor = 0.55; // of box height
  static const double _earAngleDeg = 235; // left ear direction (y-down coords)
  static const double _earHalfSpanDeg = 27; // half the base arc per ear
  static const double _earTipFactor = 1.75; // tip distance, in head radii
  static const double _earTipRounding = 0.16; // tip softness, in head radii

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final double r = size.width * _headRadiusFactor;
    final Offset head = Offset(
      size.width / 2,
      size.height * _headCenterYFactor,
    );

    // Two ears mirrored about the vertical axis (mirror of θ is 180° − θ):
    // 235° points up-left, 305° up-right (Flutter's y axis points down).
    _drawEar(canvas, paint, head, r, _earAngleDeg * math.pi / 180);
    _drawEar(canvas, paint, head, r, (540 - _earAngleDeg) * math.pi / 180);

    canvas.drawCircle(head, r, paint);
  }

  /// One ear: a triangle whose base chord sits on the head circle and whose
  /// tip is softened with a small quadratic curve.
  void _drawEar(
    Canvas canvas,
    Paint paint,
    Offset head,
    double r,
    double angle,
  ) {
    const double halfSpan = _earHalfSpanDeg * math.pi / 180;
    final Offset baseA = head + Offset.fromDirection(angle - halfSpan, r);
    final Offset baseB = head + Offset.fromDirection(angle + halfSpan, r);
    final Offset tip = head + Offset.fromDirection(angle, r * _earTipFactor);

    // Points just short of the tip along each edge; the quadratic between them
    // (through the true tip) rounds the point so it matches the app's soft,
    // rounded icon language instead of a needle.
    final double soften = _earTipRounding * r;
    final Offset nearA = tip + (baseA - tip) / (baseA - tip).distance * soften;
    final Offset nearB = tip + (baseB - tip) / (baseB - tip).distance * soften;

    final Path ear = Path()
      ..moveTo(baseA.dx, baseA.dy)
      ..lineTo(nearA.dx, nearA.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, nearB.dx, nearB.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..close();
    canvas.drawPath(ear, paint);
  }

  @override
  bool shouldRepaint(covariant _CatHeadPainter oldDelegate) =>
      oldDelegate.color != color;
}
