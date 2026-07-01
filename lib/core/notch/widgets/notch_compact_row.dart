import 'package:flutter/material.dart';

import 'notch_style.dart';

/// The standard one-line compact layout: [leading] primary · secondary
/// [trailing]. Single line so it always fits the 36dp compact pill height.
class NotchCompactRow extends StatelessWidget {
  const NotchCompactRow({
    super.key,
    required this.leading,
    required this.primary,
    this.secondary,
    this.trailing,
  });

  final Widget leading;
  final String primary;
  final String? secondary;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NotchStyle.primaryLabel,
                  ),
                ),
                if (secondary != null) ...<Widget>[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      secondary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NotchStyle.secondaryLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
