import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// The custom bottom navigation pill: a white rounded pill where the selected
/// destination sits inside a filled coral circle (Duolingo-style), echoing the
/// app's brand accent.
class NekoNavPill extends StatelessWidget {
  const NekoNavPill({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.homeKey,
    this.settingsKey,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Optional keys used by the first-run guided tour to spotlight each item.
  final Key? homeKey;
  final Key? settingsKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
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
            key: settingsKey,
            selectedIcon: Icons.settings_rounded,
            unselectedIcon: Icons.settings_outlined,
            label: 'Settings',
            selected: selectedIndex == 1,
            onTap: () => onSelect(1),
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            selected ? selectedIcon : unselectedIcon,
            color: selected ? Colors.white : AppColors.textSecondary,
            size: 26,
          ),
        ),
      ),
    );
  }
}
