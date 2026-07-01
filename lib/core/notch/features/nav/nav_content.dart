import 'package:flutter/material.dart';

import '../../models/notch_activity.dart';
import '../../models/notch_state.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// Turn-by-turn navigation content: a direction arrow + instruction + ETA.
class NavContent extends StatelessWidget {
  const NavContent({super.key, required this.activity, required this.mode});

  final NavigationActivity activity;
  final NotchDisplayMode mode;

  static String _arrow(String direction) => switch (direction) {
    'north' => '↑',
    'northeast' => '↗',
    'east' => '→',
    'southeast' => '↘',
    'south' => '↓',
    'southwest' => '↙',
    'west' => '←',
    'northwest' => '↖',
    'uturn' => '↩',
    _ => '↑',
  };

  @override
  Widget build(BuildContext context) {
    final bool expanded = mode == NotchDisplayMode.expanded;
    final Widget arrow = Text(
      _arrow(activity.direction),
      style: TextStyle(
        fontSize: expanded ? 34 : 20,
        color: NotchStyle.coral,
        height: 1,
      ),
    );

    if (!expanded) {
      return NotchCompactRow(
        leading: arrow,
        primary: activity.instruction,
        secondary: activity.etaLabel,
      );
    }

    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Row(
        children: <Widget>[
          SizedBox(width: 44, child: Center(child: arrow)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NotchStyle.primaryLabel.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.distanceLabel} · ${activity.etaLabel}',
                  style: NotchStyle.secondaryLabel.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
