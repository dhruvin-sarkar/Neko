import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../models/notch_activity.dart';
import '../../widgets/notch_style.dart';

/// The Hey Neko assistant panel. Shows a cat animation + status text per phase.
/// (Voice/AI wiring lands in a later pass; this renders the phases.)
class HeyNekoContent extends StatelessWidget {
  const HeyNekoContent({super.key, required this.activity});

  final HeyNekoActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Row(
        children: <Widget>[
          SizedBox(width: 56, height: 56, child: _lottie(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _title,
                  style: NotchStyle.primaryLabel.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NotchStyle.secondaryLabel.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lottie(BuildContext context) {
    final String asset = switch (activity.phase) {
      HeyNekoPhase.thinking => 'assets/animations/cat_typing.json',
      HeyNekoPhase.responding => 'assets/animations/rainbow_cat.json',
      _ => 'assets/animations/loading_cat.json',
    };
    return Lottie.asset(
      asset,
      fit: BoxFit.contain,
      repeat: !MediaQuery.disableAnimationsOf(context),
    );
  }

  String get _title => switch (activity.phase) {
    HeyNekoPhase.waking => 'Hey Neko',
    HeyNekoPhase.listening => 'Listening…',
    HeyNekoPhase.thinking => 'Thinking…',
    HeyNekoPhase.responding => 'Neko says',
    HeyNekoPhase.idle => 'Bye~',
  };

  String get _subtitle => switch (activity.phase) {
    HeyNekoPhase.waking => '*yawns* 🐾',
    HeyNekoPhase.listening => 'say something…',
    HeyNekoPhase.thinking => activity.spokenText ?? '…',
    HeyNekoPhase.responding => activity.response ?? '…',
    HeyNekoPhase.idle => 'purr~',
  };
}
