// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$catProfilesHash() => r'61816ebb5d4dc6766731572cddd9ac795050745b';

/// Streams the signed-in user's cat profiles. Emits an empty list while signed
/// out so the UI never reads from a repository without a user.
///
/// Copied from [catProfiles].
@ProviderFor(catProfiles)
final catProfilesProvider =
    AutoDisposeStreamProvider<List<CatProfile>>.internal(
      catProfiles,
      name: r'catProfilesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$catProfilesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CatProfilesRef = AutoDisposeStreamProviderRef<List<CatProfile>>;
String _$catByIdHash() => r'0bfeff1da7a843982e3025eb7c3c397da993ed38';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Looks up a single cat by id from the streamed list. Returns `null` while the
/// list is still loading or if the cat no longer exists.
///
/// Copied from [catById].
@ProviderFor(catById)
const catByIdProvider = CatByIdFamily();

/// Looks up a single cat by id from the streamed list. Returns `null` while the
/// list is still loading or if the cat no longer exists.
///
/// Copied from [catById].
class CatByIdFamily extends Family<CatProfile?> {
  /// Looks up a single cat by id from the streamed list. Returns `null` while the
  /// list is still loading or if the cat no longer exists.
  ///
  /// Copied from [catById].
  const CatByIdFamily();

  /// Looks up a single cat by id from the streamed list. Returns `null` while the
  /// list is still loading or if the cat no longer exists.
  ///
  /// Copied from [catById].
  CatByIdProvider call(String catId) {
    return CatByIdProvider(catId);
  }

  @override
  CatByIdProvider getProviderOverride(covariant CatByIdProvider provider) {
    return call(provider.catId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'catByIdProvider';
}

/// Looks up a single cat by id from the streamed list. Returns `null` while the
/// list is still loading or if the cat no longer exists.
///
/// Copied from [catById].
class CatByIdProvider extends AutoDisposeProvider<CatProfile?> {
  /// Looks up a single cat by id from the streamed list. Returns `null` while the
  /// list is still loading or if the cat no longer exists.
  ///
  /// Copied from [catById].
  CatByIdProvider(String catId)
    : this._internal(
        (ref) => catById(ref as CatByIdRef, catId),
        from: catByIdProvider,
        name: r'catByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$catByIdHash,
        dependencies: CatByIdFamily._dependencies,
        allTransitiveDependencies: CatByIdFamily._allTransitiveDependencies,
        catId: catId,
      );

  CatByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.catId,
  }) : super.internal();

  final String catId;

  @override
  Override overrideWith(CatProfile? Function(CatByIdRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: CatByIdProvider._internal(
        (ref) => create(ref as CatByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        catId: catId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<CatProfile?> createElement() {
    return _CatByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CatByIdProvider && other.catId == catId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, catId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CatByIdRef on AutoDisposeProviderRef<CatProfile?> {
  /// The parameter `catId` of this provider.
  String get catId;
}

class _CatByIdProviderElement extends AutoDisposeProviderElement<CatProfile?>
    with CatByIdRef {
  _CatByIdProviderElement(super.provider);

  @override
  String get catId => (origin as CatByIdProvider).catId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
