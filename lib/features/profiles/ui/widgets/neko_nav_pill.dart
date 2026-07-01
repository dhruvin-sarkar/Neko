import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/neko_motion.dart';
import 'cat_eared_icon.dart';

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
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : NekoMotion.quick,
          curve: NekoMotion.standardCurve,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: CatEaredIcon(
            icon: selected ? selectedIcon : unselectedIcon,
            isSelected: selected,
            color: selected ? AppColors.textOnPrimary : AppColors.navInactive,
            // Coral ears poke above the circle onto the white pill, so they
            // read (the on-primary colour used before was white-on-white).
            earColor: AppColors.primary,
            size: 26,
          ),
        ),
      ),
    );
  }
}
