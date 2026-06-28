import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/neko_motion.dart';

/// The custom bottom navigation pill: a white rounded pill where the selected
/// destination sits inside a filled coral circle (Duolingo-style). A little cat
/// perches on top of the pill, above the active tab, and slides across when you
/// switch tabs.
class NekoNavPill extends StatefulWidget {
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
  State<NekoNavPill> createState() => _NekoNavPillState();
}

class _NekoNavPillState extends State<NekoNavPill>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const double _pillWidth = 232;
  static const double _catSize = 74;
  // Centres of the three tabs within the pill (8px padding + spaceEvenly).
  static const List<double> _tabCenters = <double>[50, 116, 182];

  late final AnimationController _cat = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cat.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause the cat while the app isn't in the foreground to save battery.
    if (state == AppLifecycleState.resumed) {
      if (_cat.duration != null && !_cat.isAnimating) _cat.repeat();
    } else {
      _cat.stop();
    }
  }

  double get _catLeft => _tabCenters[widget.selectedIndex] - _catSize / 2;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _pillWidth,
      // Room above the pill for the perched cat (now larger and more visible).
      height: 64 + 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _buildPill(),
          AnimatedPositioned(
            duration: NekoMotion.standard,
            curve: Curves.easeOutBack,
            left: _catLeft,
            bottom: 46,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Lottie.asset(
                  'assets/animations/loader_cat.json',
                  controller: _cat,
                  width: _catSize,
                  height: _catSize,
                  onLoaded: (composition) {
                    _cat.duration = composition.duration;
                    _cat.repeat();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill() {
    return Container(
      width: _pillWidth,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
            key: widget.homeKey,
            selectedIcon: Icons.home_rounded,
            unselectedIcon: Icons.home_outlined,
            label: 'Home',
            selected: widget.selectedIndex == 0,
            onTap: () => widget.onSelect(0),
          ),
          _NavItem(
            key: widget.chatKey,
            selectedIcon: Icons.auto_awesome_rounded,
            unselectedIcon: Icons.auto_awesome_outlined,
            label: 'Neko Assistant',
            selected: widget.selectedIndex == 1,
            onTap: () => widget.onSelect(1),
          ),
          _NavItem(
            key: widget.settingsKey,
            selectedIcon: Icons.settings_rounded,
            unselectedIcon: Icons.settings_outlined,
            label: 'Settings',
            selected: widget.selectedIndex == 2,
            onTap: () => widget.onSelect(2),
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
          duration: NekoMotion.quick,
          curve: NekoMotion.standardCurve,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            selected ? selectedIcon : unselectedIcon,
            color: selected ? AppColors.textOnPrimary : AppColors.navInactive,
            size: 26,
          ),
        ),
      ),
    );
  }
}
