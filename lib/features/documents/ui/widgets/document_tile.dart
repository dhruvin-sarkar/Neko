import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../models/cat_document.dart';

/// A single document row: a type icon, name, type + date, and a delete action.
/// Tapping the row opens the document in the device's default viewer.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.onOpen,
    required this.onDelete,
  });

  final CatDocument document;
  final VoidCallback onOpen;
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
    final DateTime? date = document.savedAt;
    if (date == null) return typeLabel;
    return '$typeLabel · ${_formatDate(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onOpen,
      semanticLabel: 'Open ${document.name}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _DocThumb(document: document, icon: _icon),
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
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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

/// The leading thumbnail: a real image preview for image documents, otherwise
/// the document's semantic type icon (more informative than a generic file/PDF
/// glyph). Missing/unreadable files fall back to the icon via Image.file's
/// errorBuilder (no synchronous existsSync in build).
class _DocThumb extends StatelessWidget {
  const _DocThumb({required this.document, required this.icon});

  final CatDocument document;
  final IconData icon;

  bool get _isImage {
    final String p = document.path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.selectedFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary, size: 30),
    );
    if (_isImage && !kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(
          File(document.path),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          cacheWidth: 192,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    return fallback;
  }
}
