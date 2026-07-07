import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/notch/controller/notch_controller.dart';
import '../../../core/notch/model/notch_activity.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/models/chat_attachment.dart';
import '../../chat/models/chat_message.dart';
import '../../onboarding/models/cat_profile.dart';
import '../../profiles/providers/profile_provider.dart';
import '../../../shared/services/image_picker_service.dart';
import '../models/safety_verdict.dart';

/// Where a safety scan is in its lifecycle.
enum SafetyScanPhase { idle, capturing, analyzing, result, error }

/// Immutable snapshot of the current safety scan.
@immutable
class SafetyScanState {
  const SafetyScanState({
    this.phase = SafetyScanPhase.idle,
    this.photoPath,
    this.verdict,
    this.message,
  });

  final SafetyScanPhase phase;

  /// The captured photo's local path — held only for the on-screen preview and
  /// the one API call, never written into chat history or storage.
  final String? photoPath;

  final SafetyVerdict? verdict;

  /// Error/hint text for the sheet (camera denied, no photo, request failed).
  final String? message;

  SafetyScanState copyWith({
    SafetyScanPhase? phase,
    String? photoPath,
    SafetyVerdict? verdict,
    String? message,
  }) {
    return SafetyScanState(
      phase: phase ?? this.phase,
      photoPath: photoPath ?? this.photoPath,
      verdict: verdict ?? this.verdict,
      message: message ?? this.message,
    );
  }
}

final safetyScanControllerProvider =
    NotifierProvider<SafetyScanController, SafetyScanState>(
      SafetyScanController.new,
    );

/// Runs a cat-safety scan: capture a photo, ask the shared [ChatService] to
/// judge it (with `safety: true`), parse the verdict, and mirror a short result
/// to the notch. The photo is used for the single request and then dropped — it
/// is never persisted.
class SafetyScanController extends Notifier<SafetyScanState> {
  static const String _activityId = 'safety_scan';

  StreamSubscription<String>? _sub;
  bool _disposed = false;

  @override
  SafetyScanState build() {
    ref.onDispose(() {
      _disposed = true;
      _sub?.cancel();
    });
    return const SafetyScanState();
  }

  /// Opens the camera and analyses whatever the owner points it at. [source]
  /// defaults to the camera but the gallery is allowed for testing / re-scans.
  Future<void> scan({ImageSource source = ImageSource.camera}) async {
    if (state.phase == SafetyScanPhase.capturing ||
        state.phase == SafetyScanPhase.analyzing) {
      return;
    }
    state = const SafetyScanState(phase: SafetyScanPhase.capturing);

    final String? path = await ref
        .read(imagePickerServiceProvider)
        .pick(source);
    if (_disposed) return;
    if (path == null) {
      // Cancelled or denied — image_picker already surfaced any permission UI.
      state = state.copyWith(
        phase: SafetyScanPhase.error,
        message:
            'No photo captured. Point the camera at the item and try '
            'again — or check camera access in Settings.',
      );
      return;
    }

    state = SafetyScanState(phase: SafetyScanPhase.analyzing, photoPath: path);
    unawaited(
      _pushActivity(title: 'Safety check', subtitle: 'Neko’s looking…'),
    );

    final List<CatProfile> cats =
        ref.read(catProfilesProvider).valueOrNull ?? const <CatProfile>[];
    final String? catContext = cats.isEmpty
        ? null
        : cats.map((CatProfile c) => c.toAIContext()).join('\n\n');

    final ChatMessage message = ChatMessage(
      id: 'safety-scan',
      role: ChatRole.user,
      content: 'Is this safe for my cat?',
      attachments: <ChatAttachment>[
        ChatAttachment(path: path, name: 'safety-scan'),
      ],
    );

    final StringBuffer buffer = StringBuffer();
    _sub?.cancel();
    _sub = ref
        .read(chatServiceProvider)
        .streamReply(
          <ChatMessage>[message],
          catContext: catContext,
          safety: true,
        )
        .listen(
          buffer.write,
          onDone: () {
            _sub = null;
            _finish(buffer.toString());
          },
          onError: (Object error) {
            _sub = null;
            if (_disposed) return;
            unawaited(_removeActivity());
            final String msg = error is ChatException
                ? error.message
                : 'Meow — the safety check slipped away. Let’s try that again?';
            state = state.copyWith(phase: SafetyScanPhase.error, message: msg);
          },
        );
  }

  void _finish(String reply) {
    if (_disposed) return;
    final SafetyVerdict verdict = SafetyVerdict.parse(reply);
    state = state.copyWith(phase: SafetyScanPhase.result, verdict: verdict);
    unawaited(
      _pushActivity(
        title: 'Safety: ${verdict.headline}',
        subtitle: verdict.detail,
        ongoing: false,
      ),
    );
  }

  /// Clears everything (sheet closed). Also drops the transient photo reference.
  void reset() {
    _sub?.cancel();
    _sub = null;
    unawaited(_removeActivity());
    if (_disposed) return;
    state = const SafetyScanState();
  }

  // ── Notch mirror ────────────────────────────────────────────────────────────

  Future<void> _pushActivity({
    required String title,
    required String subtitle,
    bool ongoing = true,
  }) {
    return ref
        .read(notchControllerProvider.notifier)
        .showActivity(
          NotchActivity(
            type: NotchActivityType.notification,
            id: _activityId,
            title: title,
            subtitle: subtitle,
            appName: 'Neko',
            ongoing: ongoing,
          ),
        );
  }

  Future<void> _removeActivity() {
    return ref
        .read(notchControllerProvider.notifier)
        .removeActivity(id: _activityId);
  }
}
