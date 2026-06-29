import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/services/feedback_service.dart';
import '../../profiles/providers/profile_provider.dart';
import '../data/tour_persistence.dart';
import '../providers/tour_keys.dart';
import 'widgets/tour_card.dart';

/// Describes one spotlight step.
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

  bool get isProfile => identify.startsWith('profile_');
}

/// The premium first-run guided tour.
///
/// Runs once per user (tracked in Firestore `users/{uid}.guidedTourComplete`,
/// mirrored to a local cache). It spans three segments: a Home intro, a deep
/// dive into a cat's profile (it actually opens the profile and points out the
/// stats, edit action, and documents), then back to Home for the add-cat and
/// Settings affordances — all with one continuous progress indicator.
class HomeTour {
  HomeTour._();

  static const String _flagField = 'guidedTourComplete';
  static String? _handledUid;

  /// Shows the tour if the signed-in user hasn't seen it yet. Safe to call on
  /// every Home build — it no-ops once running or completed.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final String? uid = ref.read(
      authStateChangesProvider.select((v) => v.valueOrNull?.uid),
    );
    if (uid == null || uid == _handledUid) return;

    final TourPersistence persistence = ref.read(tourPersistenceProvider);
    if (persistence.hasSeen(uid)) {
      _handledUid = uid;
      return;
    }
    _handledUid = uid;

    final FirebaseFirestore firestore = ref.read(firestoreProvider);
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if ((doc.data()?[_flagField] as bool?) ?? false) {
        await persistence.markSeen(uid);
        return;
      }
    } on Object {
      // Offline — proceed; completion is still recorded locally afterwards.
    }
    if (!context.mounted) return;

    await _TourRunner(
      context: context,
      ref: ref,
      persistence: persistence,
      uid: uid,
    ).run();
  }
}

/// Orchestrates the multi-screen tour: shows each segment's coach marks, drives
/// the navigation between Home and the cat profile, and records completion.
class _TourRunner {
  _TourRunner({
    required this.context,
    required this.ref,
    required this.persistence,
    required this.uid,
  });

  final BuildContext context;
  final WidgetRef ref;
  final TourPersistence persistence;
  final String uid;

  late final TourKeys _keys = ref.read(tourKeysProvider);
  late final FeedbackService _feedback = ref.read(feedbackServiceProvider);

  bool _done = false;

  Future<void> run() async {
    final cats = ref.read(catProfilesProvider).valueOrNull ?? const [];
    final bool hasCats = cats.isNotEmpty;
    final String? catId = hasCats ? cats.first.id : null;

    final List<_Step> homeIntro = <_Step>[_greeting, if (hasCats) _firstCat];
    final List<_Step> profile = hasCats
        ? <_Step>[_profileStats, _profileEdit, _profileDocuments]
        : <_Step>[];
    final List<_Step> homeOutro = <_Step>[_addCat, _aiAssistant, _settings];
    final int total = homeIntro.length + profile.length + homeOutro.length;
    int offset = 0;

    // ── Segment 1: Home intro ──
    await _scrollToTop(ref.read(homeScrollControllerProvider));
    final bool ready = await _waitFor(
      () =>
          _keys.greeting.currentContext != null &&
          _keys.navSettings.currentContext != null &&
          ref.read(catProfilesProvider).hasValue,
    );
    if (!ready || !context.mounted) return _complete();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!context.mounted) return _complete();

    if (await _showSegment(homeIntro, offset, total)) return _complete();
    offset += homeIntro.length;

    // ── Segment 2: the cat profile (opens it, then tours it) ──
    if (hasCats && catId != null) {
      if (!context.mounted) return _complete();
      unawaited(_feedback.onTap());
      context.push(Routes.profile(catId));

      final bool profileReady = await _waitFor(
        () =>
            _keys.profileEdit.currentContext != null &&
            _keys.profileStats.currentContext != null,
      );
      if (profileReady) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (context.mounted && await _showSegment(profile, offset, total)) {
          _popToHome();
          return _complete();
        }
      }
      offset += profile.length;

      _popToHome();
      await _waitFor(
        () =>
            _keys.addCatPlus.currentContext != null &&
            _keys.navSettings.currentContext != null,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    // ── Segment 3: Home outro ──
    if (!context.mounted) return _complete();
    await _showSegment(homeOutro, offset, total);
    return _complete();
  }

  /// Records completion locally (instant/offline) and in Firestore.
  Future<void> _complete() async {
    if (_done) return;
    _done = true;
    await persistence.markSeen(uid);
    try {
      await ref.read(firestoreProvider).collection('users').doc(uid).set({
        HomeTour._flagField: true,
      }, SetOptions(merge: true));
    } on Object {
      // Best-effort; the local cache already prevents re-showing here.
    }
  }

  /// Pops the cat profile route if it's currently on top.
  void _popToHome() {
    if (context.mounted && context.canPop()) context.pop();
  }

  /// Shows one segment's coach marks; resolves `true` if the user skipped.
  Future<bool> _showSegment(List<_Step> steps, int offset, int total) async {
    if (steps.isEmpty) return false;
    await _reveal(steps.first);
    await _settle(steps.first.key);
    if (!context.mounted) return true;

    final Completer<bool> result = Completer<bool>();
    final List<TargetFocus> targets = <TargetFocus>[
      for (int i = 0; i < steps.length; i++)
        _targetFor(steps, i, offset, total),
    ];

    unawaited(_feedback.onTap());
    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.almostBlack,
      opacityShadow: 0.85,
      paddingFocus: 10,
      pulseEnable: false,
      hideSkip: true,
      focusAnimationDuration: const Duration(milliseconds: 550),
      unFocusAnimationDuration: const Duration(milliseconds: 550),
      onClickTarget: (_) => unawaited(_feedback.onTap()),
      onFinish: () {
        if (!result.isCompleted) result.complete(false);
      },
      onSkip: () {
        if (!result.isCompleted) result.complete(true);
        return true;
      },
    ).show(context: context, rootOverlay: true);

    return result.future;
  }

  TargetFocus _targetFor(
    List<_Step> steps,
    int localIndex,
    int offset,
    int total,
  ) {
    final _Step step = steps[localIndex];
    final int globalIndex = offset + localIndex;
    return TargetFocus(
      identify: step.identify,
      keyTarget: step.key,
      shape: step.shape,
      radius: step.radius,
      enableOverlayTab: false,
      enableTargetTab: false,
      contents: [
        TargetContent(
          align: step.align,
          builder: (ctx, controller) {
            final double screenWidth = MediaQuery.of(ctx).size.width;
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
              stepIndex: globalIndex,
              stepCount: total,
              pointerUp: step.align == ContentAlign.bottom,
              targetCenterX: targetCenterX,
              availableWidth: screenWidth,
              onBack: localIndex == 0
                  ? null
                  : () async {
                      unawaited(_feedback.onTap());
                      await _reveal(steps[localIndex - 1]);
                      controller.previous();
                    },
              onNext: () async {
                unawaited(_feedback.onAdvance());
                if (localIndex + 1 < steps.length) {
                  await _reveal(steps[localIndex + 1]);
                }
                controller.next();
              },
              onSkip: () {
                unawaited(_feedback.onTap());
                controller.skip();
              },
            );
          },
        ),
      ],
    );
  }

  /// Scrolls the right list so [step]'s target is on screen before spotlighting.
  Future<void> _reveal(_Step step) async {
    final ScrollController c = step.isProfile
        ? ref.read(profileScrollControllerProvider)
        : ref.read(homeScrollControllerProvider);
    if (!c.hasClients) return;

    final double target;
    switch (step.identify) {
      case 'greeting':
      case 'first_cat':
      case 'profile_stats':
        target = 0;
      case 'add_cat':
      case 'profile_documents':
        target = c.position.maxScrollExtent;
      default:
        return; // Settings + edit live in fixed bars — nothing to scroll.
    }

    if ((c.offset - target).abs() > 1) {
      await c.animateTo(
        target,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
    final BuildContext? ctx = step.key.currentContext;
    if (ctx != null && ctx.mounted) {
      final bool atBottom =
          step.identify == 'add_cat' || step.identify == 'profile_documents';
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: atBottom ? 0.65 : 0.2,
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  /// Waits until [key]'s on-screen position has settled before the coach mark
  /// captures it. Content slides in on first build, and a staggered entrance
  /// can hold a target at its start position for a beat — so I let the entrance
  /// finish, then confirm the position is steady. Without this the spotlight
  /// locks onto a stale, offset position.
  Future<void> _settle(GlobalKey key) async {
    final Stopwatch sw = Stopwatch()..start();
    Offset? last;
    while (sw.elapsedMilliseconds < 2000) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final Offset pos = box.localToGlobal(Offset.zero);
        if (sw.elapsedMilliseconds > 750 &&
            last != null &&
            (pos - last).distance < 0.5) {
          return;
        }
        last = pos;
      }
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
  }

  Future<void> _scrollToTop(ScrollController c) async {
    if (!c.hasClients || c.offset <= 1) return;
    await c.animateTo(
      0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<bool> _waitFor(bool Function() isReady) async {
    const Duration step = Duration(milliseconds: 80);
    for (int i = 0; i < 70; i++) {
      if (isReady()) return true;
      await Future<void>.delayed(step);
    }
    return isReady();
  }

  // ── Step definitions ──

  _Step get _greeting => _Step(
    key: _keys.greeting,
    identify: 'greeting',
    icon: Icons.waving_hand_rounded,
    title: 'Welcome to Neko',
    body:
        "This is your home base. We'll keep your cats and their care close at hand — here's the quick tour.",
    align: ContentAlign.bottom,
    shape: ShapeLightFocus.RRect,
    radius: 18,
  );

  _Step get _firstCat => _Step(
    key: _keys.firstCat,
    identify: 'first_cat',
    icon: Icons.pets_rounded,
    title: 'Your crew',
    body:
        "Each cat has its own profile. Let's open this one and see what's inside.",
    align: ContentAlign.bottom,
    shape: ShapeLightFocus.RRect,
    radius: 24,
  );

  _Step get _profileStats => _Step(
    key: _keys.profileStats,
    identify: 'profile_stats',
    icon: Icons.insights_rounded,
    title: 'The essentials',
    body:
        'Age, weight, activity, and a daily calorie target — the key numbers, all at a glance.',
    align: ContentAlign.bottom,
    shape: ShapeLightFocus.RRect,
    radius: 18,
  );

  _Step get _profileEdit => _Step(
    key: _keys.profileEdit,
    identify: 'profile_edit',
    icon: Icons.edit_rounded,
    title: 'Edit anytime',
    body:
        'Tap here to update the name, weight, photo, and other details whenever they change.',
    align: ContentAlign.bottom,
    shape: ShapeLightFocus.Circle,
  );

  _Step get _profileDocuments => _Step(
    key: _keys.profileDocuments,
    identify: 'profile_documents',
    icon: Icons.upload_file_rounded,
    title: 'Keep records safe',
    body:
        'Upload vaccination cards, passports, and vet records so they are always with you.',
    align: ContentAlign.top,
    shape: ShapeLightFocus.RRect,
    radius: 18,
  );

  _Step get _addCat => _Step(
    key: _keys.addCatPlus,
    identify: 'add_cat',
    icon: Icons.add_rounded,
    title: 'Add a cat',
    body:
        'Back home — tap the plus to add another member of the family anytime.',
    align: ContentAlign.top,
    shape: ShapeLightFocus.Circle,
  );

  _Step get _aiAssistant => _Step(
    key: _keys.navChat,
    identify: 'ai_assistant',
    icon: Icons.auto_awesome_rounded,
    title: 'Meet Neko AI',
    body:
        'Your cat-obsessed assistant lives here. Ask about feeding, health, or '
        'behaviour — Neko knows your cats by name.',
    align: ContentAlign.top,
    shape: ShapeLightFocus.Circle,
  );

  _Step get _settings => _Step(
    key: _keys.navSettings,
    identify: 'settings',
    icon: Icons.settings_rounded,
    title: 'Settings live here',
    body:
        'Manage your account, preferences, and sign-out from here. That is the tour — enjoy Neko!',
    align: ContentAlign.top,
    shape: ShapeLightFocus.Circle,
  );
}
