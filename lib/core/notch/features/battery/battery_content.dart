import 'package:flutter/material.dart';

import '../../models/notch_activity.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// Battery status (compact only) — shown when charging or low.
class BatteryContent extends StatelessWidget {
  const BatteryContent({super.key, required this.activity});

  final BatteryActivity activity;

  @override
  Widget build(BuildContext context) {
    final Color color = activity.isCharging
        ? NotchStyle.green
        : (activity.percentage <= 15 ? NotchStyle.coral : NotchStyle.textPrimary);

    final String? secondary = activity.isCharging
        ? (activity.minutesUntilFull != null
              ? '${activity.minutesUntilFull}m until full'
              : 'Charging')
        : (activity.percentage <= 20 ? 'Battery low' : null);

    return NotchCompactRow(
      leading: Icon(
        activity.isCharging
            ? Icons.battery_charging_full_rounded
            : Icons.battery_full_rounded,
        size: 18,
        color: color,
      ),
      primary: '${activity.percentage}%',
      secondary: secondary,
    );
  }
}
