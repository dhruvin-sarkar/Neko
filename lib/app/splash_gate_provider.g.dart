// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_gate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$splashGateHash() => r'70a81e1690fa82b5931f0cb2f19c87d2f635f860';

/// Becomes `true` once the minimum splash duration has elapsed. The router
/// keeps the app on `/splash` until this is `true` (and auth has resolved).
///
/// Copied from [SplashGate].
@ProviderFor(SplashGate)
final splashGateProvider = NotifierProvider<SplashGate, bool>.internal(
  SplashGate.new,
  name: r'splashGateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$splashGateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SplashGate = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
