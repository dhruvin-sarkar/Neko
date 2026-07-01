import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/notch_controller.dart';
import '../../models/notch_activity.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// A mirrored app notification. Self-dismisses after 4s (a notification is
/// transient — it shouldn't linger in the notch).
class NotificationContent extends ConsumerStatefulWidget {
  const NotificationContent({super.key, required this.activity});

  final NotificationActivity activity;

  @override
  ConsumerState<NotificationContent> createState() =>
      _NotificationContentState();
}

class _NotificationContentState extends ConsumerState<NotificationContent> {
  Timer? _dismiss;

  @override
  void initState() {
    super.initState();
    _armDismiss();
  }

  @override
  void didUpdateWidget(NotificationContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The activity is replaced in place (State persists), so a genuinely new
    // notification must get its own full 4s rather than the previous schedule.
    if (widget.activity.id != oldWidget.activity.id) _armDismiss();
  }

  void _armDismiss() {
    _dismiss?.cancel();
    _dismiss = Timer(const Duration(seconds: 4), () {
      // Don't yank it away while the user has tapped to expand it.
      if (ref.read(notchControllerProvider).userExpanded) return;
      ref
          .read(notchControllerProvider.notifier)
          .remove<NotificationActivity>()
          .ignore();
    });
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotchCompactRow(
      leading: const Icon(
        Icons.notifications_rounded,
        size: 18,
        color: NotchStyle.coral,
      ),
      primary: widget.activity.title.isNotEmpty
          ? widget.activity.title
          : widget.activity.appName,
      secondary: widget.activity.body.isNotEmpty
          ? widget.activity.body
          : widget.activity.appName,
    );
  }
}
