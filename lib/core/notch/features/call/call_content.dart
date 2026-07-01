import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/notch_controller.dart';
import '../../models/notch_activity.dart';
import '../../widgets/notch_style.dart';

/// Incoming-call card (always expanded): pulsing avatar, name, and accept /
/// decline actions. In the foundation both actions simply dismiss the call.
class CallContent extends ConsumerWidget {
  const CallContent({super.key, required this.activity});

  final IncomingCallActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotchController controller = ref.read(
      notchControllerProvider.notifier,
    );
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final String initial = activity.callerName.isNotEmpty
        ? activity.callerName[0].toUpperCase()
        : '?';

    final Widget avatar = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: NotchStyle.coral,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Row(
        children: <Widget>[
          // Pulse the avatar, but honour reduce-motion like the rest of the notch.
          if (reduceMotion)
            avatar
          else
            avatar
                .animate(
                  onPlay: (AnimationController c) => c.repeat(reverse: true),
                )
                .scaleXY(
                  begin: 1.0,
                  end: 1.06,
                  duration: 900.ms,
                  curve: Curves.easeInOut,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.callerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NotchStyle.primaryLabel.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.isVideo ? 'Incoming Video Call' : 'Incoming Call',
                  style: NotchStyle.secondaryLabel.copyWith(
                    color: NotchStyle.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CallButton(
            color: NotchStyle.green,
            icon: Icons.call_rounded,
            label: 'Accept',
            onTap: () => controller.remove<IncomingCallActivity>().ignore(),
          ),
          const SizedBox(width: 8),
          _CallButton(
            color: NotchStyle.red,
            icon: Icons.call_end_rounded,
            label: 'Decline',
            onTap: () => controller.remove<IncomingCallActivity>().ignore(),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
