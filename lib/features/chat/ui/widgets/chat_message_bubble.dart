import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../models/chat_attachment.dart';
import '../../models/chat_message.dart';

/// A single chat bubble. User messages are coral pills on the right; the
/// assistant's replies are white cards on the left, matching the app's surfaces.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final Color bubbleColor = isUser ? AppColors.primary : AppColors.snowWhite;
    final Color textColor = isUser
        ? AppColors.textOnPrimary
        : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 6),
              bottomRight: Radius.circular(isUser ? 6 : 20),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Attachments(attachments: message.attachments),
                ),
              if (message.content.isNotEmpty)
                Semantics(
                  // Announce the assistant's reply to screen readers as it lands.
                  liveRegion: !isUser,
                  child: Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: textColor,
                      height: 1.35,
                    ),
                  ),
                )
              else if (message.isStreaming)
                _TypingDots(color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({required this.attachments});

  final List<ChatAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ChatAttachment a in attachments)
          _AttachmentThumb(attachment: a),
      ],
    );
  }
}

/// A single attachment thumbnail. Missing/unreadable files fall back to a file
/// icon via Image.file's errorBuilder (no synchronous existsSync in build), and
/// the tile carries a screen-reader label.
class _AttachmentThumb extends StatelessWidget {
  const _AttachmentThumb({required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final ChatAttachment a = attachment;
    final Widget fallback = Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(Icons.insert_drive_file_outlined, color: AppColors.graphite),
    );
    return Semantics(
      image: a.isImage,
      label: a.isImage ? 'Image attachment' : 'File attachment',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 120,
          height: 90,
          child: a.isImage && !kIsWeb
              ? Image.file(
                  File(a.path),
                  fit: BoxFit.cover,
                  cacheWidth: 360,
                  errorBuilder: (_, _, _) => fallback,
                )
              : fallback,
        ),
      ),
    );
  }
}

/// The animated "…" shown while the assistant's reply hasn't started arriving.
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the OS "reduce motion" setting: show static dots, not the pulse.
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_c.isAnimating) _c.stop();
      return SizedBox(
        height: 18,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(3, (i) {
              final double t = ((_c.value + i * 0.2) % 1.0);
              final double opacity =
                  0.3 + 0.7 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
