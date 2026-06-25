// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingNotifierHash() =>
    r'f052c44cb0109d1a9c6eb45b256ba943b8373669';

/// Holds the in-progress cat draft and step position for the onboarding flow.
///
/// Nothing is persisted until [save]; that call writes the cat profile and the
/// `onboardingComplete` flag atomically, after which the router redirects.
///
/// Copied from [OnboardingNotifier].
@ProviderFor(OnboardingNotifier)
final onboardingNotifierProvider =
    AutoDisposeNotifierProvider<OnboardingNotifier, OnboardingState>.internal(
      OnboardingNotifier.new,
      name: r'onboardingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onboardingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnboardingNotifier = AutoDisposeNotifier<OnboardingState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
