import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/neko_motion.dart';
import '../../../features/tour/providers/tour_keys.dart';
import '../../documents/ui/widgets/documents_section.dart';
import 'widgets/profile_detail_shimmer.dart';
import '../../onboarding/models/cat_profile.dart';
import '../providers/profile_provider.dart';
import 'widgets/cat_avatar.dart';

/// Full-screen profile for a single cat: avatar, name, breed, and key stats.
class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.catId});

  final String catId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoading = ref.watch(
      catProfilesProvider.select((v) => v.isLoading),
    );
    final CatProfile? cat = ref.watch(catByIdProvider(catId));
    final TourKeys tourKeys = ref.watch(tourKeysProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
        actions: [
          if (cat != null)
            IconButton(
              key: tourKeys.profileEdit,
              tooltip: 'Edit',
              onPressed: () => context.push(Routes.editCat(catId)),
              icon: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : NekoMotion.standard,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: cat == null
              ? (isLoading
                    ? const ProfileDetailShimmer(key: ValueKey('loading'))
                    : const _NotFound(key: ValueKey('not-found')))
              : _CatProfileBody(
                  key: ValueKey(cat.id),
                  cat: cat,
                  tourKeys: tourKeys,
                  scrollController: ref.read(profileScrollControllerProvider),
                ),
        ),
      ),
    );
  }
}

class _CatProfileBody extends StatelessWidget {
  const _CatProfileBody({
    super.key,
    required this.cat,
    required this.tourKeys,
    required this.scrollController,
  });

  final CatProfile cat;
  final TourKeys tourKeys;
  final ScrollController scrollController;

  String get _ageLabel {
    if (cat.years > 0) {
      return cat.months > 0 ? '${cat.years}y ${cat.months}m' : '${cat.years}y';
    }
    return '${cat.months}m';
  }

  String get _activityLabel {
    return switch (cat.activityLevel) {
      'couch' => 'Low Activity',
      'outdoor' => 'Highly Active',
      _ => 'Moderately Active',
    };
  }

  String? get _addedLabel {
    final DateTime? date = cat.createdAt;
    if (date == null) return null;
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[(date.month - 1).clamp(0, 11)];
    return 'Added ${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: <Widget>[
        // The avatar (and name/breed) sit in a grounded header card, outside
        // the staggered entrance, so the Hero flight from the home banner lands
        // inside a designed surface — the hand-off reads as the banner opening
        // up, not an avatar floating onto the page.
        _ProfileHeader(cat: cat, addedLabel: _addedLabel),
        const SizedBox(height: 24),
        ...<Widget>[
              KeyedSubtree(
                key: tourKeys.profileStats,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: _ageLabel,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Weight',
                            value: '${cat.weightKg} kg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.directions_run_rounded,
                            label: 'Activity',
                            value: _activityLabel,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Daily target',
                            value: '${cat.dailyCalorieTarget} kcal',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              KeyedSubtree(
                key: tourKeys.profileDocuments,
                child: DocumentsSection(catId: cat.id),
              ),
            ]
            // Hold the in-body stagger until the route reveal has settled, so the
            // stats aren't fading on top of the page's own fade-in.
            .animate(delay: 220.ms, interval: 70.ms)
            .fadeIn(duration: 250.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

/// The grounded profile header: the Hero avatar, name and breed inside a soft
/// elevated card. Gives the avatar a designed place to land after its flight
/// from the home banner.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.cat, required this.addedLabel});

  final CatProfile cat;
  final String? addedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CatAvatar(
            colorType: cat.colorType,
            catId: cat.id,
            avatarPreset: cat.avatarPreset,
            size: 112,
            borderWidth: 3,
            heroTag: 'cat-avatar-${cat.id}',
          ),
          const SizedBox(height: 16),
          Text(
            cat.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge,
          ),
          const SizedBox(height: 4),
          Text(
            cat.breed,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (addedLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              addedLabel!,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "Hmm, we can't find that cat.",
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLarge,
        ),
      ),
    );
  }
}
