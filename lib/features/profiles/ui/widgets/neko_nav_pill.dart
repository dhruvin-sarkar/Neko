import 'package:flutter/material.dart';

/// The custom black pill navigation at the bottom of the home screen.
///
/// Two icons (home, settings); the selected one is full white, the other is
/// dimmed, and the change cross-fades over 150ms.
class NekoNavPill extends StatelessWidget {
  const NekoNavPill({
    super.key,
    required this.selectedIndex,
    required this.onSelectHome,
    required this.onSelectSettings,
  });

  final int selectedIndex;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
            icon: Icons.home_rounded,
            selected: selectedIndex == 0,
            tooltip: 'Home',
            onTap: onSelectHome,
          ),
          _NavIcon(
            icon: Icons.settings_rounded,
            selected: selectedIndex == 1,
            tooltip: 'Settings',
            onTap: onSelectSettings,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: AnimatedOpacity(
        opacity: selected ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
