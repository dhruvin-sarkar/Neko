import 'package:flutter/material.dart';

import '../../models/notch_activity.dart';
import '../../models/notch_state.dart';
import '../../widgets/notch_compact_row.dart';
import '../../widgets/notch_style.dart';

/// Music now-playing content. Compact = one line + play/pause; expanded adds
/// album tile, larger controls and a progress bar.
class MusicContent extends StatelessWidget {
  const MusicContent({super.key, required this.activity, required this.mode});

  final MusicActivity activity;
  final NotchDisplayMode mode;

  @override
  Widget build(BuildContext context) {
    return mode == NotchDisplayMode.expanded ? _expanded() : _compact();
  }

  Widget _compact() {
    return NotchCompactRow(
      leading: _art(20, iconSize: 12),
      primary: activity.songTitle,
      secondary: activity.artistName,
      trailing: Icon(
        activity.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        size: 18,
        color: NotchStyle.textPrimary,
      ),
    );
  }

  Widget _expanded() {
    return Padding(
      padding: NotchStyle.expandedPadding,
      child: Row(
        children: <Widget>[
          _art(48, iconSize: 22, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.songTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NotchStyle.primaryLabel.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NotchStyle.secondaryLabel.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: activity.progress.clamp(0.0, 1.0),
                    minHeight: 2,
                    backgroundColor: NotchStyle.track,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      NotchStyle.coral,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            activity.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 26,
            color: NotchStyle.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _art(double size, {required double iconSize, double radius = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: NotchStyle.coral.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_rounded,
        size: iconSize,
        color: NotchStyle.coral,
      ),
    );
  }
}
