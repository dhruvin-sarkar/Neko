import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/neko_motion.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/services/image_picker_service.dart';
import '../../../shared/widgets/neko_mascot.dart';
import '../../settings/providers/theme_controller.dart';
import '../models/chat_attachment.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../../safety/ui/safety_scan_sheet.dart';
import '../providers/chat_history_provider.dart';
import '../providers/chat_provider.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/suggested_prompts.dart';

/// The three ways to attach from the composer's attach menu.
enum _AttachChoice { gallery, camera, safety }

/// One-on-one conversation with the Neko AI assistant. A scrolling transcript
/// of bubbles with the composer pinned to the bottom; an empty state offers
/// starter prompts.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();
  List<ChatAttachment> _pending = <ChatAttachment>[];
  bool _uploading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: NekoMotion.entry,
        curve: NekoMotion.standardCurve,
      );
    });
  }

  void _send() {
    final String text = _controller.text;
    if (text.trim().isEmpty && _pending.isEmpty) return;
    unawaited(ref.read(feedbackServiceProvider).onAdvance());
    ref.read(chatControllerProvider.notifier).send(text, _pending);
    _controller.clear();
    setState(() => _pending = <ChatAttachment>[]);
    _scrollToBottom();
  }

  Future<void> _openAttachMenu() async {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    _focus.unfocus();
    final _AttachChoice? choice = await showModalBottomSheet<_AttachChoice>(
      context: context,
      backgroundColor: AppColors.snowWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AttachSheet(),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _AttachChoice.gallery:
        await _addPhoto(ImageSource.gallery);
      case _AttachChoice.camera:
        await _addPhoto(ImageSource.camera);
      case _AttachChoice.safety:
        _openSafetyScan();
    }
  }

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _uploading = true);
    final String? path = await ref
        .read(imagePickerServiceProvider)
        .pick(source);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (path != null) {
        final String name = path.split(RegExp(r'[\\/]')).last;
        _pending = <ChatAttachment>[
          ..._pending,
          ChatAttachment(path: path, name: name),
        ];
      }
    });
  }

  void _openSafetyScan() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.snowWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const SafetyScanSheet(),
    );
  }

  void _startVoice() {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    _focus.unfocus();
    // Open the dedicated AI-notch page (the voice session starts there).
    context.push(Routes.heyNeko);
  }

  void _selectPrompt(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focus.requestFocus();
  }

  void _openHistory() {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.snowWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild on theme change so this kept-alive tab re-skins when the palette
    // is switched from another tab.
    ref.watch(themeControllerProvider);
    // Auto-scroll as the transcript grows or the reply streams in.
    ref.listen(chatControllerProvider, (_, _) => _scrollToBottom());
    final ChatState state = ref.watch(chatControllerProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Neko Assistant',
                    style: AppTextStyles.displayLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Chat history',
                  icon: Icon(
                    Icons.history_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _openHistory,
                ),
                IconButton(
                  tooltip: 'New chat',
                  icon: Icon(Icons.edit_square, color: AppColors.textPrimary),
                  onPressed: () {
                    unawaited(ref.read(feedbackServiceProvider).onTap());
                    ref.read(chatControllerProvider.notifier).newChat();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: state.isEmpty
                ? _EmptyState(onSelect: _selectPrompt)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final ChatMessage m = state.messages[index];
                      final Widget bubble = ChatMessageBubble(message: m);
                      // Only the newest bubble gets the entrance — otherwise
                      // flutter_animate replays it every time an old bubble
                      // scrolls back into view (and churns a controller per row).
                      final bool isLast = index == state.messages.length - 1;
                      if (!isLast || MediaQuery.disableAnimationsOf(context)) {
                        return bubble;
                      }
                      return bubble
                          .animate()
                          .fadeIn(duration: NekoMotion.quick)
                          .slideY(begin: 0.12, end: 0, curve: NekoMotion.enter);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: ChatInput(
              controller: _controller,
              focusNode: _focus,
              attachments: _pending,
              isGenerating: state.isGenerating,
              isUploading: _uploading,
              onPickAttachment: _openAttachMenu,
              onRemoveAttachment: (a) => setState(
                () => _pending = _pending.where((e) => e != a).toList(),
              ),
              onSend: _send,
              onStop: () => ref.read(chatControllerProvider.notifier).stop(),
              onMic: _startVoice,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.pets_rounded, size: 48, color: AppColors.primary),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(child: NekoMascot(size: 96, fallback: fallback)),
          const SizedBox(height: 16),
          Text(
            'Ask Neko anything',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Your assistant for cat care, tips, and reminders.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          SuggestedPrompts(onSelect: onSelect),
        ],
      ).animate().fadeIn(duration: NekoMotion.entry).slideY(begin: 0.1, end: 0),
    );
  }
}

/// Bottom sheet listing saved conversations. Tapping one loads it as the active
/// chat; the trash icon removes it.
class _HistorySheet extends ConsumerWidget {
  const _HistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<ChatConversation> history = ref.watch(chatHistoryProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cloudGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('History', style: AppTextStyles.headlineLarge),
                  ),
                  if (history.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          ref.read(chatHistoryProvider.notifier).clearAll(),
                      child: Text(
                        'Clear all',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No past conversations yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final ChatConversation c = history[index];
                      return _HistoryTile(
                        conversation: c,
                        onTap: () {
                          ref.read(chatControllerProvider.notifier).load(c);
                          Navigator.of(context).pop();
                        },
                        onDelete: () =>
                            ref.read(chatHistoryProvider.notifier).remove(c.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open conversation: ${conversation.preview}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.selectedFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(conversation.updatedAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The attach menu: pick a photo, take one, or run a cat safety scan.
class _AttachSheet extends StatelessWidget {
  const _AttachSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cloudGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _AttachTile(
            icon: Icons.photo_library_outlined,
            label: 'Photo library',
            subtitle: 'Attach a saved photo',
            onTap: () => Navigator.of(context).pop(_AttachChoice.gallery),
          ),
          _AttachTile(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            subtitle: 'Snap something to attach',
            onTap: () => Navigator.of(context).pop(_AttachChoice.camera),
          ),
          _AttachTile(
            icon: Icons.health_and_safety_outlined,
            label: 'Cat safety scan',
            subtitle: 'Is this plant or food safe for your cat?',
            highlight: true,
            onTap: () => Navigator.of(context).pop(_AttachChoice.safety),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color tint = highlight ? AppColors.primary : AppColors.graphite;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlight ? AppColors.selectedFill : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: tint),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// A compact "time ago" label for the history list.
String _relativeTime(DateTime time) {
  final Duration d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
