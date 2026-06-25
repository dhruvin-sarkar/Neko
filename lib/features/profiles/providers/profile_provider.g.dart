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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
