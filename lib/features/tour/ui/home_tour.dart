import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/services/feedback_service.dart';
import '../../profiles/providers/profile_provider.dart';
import '../data/tour_persistence.dart';
import '../providers/tour_keys.dart';
import 'widgets/tour_card.dart';

/// Describes one spotlight step before it is bound to a live target.
class _Step {
  const _Step({
    required this.key,
    required this.identify,
    required this.icon,
    required this.title,
    required this.body,
    required this.align,
    required this.shape,
    this.radius = 20,
  });

  final GlobalKey key;
  final String identify;
  final IconData icon;
  final String title;
  final String body;
  final ContentAlign align;
  final ShapeLightFocus shape;
  final double radius;
}

/// The premium first-run guided tour for the Home screen.
///
/// Shown exactly once, the first time a freshly onboarded user lands on Home.
/// "First time" is tracked per user in Firestore (`users/{uid}.guidedTour
/// Complete`) — mirroring `onboardingComplete` — with a local cache so it's
/// instant and offline-friendly. The tour scrolls each target into view before
/// spotlighting it, so the add-cat step works even under a long cat list.
class HomeTour {
  HomeTour._();

  /// Firestore field flagging whether a user has finished the guided tour.
  static const String _flagField = 'guidedTourComplete';

  /// The uid whose tour is currently running or was handled this session.
  static String? _handledUid;

  /// Shows the tour if the signed-in user hasn't seen it yet.
  ///
  /// Safe to call on every Home build — it no-ops once the tour is running or
  /// has been completed/skipped.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final String? uid = ref.read(
      authStateChangesProvider.select((v) => v.valueOrNull?.uid),
    );
    if (uid == null || uid == _handledUid) return;

    final TourPersistence persistence = ref.read(tourPersistenceProvider);
    // Fast path: a prior completion is cached on-device — no network needed.
    if (persistence.hasSeen(uid)) {
      _handledUid = uid;
      return;
    }

    // Claim the run up-front so concurrent rebuilds can't double-launch it.
    _handledUid = uid;

    final FirebaseFirestore firestore = ref.read(firestoreProvider);

    // Authoritative check: has this user already done the tour on any device?
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      final bool remoteDone = doc.data()?[_flagField] as bool? ?? false;
      if (remoteDone) {
        await persistence.markSeen(uid);
        return;
      }
    } on Object {
      // Offline or unreadable — fall through and show; we still record locally
      // (and best-effort remotely) when it finishes.
    }

    if (!context.mounted) return;

    final TourKeys keys = ref.read(tourKeysProvider);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);

    // Start at the top so the greeting / first cat are the first anchors.
    await _scrollToTop(ref);

    // Wait for the always-present anchors to mount.
    final bool ready = await _waitForTargets(
      () =>
          keys.greeting.currentContext != null &&
          keys.navSettings.currentContext != null,
    );
    if (!ready || !context.mounted) return;

    // Let entrance animations settle so the first spotlight lands cleanly.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return;

    // Decide which steps apply from the cat list state. The add-cat button may
    // be below the fold (long list) — it's included anyway and scrolled to.
    final catsAsync = ref.read(catProfilesProvider);
    final bool hasData = catsAsync.hasValue;
    final bool hasCats = (catsAsync.valueOrNull ?? const []).isNotEmpty;

    final List<_Step> live = _steps(keys).where((s) {
      return switch (s.identify) {
        'first_cat' => hasCats,
        'add_cat' => hasData,
        _ => true,
      };
    }).toList();
    if (live.isEmpty) {
      await _complete(ref, persistence, uid);
      return;
    }

    final List<TargetFocus> targets = <TargetFocus>[
      for (int i = 0; i < live.length; i++) _targetFor(ref, live, i, feedback),
    ];

    unawaited(feedback.onTap());

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.almostBlack,
      opacityShadow: 0.85,
      paddingFocus: 10,
      pulseEnable: false,
      hideSkip: true,
      focusAnimationDuration: const Duration(milliseconds: 600),
      unFocusAnimationDuration: const Duration(milliseconds: 600),
      onClickTarget: (_) => unawaited(feedback.onTap()),
      onFinish: () => unawaited(_complete(ref, persistence, uid)),
      onSkip: () {
        unawaited(_complete(ref, persistence, uid));
        return true;
      },
    ).show(context: context);
  }

  /// Records tour completion locally (instant/offline) and in Firestore.
  static Future<void> _complete(
    WidgetRef ref,
    TourPersistence persistence,
    String uid,
  ) async {
    await persistence.markSeen(uid);
    try {
      await ref.read(firestoreProvider).collection('users').doc(uid).set({
        _flagField: true,
      }, SetOptions(merge: true));
    } on Object {
      // Best-effort: the local cache already prevents re-showing on this device.
    }
  }

  /// Polls [isReady] briefly so the tour starts only once targets are laid out.
  static Future<bool> _waitForTargets(bool Function() isReady) async {
    const Duration step = Duration(milliseconds: 80);
    const int maxAttempts = 60; // ~5s ceiling
    for (int i = 0; i < maxAttempts; i++) {
      if (isReady()) return true;
      await Future<void>.delayed(step);
    }
    return isReady();
  }

  /// Animates the Home list back to the top.
  static Future<void> _scrollToTop(WidgetRef ref) async {
    final ScrollController c = ref.read(homeScrollControllerProvider);
    if (!c.hasClients || c.offset <= 1) return;
    await c.animateTo(
      0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  /// Scrolls so [step]'s target is on screen before it is spotlighted. The
  /// add-cat button lives at the bottom of a potentially long list; the
  /// greeting and first cat live at the top; Settings is in the fixed nav bar.
  static Future<void> _revealStep(WidgetRef ref, _Step step) async {
    if (step.identify == 'settings') return; // Fixed nav bar, always visible.
    final ScrollController c = ref.read(homeScrollControllerProvider);
    if (!c.hasClients) return;

    // Coarse pass: jump toward the right end of the list so the target builds.
    final double coarse = step.identify == 'add_cat'
        ? c.position.maxScrollExtent
        : 0;
    if ((c.offset - coarse).abs() > 1) {
      await c.animateTo(
        coarse,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }

    // Fine pass: now that the target is laid out, settle it comfortably in view
    // (the list's scroll extent is only estimated until children are built).
    final BuildContext? ctx = step.key.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: step.identify == 'add_cat' ? 0.65 : 0.15,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  static List<_Step> _steps(TourKeys keys) => <_Step>[
    _Step(
      key: keys.greeting,
      identify: 'greeting',
      icon: Icons.waving_hand_rounded,
      title: 'Welcome to Neko',
      body:
          "This is your home base. We'll keep your cats and their care close at hand — here's the quick tour.",
      align: ContentAlign.bottom,
      shape: ShapeLightFocus.RRect,
      radius: 18,
    ),
    _Step(
      key: keys.firstCat,
      identify: 'first_cat',
      icon: Icons.pets_rounded,
      title: 'Your crew',
      body:
          'Each cat gets their own profile. Tap a banner to open photos, weight, and records.',
      align: ContentAlign.bottom,
      shape: ShapeLightFocus.RRect,
      radius: 24,
    ),
    _Step(
      key: keys.addCatPlus,
      identify: 'add_cat',
      icon: Icons.add_rounded,
      title: 'Add a cat',
      body:
          'Tap the plus to add another member of the family. The setup only takes a moment.',
      align: ContentAlign.top,
      shape: ShapeLightFocus.Circle,
    ),
    _Step(
      key: keys.navSettings,
      identify: 'settings',
      icon: Icons.settings_rounded,
      title: 'Settings live here',
      body:
          'Tap the gear anytime to manage your account, preferences, and sign-out. That is the tour — enjoy Neko!',
      align: ContentAlign.top,
      shape: ShapeLightFocus.Circle,
    ),
  ];

  static TargetFocus _targetFor(
    WidgetRef ref,
    List<_Step> live,
    int index,
    FeedbackService feedback,
  ) {
    final _Step step = live[index];
    return TargetFocus(
      identify: step.identify,
      keyTarget: step.key,
      shape: step.shape,
      radius: step.radius,
      enableOverlayTab: false,
      // Advance only via the card's controls so we can scroll the next target
      // into view first; tapping the spotlight must not skip ahead.
      enableTargetTab: false,
      contents: [
        TargetContent(
          align: step.align,
          builder: (context, controller) {
            // Anchor the card's pointer to the target's horizontal centre.
            final double screenWidth = MediaQuery.of(context).size.width;
            final box =
                step.key.currentContext?.findRenderObject() as RenderBox?;
            double? targetCenterX;
            if (box != null && box.hasSize) {
              targetCenterX =
                  box.localToGlobal(Offset.zero).dx + box.size.width / 2;
            }

            return TourCard(
              icon: step.icon,
              title: step.title,
              body: step.body,
              stepIndex: index,
              stepCount: live.length,
              pointerUp: step.align == ContentAlign.bottom,
              targetCenterX: targetCenterX,
              availableWidth: screenWidth,
              onBack: index == 0
                  ? null
                  : () async {
                      unawaited(feedback.onTap());
                      await _revealStep(ref, live[index - 1]);
                      controller.previous();
                    },
              onNext: () async {
                unawaited(feedback.onAdvance());
                if (index + 1 < live.length) {
                  await _revealStep(ref, live[index + 1]);
                }
                controller.next();
              },
              onSkip: () {
                unawaited(feedback.onTap());
                controller.skip();
              },
            );
          },
        ),
      ],
    );
  }
}
