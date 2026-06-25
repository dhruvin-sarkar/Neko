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
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            sliver: SliverToBoxAdapter(
              child: HomeGreeting(
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
            data: (list) => _catSlivers(list, openCat, addCat),
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
) {
  if (cats.isEmpty) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        sliver: SliverToBoxAdapter(child: _EmptyCats(onAddCat: onAddCat)),
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
          return Padding(
            key: ValueKey<String>(cat.id),
            padding: const EdgeInsets.only(bottom: 16),
            child:
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
                    ),
          );
        },
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      sliver: SliverToBoxAdapter(child: AddCatSection(onTap: onAddCat)),
    ),
  ];
}

class _EmptyCats extends StatelessWidget {
  const _EmptyCats({required this.onAddCat});

  final VoidCallback onAddCat;

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
        AddCatSection(onTap: onAddCat),
      ],
    );
  }
}
