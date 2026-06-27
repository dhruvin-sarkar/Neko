// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingCompleteHash() =>
    r'96bc11319e91e303929bfd56d15a022c5416a4b6';

/// Streams whether the signed-in user has finished onboarding.
///
/// Emits `false` while signed out. Resolution order:
///   1. A locally-persisted flag (set the first time onboarding completes), so
///      a returning user is taken straight into the app instantly and offline.
///   2. The user's cats: anyone who already has a cat has, by definition,
///      finished onboarding. The decision is driven by the cat stream, so it
///      emits **only after** the cat list has actually loaded — a returning
///      user is therefore never momentarily routed into the add-a-cat flow (and
///      then stranded there, since `/onboarding` is intentionally sticky).
///   3. For users with no cats, the per-user `users/{uid}.onboardingComplete`
///      flag is consulted.
///
/// A positive result from (2) or (3) is cached locally so future launches
/// short-circuit on (1).
///
/// Copied from [onboardingComplete].
@ProviderFor(onboardingComplete)
final onboardingCompleteProvider = StreamProvider<bool>.internal(
  onboardingComplete,
  name: r'onboardingCompleteProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingCompleteHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OnboardingCompleteRef = StreamProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
