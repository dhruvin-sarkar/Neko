/// Breed categories used by the onboarding breed selector's filter chips.
enum BreedCategory { popular, shortHair, longHair, hairless, wild, unknown }

extension BreedCategoryLabel on BreedCategory {
  String get label => switch (this) {
    BreedCategory.popular => 'Popular',
    BreedCategory.shortHair => 'Short Hair',
    BreedCategory.longHair => 'Long Hair',
    BreedCategory.hairless => 'Hairless',
    BreedCategory.wild => 'Wild Type',
    BreedCategory.unknown => 'Unknown',
  };
}

/// A selectable breed and the categories it belongs to (some span more than
/// one, e.g. Bengal is Popular and Wild Type).
class CatBreed {
  const CatBreed(this.name, this.categories);

  final String name;
  final Set<BreedCategory> categories;
}

/// The full breed catalogue. The selector only changes presentation; the value
/// written to `OnboardingDraft.breed` is still the plain breed name string.
abstract final class BreedCatalog {
  const BreedCatalog._();

  static const List<CatBreed> all = <CatBreed>[
    // Popular
    CatBreed('British Shorthair', {BreedCategory.popular}),
    CatBreed('Maine Coon', {BreedCategory.popular}),
    CatBreed('Persian', {BreedCategory.popular}),
    CatBreed('Ragdoll', {BreedCategory.popular}),
    CatBreed('Scottish Fold', {BreedCategory.popular}),
    CatBreed('Siamese', {BreedCategory.popular}),
    CatBreed('Bengal', {BreedCategory.popular, BreedCategory.wild}),
    CatBreed('Sphynx', {BreedCategory.popular, BreedCategory.hairless}),
    CatBreed('Abyssinian', {BreedCategory.popular}),
    CatBreed('Burmese', {BreedCategory.popular}),
    CatBreed('Russian Blue', {BreedCategory.popular}),
    CatBreed('Norwegian Forest Cat', {BreedCategory.popular}),
    CatBreed('Birman', {BreedCategory.popular}),
    CatBreed('Tonkinese', {BreedCategory.popular}),
    CatBreed('Devon Rex', {BreedCategory.popular}),
    CatBreed('Exotic Shorthair', {BreedCategory.popular}),
    CatBreed('American Shorthair', {BreedCategory.popular}),
    // Short hair
    CatBreed('Cornish Rex', {BreedCategory.shortHair}),
    CatBreed('Manx', {BreedCategory.shortHair}),
    CatBreed('Chartreux', {BreedCategory.shortHair}),
    CatBreed('Japanese Bobtail', {BreedCategory.shortHair}),
    CatBreed('Ocicat', {BreedCategory.shortHair}),
    CatBreed('Bombay', {BreedCategory.shortHair}),
    CatBreed('Havana Brown', {BreedCategory.shortHair}),
    CatBreed('Singapura', {BreedCategory.shortHair}),
    CatBreed('Korat', {BreedCategory.shortHair}),
    CatBreed('Burmilla', {BreedCategory.shortHair}),
    CatBreed('Australian Mist', {BreedCategory.shortHair}),
    CatBreed('Snowshoe', {BreedCategory.shortHair}),
    CatBreed('Selkirk Rex (short variant)', {BreedCategory.shortHair}),
    CatBreed('Savannah', {BreedCategory.shortHair, BreedCategory.wild}),
    CatBreed('Egyptian Mau', {BreedCategory.shortHair}),
    CatBreed('Pixiebob', {BreedCategory.shortHair}),
    // Long hair
    CatBreed('Turkish Angora', {BreedCategory.longHair}),
    CatBreed('Turkish Van', {BreedCategory.longHair}),
    CatBreed('Himalayan', {BreedCategory.longHair}),
    CatBreed('Balinese', {BreedCategory.longHair}),
    CatBreed('Somali', {BreedCategory.longHair}),
    CatBreed('Tiffany / Chantilly', {BreedCategory.longHair}),
    CatBreed('LaPerm', {BreedCategory.longHair}),
    CatBreed('Selkirk Rex (long variant)', {BreedCategory.longHair}),
    CatBreed('Nebelung', {BreedCategory.longHair}),
    CatBreed('Siberian', {BreedCategory.longHair}),
    CatBreed('RagaMuffin', {BreedCategory.longHair}),
    CatBreed('Cymric', {BreedCategory.longHair}),
    // Hairless
    CatBreed('Peterbald', {BreedCategory.hairless}),
    CatBreed('Donskoy / Don Sphynx', {BreedCategory.hairless}),
    CatBreed('Bambino', {BreedCategory.hairless}),
    CatBreed('Elf Cat', {BreedCategory.hairless}),
    CatBreed('Ukrainian Levkoy', {BreedCategory.hairless}),
    // Wild type
    CatBreed('Chausie', {BreedCategory.wild}),
    CatBreed('Serengeti', {BreedCategory.wild}),
    CatBreed('Toyger', {BreedCategory.wild}),
    CatBreed('Caracat', {BreedCategory.wild}),
    // Unknown / mixed
    CatBreed('Domestic Shorthair (Mixed)', {BreedCategory.unknown}),
    CatBreed('Domestic Longhair (Mixed)', {BreedCategory.unknown}),
    CatBreed('Unknown Breed', {BreedCategory.unknown}),
  ];

  /// "All" view: popular breeds pinned to the top, then everything else
  /// alphabetically.
  static final List<CatBreed> allSorted = () {
    final List<CatBreed> popular = all
        .where((b) => b.categories.contains(BreedCategory.popular))
        .toList();
    final List<CatBreed> rest =
        all.where((b) => !b.categories.contains(BreedCategory.popular)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return <CatBreed>[...popular, ...rest];
  }();

  /// Breeds in [category], or [allSorted] when [category] is null.
  static List<CatBreed> forCategory(BreedCategory? category) {
    if (category == null) return allSorted;
    return all.where((b) => b.categories.contains(category)).toList();
  }

  /// Case-insensitive name search across the whole catalogue.
  static List<CatBreed> search(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return allSorted;
    return allSorted.where((b) => b.name.toLowerCase().contains(q)).toList();
  }
}
