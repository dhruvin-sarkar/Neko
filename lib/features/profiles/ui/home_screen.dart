import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/services/feedback_service.dart';
import '../../onboarding/models/cat_profile.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../tour/providers/tour_keys.dart';
import '../../tour/ui/home_tour.dart';
import '../providers/profile_provider.dart';
import 'widgets/add_cat_section.dart';
import 'widgets/cat_banner_shimmer.dart';
import 'widgets/cat_profile_banner.dart';
import 'widgets/home_error_card.dart';
import 'widgets/home_greeting.dart';

/// The Home tab: the user's cats as pill banners plus the add-cat affordance.
/// The amber background and bottom nav pill are provided by [MainShell].
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(catProfilesProvider);
    final String? displayName = ref.watch(
      authStateChangesProvider.select((v) => v.valueOrNull?.displayName),
    );
    final FeedbackService feedback = ref.read(feedbackServiceProvider);
    final TourKeys tourKeys = ref.read(tourKeysProvider);

    // Kick off the first-run guided tour once Home is on screen. The call
    // self-guards (persistence + in-memory flag) and waits for its targets to
    // lay out, so firing it on every build is safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) HomeTour.maybeShow(context, ref);
    });

    void openCat(String catId) {
      unawaited(feedback.onTap());
      context.push(Routes.profile(catId));
    }

    void addCat() {
      unawaited(feedback.onTap());
      ref.read(onboardingNotifierProvider.notifier).reset();
      context.push(Routes.onboarding);
    }

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: ref.read(homeScrollControllerProvider),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            sliver: SliverToBoxAdapter(
              child: HomeGreeting(
                key: tourKeys.greeting,
                displayName: displayName,
              ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.15, end: 0),
            ),
          ),
          ...cats.when(
            loading: () => const [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(child: CatBannerShimmer()),
              ),
            ],
            error: (_, _) => [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: HomeErrorCard(
                    onRetry: () => ref.invalidate(catProfilesProvider),
                  ),
                ),
              ),
            ],
            data: (list) => _catSlivers(list, openCat, addCat, tourKeys),
          ),
        ],
      ),
    );
  }
}

/// Builds the cat-list slivers for the data state.
List<Widget> _catSlivers(
  List<CatProfile> cats,
  void Function(String) onOpenCat,
  VoidCallback onAddCat,
  TourKeys tourKeys,
) {
  if (cats.isEmpty) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        sliver: SliverToBoxAdapter(
          child: _EmptyCats(onAddCat: onAddCat, plusKey: tourKeys.addCatPlus),
        ),
      ),
    ];
  }
  return [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList.builder(
        itemCount: cats.length,
        itemBuilder: (context, index) {
          final CatProfile cat = cats[index];
          final Widget banner =
              RepaintBoundary(
                    child: CatProfileBanner(
                      cat: cat,
                      onTap: () => onOpenCat(cat.id),
                    ),
                  )
                  .animate(delay: (80 * index).ms)
                  .fadeIn(duration: 250.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                  );
          return Padding(
            key: ValueKey<String>(cat.id),
            padding: const EdgeInsets.only(bottom: 16),
            // The first banner anchors the "your crew" tour step.
            child: index == 0
                ? KeyedSubtree(key: tourKeys.firstCat, child: banner)
                : banner,
          );
        },
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      sliver: SliverToBoxAdapter(
        child: AddCatSection(plusKey: tourKeys.addCatPlus, onTap: onAddCat),
      ),
    ),
  ];
}

class _EmptyCats extends StatelessWidget {
  const _EmptyCats({required this.onAddCat, this.plusKey});

  final VoidCallback onAddCat;
  final Key? plusKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "It's a little quiet in here.",
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Add your first cat to get Neko started.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        AddCatSection(plusKey: plusKey, onTap: onAddCat),
      ],
    );
  }
}
