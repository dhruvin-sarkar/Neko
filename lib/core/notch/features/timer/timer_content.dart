import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/notch_activity.dart';
import '../../models/notch_state.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// Timer content with a live-ticking countdown and a progress arc. Ticks itself
/// every second so the display stays current without the controller pushing
/// per-second updates.
class TimerContent extends StatefulWidget {
  const TimerContent({super.key, required this.activity, required this.mode});

  final TimerActivity activity;
  final NotchDisplayMode mode;

  @override
  State<TimerContent> createState() => _TimerContentState();
}

class _TimerContentState extends State<TimerContent> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  static String _fmt(int total) {
    final int h = total ~/ 3600;
    final int m = (total % 3600) ~/ 60;
    final int s = total % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int left = widget.activity.secondsLeftAt(now);
    final double progress = widget.activity.progressAt(now);
    final bool urgent = left <= 10;
    final bool expanded = widget.mode == NotchDisplayMode.expanded;

    final double arcSize = expanded ? 56 : 28;
    final Widget arc = SizedBox(
      width: arcSize,
      height: arcSize,
      child: CustomPaint(painter: _ArcPainter(progress)),
    );

    final Widget countdown = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 250),
      style: TextStyle(
        fontSize: expanded ? 24 : 15,
        fontWeight: FontWeight.w700,
        color: urgent ? NotchStyle.red : NotchStyle.textPrimary,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
      child: Text(_fmt(left)),
    );

    if (!expanded) {
      return NotchCompactRow(
        leading: arc,
        primary: _fmt(left),
        secondary: widget.activity.label,
        trailing: null,
      );
    }

    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Row(
        children: <Widget>[
          arc,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                countdown,
                const SizedBox(height: 2),
                Text(
                  widget.activity.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NotchStyle.secondaryLabel.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 2;
    final Paint track = Paint()
      ..color = NotchStyle.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Paint fill = Paint()
      ..color = NotchStyle.coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const double start = -math.pi / 2; // 12 o'clock
    const double sweep = 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * progress.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
