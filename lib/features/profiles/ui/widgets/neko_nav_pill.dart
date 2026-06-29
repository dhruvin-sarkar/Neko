import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/neko_motion.dart';

/// The pill width (and the cat's travel track), shared by the state and the
/// pill widget.
const double _kPillWidth = 232;

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
  static const double _catSize = 84;
  // Centres of the three tabs within the pill (8px padding + spaceEvenly).
  static const List<double> _tabCenters = <double>[50, 116, 182];

  late final AnimationController _cat = AnimationController(vsync: this);

  // Mirrors MediaQuery.disableAnimations so the lifecycle callback can respect
  // the OS reduce-motion setting too.
  bool _reduceMotion = false;

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
      if (!_reduceMotion && _cat.duration != null && !_cat.isAnimating) {
        _cat.repeat();
      }
    } else {
      _cat.stop();
    }
  }

  double get _catLeft => _tabCenters[widget.selectedIndex] - _catSize / 2;

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Honor the OS reduce-motion setting: keep the perched cat still.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_reduceMotion) {
        _cat.stop();
      } else if (_cat.duration != null && !_cat.isAnimating) {
        _cat.repeat();
      }
    });
    return SizedBox(
      width: _kPillWidth,
      // Room above the pill for the perched cat (now larger and more visible).
      height: 64 + 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _NavPill(
            selectedIndex: widget.selectedIndex,
            onSelect: widget.onSelect,
            homeKey: widget.homeKey,
            chatKey: widget.chatKey,
            settingsKey: widget.settingsKey,
          ),
          AnimatedPositioned(
            duration: NekoMotion.standard,
            curve: Curves.easeOutBack,
            left: _catLeft,
            bottom: 44,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: Lottie.asset(
                  'assets/animations/loader_cat.json',
                  controller: _cat,
                  width: _catSize,
                  height: _catSize,
                  onLoaded: (composition) {
                    _cat.duration = composition.duration;
                    if (!_reduceMotion) _cat.repeat();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The rounded pill itself with its three destinations.
class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.selectedIndex,
    required this.onSelect,
    this.homeKey,
    this.chatKey,
    this.settingsKey,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Key? homeKey;
  final Key? chatKey;
  final Key? settingsKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kPillWidth,
      height: 64,
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
