import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/neko_primary_button.dart';
import '../../models/cat_document.dart';

/// Metadata returned when the user confirms a document upload.
typedef DocumentMeta = ({String name, String type});

/// Asks the user to name a picked document and choose its type.
class UploadDocumentSheet extends StatefulWidget {
  const UploadDocumentSheet({super.key, required this.defaultName});

  final String defaultName;

  /// Shows the sheet and resolves to the chosen [DocumentMeta], or `null` if
  /// dismissed.
  static Future<DocumentMeta?> show(
    BuildContext context, {
    required String defaultName,
  }) {
    return showModalBottomSheet<DocumentMeta>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => UploadDocumentSheet(defaultName: defaultName),
    );
  }

  @override
  State<UploadDocumentSheet> createState() => _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends State<UploadDocumentSheet> {
  late final TextEditingController _nameController;
  final ValueNotifier<String?> _type = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text("What's this document?", style: AppTextStyles.headlineLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: AppTextStyles.bodyLarge,
            cursorColor: AppColors.primary,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 20),
          Text('Type', style: AppTextStyles.bodyLarge),
          const SizedBox(height: 12),
          ValueListenableBuilder<String?>(
            valueListenable: _type,
            builder: (context, selected, _) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final String type in DocumentTypes.all)
                    _TypeChip(
                      label: DocumentTypes.label(type),
                      selected: selected == type,
                      onTap: () => _type.value = type,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<String?>(
            valueListenable: _type,
            builder: (context, selected, _) {
              return NekoPrimaryButton(
                label: 'Save document',
                enabled: selected != null,
                onPressed: selected == null
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop((name: _nameController.text, type: selected)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.selectedFill : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? AppColors.selectedBorder : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
