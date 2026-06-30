import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/neko_motion.dart';
import '../../../../core/services/audio_service.dart';
import '../../data/breed_catalog.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/step_headline.dart';

/// Step 3 — breed picker: one calm column of a search field, optional category
/// filters, and a grid of breed cards. Whatever the user types can always be
/// added as a custom breed (a card pinned to the results), so they're never
/// stuck. The chosen breed name writes to `OnboardingDraft.breed`.
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
    // Reflect the clear (×) button immediately; only the heavier query that
    // drives the search results is debounced.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _focus.unfocus();
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
    // Offer the typed text as a custom breed whenever it isn't already an exact
    // match — so a breed that isn't catalogued is still one tap away.
    final bool offerCustom =
        searching &&
        !results.any((b) => b.name.toLowerCase() == _query.toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('What breed is $display?'),
        const SizedBox(height: 6),
        Text(
          'Search, pick from the list, or add your own.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _SearchBar(
          controller: _searchCtrl,
          focusNode: _focus,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        const SizedBox(height: 12),
        if (!searching) ...[
          _CategoryChips(
            selected: _category,
            onSelect: (BreedCategory? c) {
              AudioService.playClickSoft();
              setState(() => _category = c);
            },
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: _BreedGrid(
            breeds: results,
            selectedBreed: selected,
            offerCustom: offerCustom,
            query: _query,
            category: _category,
            onSelect: _select,
          ),
        ),
      ],
    );
  }
}

/// The rounded search field for filtering breeds.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final bool focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.bodyMedium,
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search breeds…',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: controller.text.isNotEmpty ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
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
  }
}

/// The horizontal row of breed-category filter chips.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelect});

  final BreedCategory? selected;
  final ValueChanged<BreedCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<BreedCategory?> cats = <BreedCategory?>[
      null,
      ...BreedCategory.values,
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final BreedCategory? c = cats[index];
          final bool active = c == selected;
          return GestureDetector(
            onTap: () => onSelect(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                c?.label ?? 'All',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: active
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The grid of breed cards, plus a pinned custom-breed card and empty state.
class _BreedGrid extends StatelessWidget {
  const _BreedGrid({
    required this.breeds,
    required this.selectedBreed,
    required this.offerCustom,
    required this.query,
    required this.category,
    required this.onSelect,
  });

  final List<CatBreed> breeds;
  final String? selectedBreed;
  final bool offerCustom;
  final String query;
  final BreedCategory? category;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final int total = breeds.length + (offerCustom ? 1 : 0);
    if (total == 0) return const _BreedEmptyState();

    return AnimationLimiter(
      // Re-stagger when the category or search-mode changes, but not on every
      // keystroke (which would replay the whole grid animation as you type).
      key: ValueKey<String>('$category-${query.isEmpty ? 'all' : 'search'}'),
      // Clamp text scaling for these dense, fixed-height cards so an extreme OS
      // font scale can't clip a breed name; up to 1.3× is still honoured.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemCount: total,
          itemBuilder: (context, index) {
            final bool isCustom = offerCustom && index == breeds.length;
            return AnimationConfiguration.staggeredGrid(
              // Cap the cascade at ~8 cards so a full-catalogue search doesn't
              // delay the last cards heavily.
              position: index.clamp(0, 7),
              columnCount: 2,
              duration: NekoMotion.entry,
              child: FadeInAnimation(
                child: SlideAnimation(
                  verticalOffset: 18,
                  child: isCustom
                      ? _CustomBreedCard(
                          query: query,
                          onTap: () => onSelect(query),
                        )
                      : _BreedCard(
                          breed: breeds[index],
                          selected: selectedBreed == breeds[index].name,
                          onTap: () => onSelect(breeds[index].name),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shown when a category filter has no breeds (rare; the catalogue is full).
class _BreedEmptyState extends StatelessWidget {
  const _BreedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍🐱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No breeds in this filter',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single breed card: name and coat-type tag at the bottom, a faint paw mark
/// behind, a coral tick when chosen. Springs slightly on selection.
class _BreedCard extends StatelessWidget {
  const _BreedCard({
    required this.breed,
    required this.selected,
    required this.onTap,
  });

  final CatBreed breed;
  final bool selected;
  final VoidCallback onTap;

  /// A descriptive coat-type tag, preferred over the generic "Popular".
  String get _tag {
    const List<BreedCategory> order = <BreedCategory>[
      BreedCategory.shortHair,
      BreedCategory.longHair,
      BreedCategory.hairless,
      BreedCategory.wild,
      BreedCategory.unknown,
      BreedCategory.popular,
    ];
    for (final BreedCategory c in order) {
      if (breed.categories.contains(c)) return c.label;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: breed.name,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: selected ? 1.03 : 1.0,
          duration: NekoMotion.quick,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: NekoMotion.fast,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLight : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -2,
                  right: -2,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 26,
                    color: AppColors.primary.withValues(
                      alpha: selected ? 0.0 : 0.20,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breed.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_tag.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _tag,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ],
                  ),
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
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.textOnPrimary,
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

/// The "add what I typed" card, pinned to the results when the query isn't a
/// catalogued breed — so an unlisted breed is never a dead end.
class _CustomBreedCard extends StatelessWidget {
  const _CustomBreedCard({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add $query as a custom breed',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -2,
                right: -2,
                child: Icon(
                  Icons.add_circle_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add “$query”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Custom breed',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
