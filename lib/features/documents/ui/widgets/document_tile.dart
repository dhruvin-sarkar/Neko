import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../models/cat_document.dart';

/// A single document row: a type icon, name, type + date, and a delete action.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onDelete,
  });

  final CatDocument document;
  final VoidCallback onDelete;

  IconData get _icon {
    return switch (document.type) {
      'passport' => Icons.book_outlined,
      'vaccination' => Icons.vaccines_outlined,
      'microchip' => Icons.memory_outlined,
      'license' => Icons.badge_outlined,
      _ => Icons.description_outlined,
    };
  }

  String get _subtitle {
    final String typeLabel = DocumentTypes.label(document.type);
    final DateTime? date = document.uploadedAt;
    if (date == null) return typeLabel;
    return '$typeLabel · ${_formatDate(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.selectedFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(_subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[(date.month - 1).clamp(0, 11)];
    return '${date.day} $month ${date.year}';
  }
}
