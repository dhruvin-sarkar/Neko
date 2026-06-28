import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:zo_animated_border/zo_animated_border.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/services/audio_service.dart';
import '../../data/breed_catalog.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/step_headline.dart';

/// Step 3 — breed picker: a searchable, category-filtered grid. Only the
/// presentation changed; the chosen breed name still writes to
/// `OnboardingDraft.breed` via [OnboardingNotifier.setBreed].
class BreedStep extends ConsumerStatefulWidget {
  const BreedStep({super.key});

  @override
  ConsumerState<BreedStep> createState() => _BreedStepState();
}

class _BreedStepState extends ConsumerState<BreedStep> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  String _query = '';
  BreedCategory? _category; // null = "All"

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  void _select(String breed) {
    HapticFeedback.lightImpact();
    AudioService.playClickSoft();
    ref.read(onboardingNotifierProvider.notifier).setBreed(breed);
  }

  @override
  Widget build(BuildContext context) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final String? selected = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.breed),
    );
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();
    final bool searching = _query.isNotEmpty;
    final List<CatBreed> results = searching
        ? BreedCatalog.search(_query)
        : BreedCatalog.forCategory(_category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('What breed is $display?'),
        const SizedBox(height: 16),
        _searchBar(),
        const SizedBox(height: 12),
        if (!searching) _categoryChips(),
        if (!searching) const SizedBox(height: 12),
        Expanded(
          child: results.isEmpty ? _emptyState() : _grid(results, selected),
        ),
      ],
    );
  }

  Widget _searchBar() {
    final Widget field = Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(30),
        border: _focus.hasFocus ? null : Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focus,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyMedium,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search breeds...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _searchCtrl.text.isNotEmpty ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: GestureDetector(
              onTap: _clearSearch,
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );

    if (!_focus.hasFocus) return field;
    return ZoAnimatedGradientBorder(
      borderRadius: 30,
      borderThickness: 2,
      glowOpacity: 0.3,
      animationDuration: const Duration(milliseconds: 2800),
      gradientColor: <Color>[
        AppColors.primary,
        AppColors.secondary,
        AppColors.primary,
      ],
      child: field,
    );
  }

  Widget _categoryChips() {
    final List<BreedCategory?> cats = <BreedCategory?>[
      null,
      ...BreedCategory.values,
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final BreedCategory? c = cats[index];
          final bool active = c == _category;
          return GestureDetector(
            onTap: () {
              AudioService.playClickSoft();
              setState(() => _category = c);
            },
            child: AnimatedScale(
              scale: active ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryLight
                      : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Text(
                  c?.label ?? 'All',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _grid(List<CatBreed> breeds, String? selected) {
    return AnimationLimiter(
      key: ValueKey<String>('$_category-$_query-${breeds.length}'),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
        ),
        itemCount: breeds.length,
        itemBuilder: (context, index) {
          final CatBreed breed = breeds[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            columnCount: 2,
            duration: const Duration(milliseconds: 300),
            child: FadeInAnimation(
              child: SlideAnimation(
                verticalOffset: 20,
                child: _BreedCard(
                  name: breed.name,
                  selected: selected == breed.name,
                  onTap: () => _select(breed.name),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍🐱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              "No breeds found for '$_query'",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              "Try 'British' or 'short hair'",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _select(_query),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  'Add "$_query" as custom breed',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single breed card: name on the left, a faint decorative paw glyph on the
/// right. Springs slightly when selected.
class _BreedCard extends StatelessWidget {
  const _BreedCard({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: selected ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLight : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    // UI DECISION: no silhouette PNG is bundled, so a tinted paw
                    // glyph stands in as the decorative mark.
                    Icon(
                      Icons.pets_rounded,
                      size: 28,
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ],
                ),
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
