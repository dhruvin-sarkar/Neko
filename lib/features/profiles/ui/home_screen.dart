import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/motion/staggered_entrance.dart';
import '../../onboarding/models/cat_profile.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/profile_provider.dart';
import 'widgets/add_cat_section.dart';
import 'widgets/cat_banner_shimmer.dart';
import 'widgets/cat_profile_banner.dart';
import 'widgets/home_error_card.dart';
import 'widgets/home_greeting.dart';
import 'widgets/neko_nav_pill.dart';

/// The signature amber home screen: greeting, the user's cats as pill banners,
/// an add-cat affordance, and the custom bottom nav pill.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(catProfilesProvider);
    final String? displayName = ref
        .watch(authStateChangesProvider)
        .valueOrNull
        ?.displayName;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    void openCat(String catId) => context.push(Routes.profile(catId));
    void addCat() {
      ref.read(onboardingNotifierProvider.notifier).reset();
      context.push(Routes.onboarding);
    }

    return Scaffold(
      backgroundColor: AppColors.homeBg,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 96),
              children: [
                HomeGreeting(displayName: displayName),
                const SizedBox(height: 28),
                cats.when(
                  loading: () => const CatBannerShimmer(),
                  error: (_, _) => HomeErrorCard(
                    onRetry: () => ref.invalidate(catProfilesProvider),
                  ),
                  data: (list) => _CatList(
                    cats: list,
                    onOpenCat: openCat,
                    onAddCat: addCat,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset + 16),
              child: NekoNavPill(
                selectedIndex: 0,
                onSelectHome: () {},
                onSelectSettings: () => context.go(Routes.settings),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The list of cat banners plus the add-cat section. Banners cascade in via
/// [StaggeredEntrance]; stable keys keep them from replaying on Firestore
/// updates.
class _CatList extends StatelessWidget {
  const _CatList({
    required this.cats,
    required this.onOpenCat,
    required this.onAddCat,
  });

  final List<CatProfile> cats;
  final void Function(String catId) onOpenCat;
  final VoidCallback onAddCat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < cats.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          StaggeredEntrance(
            key: ValueKey<String>(cats[i].id),
            delay: Duration(milliseconds: 80 * i),
            offsetY: 30,
            child: CatProfileBanner(
              cat: cats[i],
              onTap: () => onOpenCat(cats[i].id),
            ),
          ),
        ],
        const SizedBox(height: 32),
        AddCatSection(onTap: onAddCat),
      ],
    );
  }
}
