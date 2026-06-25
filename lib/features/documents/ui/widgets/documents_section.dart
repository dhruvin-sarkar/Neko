import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../../../shared/services/file_picker_service.dart';
import '../../models/cat_document.dart';
import '../../providers/document_provider.dart';
import 'document_tile.dart';
import 'upload_document_sheet.dart';

/// The Documents block on a cat's profile: lists stored documents and lets the
/// user add new ones (pick a file → name it → choose a type → upload).
class DocumentsSection extends ConsumerWidget {
  const DocumentsSection({super.key, required this.catId});

  final String catId;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    final PickedFile? picked = await ref
        .read(filePickerServiceProvider)
        .pickDocument();
    if (picked == null || !context.mounted) return;

    final DocumentMeta? meta = await UploadDocumentSheet.show(
      context,
      defaultName: _stripExtension(picked.name),
    );
    if (meta == null || !context.mounted) return;

    await ref
        .read(documentActionControllerProvider.notifier)
        .upload(
          catId: catId,
          path: picked.path,
          name: meta.name,
          type: meta.type,
        );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    CatDocument doc,
  ) async {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    final Uri? uri = Uri.tryParse(doc.storageUrl);
    bool opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object catch (e, st) {
        AppLogger.warning('Could not open document', e, st);
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("We couldn't open that document.")),
        );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CatDocument document,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete document?', style: AppTextStyles.headlineLarge),
        content: Text(
          'Remove "${document.name}"? This can\'t be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(documentActionControllerProvider.notifier)
        .delete(catId: catId, document: document);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(documentActionControllerProvider, (
      previous,
      next,
    ) {
      if (next is AsyncError) {
        final Object error = next.error;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is AppException ? error.message : 'Something went wrong.',
              ),
            ),
          );
      }
    });

    final docsAsync = ref.watch(documentsProvider(catId));
    final bool isBusy = ref.watch(
      documentActionControllerProvider.select((s) => s.isLoading),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Documents', style: AppTextStyles.headlineLarge),
            if (isBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        docsAsync.when(
          loading: () => const _DocumentsLoading(),
          error: (_, _) => const _DocumentsMessage(
            text: "We couldn't load documents right now.",
          ),
          data: (docs) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (docs.isEmpty)
                const _DocumentsMessage(
                  text:
                      'No documents yet. Add vaccination cards, passports and more.',
                )
              else
                for (final CatDocument doc in docs) ...[
                  DocumentTile(
                    document: doc,
                    onOpen: () => _open(context, ref, doc),
                    onDelete: () => _confirmDelete(context, ref, doc),
                  ),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: isBusy ? null : () => _add(context, ref),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload a document'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _stripExtension(String fileName) {
    final int dot = fileName.lastIndexOf('.');
    return dot <= 0 ? fileName : fileName.substring(0, dot);
  }
}

class _DocumentsLoading extends StatelessWidget {
  const _DocumentsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

class _DocumentsMessage extends StatelessWidget {
  const _DocumentsMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
