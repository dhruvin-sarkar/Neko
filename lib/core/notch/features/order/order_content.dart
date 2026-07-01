import 'package:flutter/material.dart';

import '../../models/notch_activity.dart';
import '../../models/notch_state.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// Food-delivery order tracking. Compact shows restaurant + status; expanded
/// adds a four-step progress strip.
class OrderContent extends StatelessWidget {
  const OrderContent({super.key, required this.activity, required this.mode});

  final OrderTrackingActivity activity;
  final NotchDisplayMode mode;

  static const List<String> _steps = <String>[
    'placed',
    'confirmed',
    'outForDelivery',
    'delivered',
  ];

  int get _currentStep {
    final int i = _steps.indexOf(
      activity.status == 'preparing' ? 'confirmed' : activity.status,
    );
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    if (mode != NotchDisplayMode.expanded) {
      return NotchCompactRow(
        leading: Text(activity.statusEmoji, style: const TextStyle(fontSize: 18)),
        primary: activity.restaurantName,
        secondary: activity.statusLabel,
      );
    }

    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${activity.statusEmoji}  ${activity.restaurantName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NotchStyle.primaryLabel.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (int i = 0; i < _steps.length; i++) ...<Widget>[
                _Dot(active: i <= _currentStep),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _currentStep
                          ? NotchStyle.coral
                          : NotchStyle.track,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(activity.statusLabel, style: NotchStyle.secondaryLabel),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        color: active ? NotchStyle.coral : NotchStyle.track,
        shape: BoxShape.circle,
      ),
    );
  }
}
