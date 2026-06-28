import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:zo_animated_border/zo_animated_border.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/neko_loader.dart';
import '../../models/chat_attachment.dart';

/// The composer at the bottom of the chat: an attachments tray, a growing
/// multi-line field, an attach button, and a Send / Stop toggle.
///
/// Re-skinned from the supplied multimodal input to use the app's theme tokens
/// (surfaces, borders, the coral accent) so it inherits the active colour theme
/// instead of the original hardcoded greys/black.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.attachments,
    required this.isGenerating,
    required this.isUploading,
    required this.onPickAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final List<ChatAttachment> attachments;
  final bool isGenerating;
  final bool isUploading;
  final VoidCallback onPickAttachment;
  final ValueChanged<ChatAttachment> onRemoveAttachment;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasContent =>
      widget.controller.text.trim().isNotEmpty || widget.attachments.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bool attachDisabled = widget.isGenerating || widget.isUploading;
    final bool sendDisabled =
        widget.isUploading || widget.isGenerating || !_hasContent;

    final Widget composer = Container(
      decoration: BoxDecoration(
        color: AppColors.snowWhite,
        border: widget.isGenerating
            ? null
            : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
        boxShadow: widget.isGenerating
            ? null
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.attachments.isNotEmpty || widget.isUploading)
            _AttachmentTray(
              attachments: widget.attachments,
              isUploading: widget.isUploading,
              onRemove: widget.onRemoveAttachment,
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 22),
                color: AppColors.graphite,
                onPressed: attachDisabled ? null : widget.onPickAttachment,
                visualDensity: VisualDensity.compact,
                tooltip: 'Add a photo',
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    controller: widget.controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.bodyLarge,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      hintText: 'Message Neko…',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) {
                      if (!sendDisabled) widget.onSend();
                    },
                  ),
                ),
              ),
              _ActionButton(
                isGenerating: widget.isGenerating,
                disabled: sendDisabled,
                onSend: widget.onSend,
                onStop: widget.onStop,
              ),
            ],
          ),
        ],
      ),
    );

    // While Neko is replying, a gentle coral gradient drifts around the
    // composer as a calm "thinking" cue. Otherwise it's a plain static surface.
    if (widget.isGenerating) {
      return ZoAnimatedGradientBorder(
        borderRadius: 24,
        borderThickness: 2,
        glowOpacity: 0.35,
        animationCurve: Curves.linear,
        animationDuration: const Duration(milliseconds: 2600),
        gradientColor: <Color>[
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.primary,
        ],
        child: composer,
      );
    }
    return composer;
  }
}

/// The Send (coral, up-arrow) / Stop (dark, square) toggle.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isGenerating,
    required this.disabled,
    required this.onSend,
    required this.onStop,
  });

  final bool isGenerating;
  final bool disabled;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.darkBanner,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.stop_rounded, size: 18, color: Colors.white),
          onPressed: onStop,
          visualDensity: VisualDensity.compact,
          tooltip: 'Stop',
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: disabled ? AppColors.cloudGray : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_upward_rounded,
          size: 18,
          color: Colors.white,
        ),
        onPressed: disabled ? null : onSend,
        visualDensity: VisualDensity.compact,
        tooltip: 'Send',
      ),
    );
  }
}

class _AttachmentTray extends StatelessWidget {
  const _AttachmentTray({
    required this.attachments,
    required this.isUploading,
    required this.onRemove,
  });

  final List<ChatAttachment> attachments;
  final bool isUploading;
  final ValueChanged<ChatAttachment> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final ChatAttachment a in attachments)
            _PreviewItem(attachment: a, onRemove: () => onRemove(a)),
          if (isUploading) const _PreviewItem(uploading: true),
        ],
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({this.attachment, this.uploading = false, this.onRemove});

  final ChatAttachment? attachment;
  final bool uploading;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ChatAttachment? a = attachment;
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: uploading
                ? const Center(child: NekoLoader.small())
                : (a != null &&
                          a.isImage &&
                          !kIsWeb &&
                          File(a.path).existsSync()
                      ? Image.file(File(a.path), fit: BoxFit.cover)
                      : Center(
                          child: Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.graphite,
                          ),
                        )),
          ),
          if (!uploading && onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.darkBanner,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.snowWhite, width: 1.5),
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
