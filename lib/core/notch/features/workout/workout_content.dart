import 'package:flutter/material.dart';

import '../../models/notch_activity.dart';
import '../../models/notch_state.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// Live workout content: compact shows type + duration/steps; expanded shows the
/// four key stats in a row.
class WorkoutContent extends StatelessWidget {
  const WorkoutContent({super.key, required this.activity, required this.mode});

  final WorkoutActivity activity;
  final NotchDisplayMode mode;

  String get _typeLabel => activity.type.isEmpty
      ? 'Workout'
      : '${activity.type[0].toUpperCase()}${activity.type.substring(1)}';

  @override
  Widget build(BuildContext context) {
    if (mode != NotchDisplayMode.expanded) {
      return NotchCompactRow(
        leading: const Icon(
          Icons.directions_run_rounded,
          size: 18,
          color: NotchStyle.coral,
        ),
        primary: _typeLabel,
        secondary: '${activity.durationLabel} · ${activity.steps} steps',
      );
    }

    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _stat(Icons.timer_outlined, activity.durationLabel, 'Time'),
          _stat(Icons.directions_walk_rounded, '${activity.steps}', 'Steps'),
          _stat(
            Icons.local_fire_department_outlined,
            activity.caloriesBurned.toStringAsFixed(0),
            'Cal',
          ),
          _stat(
            Icons.favorite_rounded,
            activity.heartRate != null ? '${activity.heartRate}' : '--',
            'BPM',
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 20, color: NotchStyle.coral),
        const SizedBox(height: 4),
        Text(value, style: NotchStyle.primaryLabel.copyWith(fontSize: 14)),
        Text(label, style: NotchStyle.secondaryLabel.copyWith(fontSize: 10)),
      ],
    );
  }
}
