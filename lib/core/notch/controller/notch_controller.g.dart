// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notch_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notchControllerHash() => r'6fc5e51ab3eda7ff2a0b5403edbd90376a77fa03';

/// The single source of truth for the Neko Notch. Drives both layers at once:
/// the in-app Flutter pill (via [NotchState]) and the system `live_activities`
/// notification (via the native `NekoLiveActivityManager`).
///
/// The system layer is strictly best-effort: if `live_activities` is
/// unavailable (older Android, notification permission denied, running on a
/// desktop host), every call is caught and logged — the in-app pill keeps
/// working regardless, so the notch never throws into the UI.
///
/// Copied from [NotchController].
@ProviderFor(NotchController)
final notchControllerProvider =
    NotifierProvider<NotchController, NotchState>.internal(
      NotchController.new,
      name: r'notchControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notchControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotchController = Notifier<NotchState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
