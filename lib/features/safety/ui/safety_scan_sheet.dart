import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/neko_button.dart';
import '../../../core/widgets/neko_loader.dart';
import '../../chat/providers/chat_provider.dart';
import '../models/safety_verdict.dart';
import '../providers/safety_scan_controller.dart';

/// The cat-safety scanner: point the camera at a plant, food, or household item
/// and Neko says whether it's safe for the cat — erring toward caution. Opens
/// the camera on show, then walks through analysing → a colour-coded verdict.
class SafetyScanSheet extends ConsumerStatefulWidget {
  const SafetyScanSheet({super.key});

  @override
  ConsumerState<SafetyScanSheet> createState() => _SafetyScanSheetState();
}

class _SafetyScanSheetState extends ConsumerState<SafetyScanSheet> {
  late final SafetyScanController _controller = ref.read(
    safetyScanControllerProvider.notifier,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.scan());
  }

  @override
  void dispose() {
    _controller.reset();
    super.dispose();
  }

  void _discuss(SafetyVerdict verdict) {
    ref
        .read(chatControllerProvider.notifier)
        .appendVoiceTurn(
          'Is this safe for my cat? (safety scan)',
          '${verdict.headline}. ${verdict.detail}',
        );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final SafetyScanState state = ref.watch(safetyScanControllerProvider);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
            const SizedBox(height: 20),
            _ScanHeader(state: state),
            const SizedBox(height: 20),
            _ScanBody(state: state),
            const SizedBox(height: 24),
            _ScanActions(
              state: state,
              onScanAgain: _controller.scan,
              onClose: () => Navigator.of(context).maybePop(),
              onDiscuss: _discuss,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHeader extends StatelessWidget {
  const _ScanHeader({required this.state});

  final SafetyScanState state;

  @override
  Widget build(BuildContext context) {
    final String title = switch (state.phase) {
      SafetyScanPhase.result =>
        state.verdict?.headline ?? 'Safety check',
      SafetyScanPhase.error => 'Safety check',
      _ => 'Cat safety scan',
    };
    return Row(
      children: [
        Icon(Icons.health_and_safety_rounded, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: AppTextStyles.headlineLarge)),
      ],
    );
  }
}

/// The photo preview + status / verdict text.
class _ScanBody extends StatelessWidget {
  const _ScanBody({required this.state});

  final SafetyScanState state;

  @override
  Widget build(BuildContext context) {
    final String? path = state.photoPath;

    final Widget preview = path == null
        ? const SizedBox.shrink()
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          );

    return switch (state.phase) {
      SafetyScanPhase.capturing => const _StatusBlock(
        text: 'Opening the camera…',
      ),
      SafetyScanPhase.analyzing => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          preview,
          const SizedBox(height: 16),
          const _StatusBlock(
            text: 'Neko’s checking if this is safe for your cat…',
            spinner: true,
          ),
        ],
      ),
      SafetyScanPhase.result => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          preview,
          const SizedBox(height: 16),
          if (state.verdict != null) _VerdictCard(verdict: state.verdict!),
        ],
      ),
      SafetyScanPhase.error => _StatusBlock(
        text: state.message ?? 'Something went wrong. Please try again.',
      ),
      SafetyScanPhase.idle => const SizedBox.shrink(),
    };
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({required this.text, this.spinner = false});

  final String text;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          if (spinner) ...[
            const NekoLoader.small(),
            const SizedBox(height: 14),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// The colour-coded verdict: a chip (safe / caution / danger) and explanation.
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});

  final SafetyVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (verdict.level) {
      SafetyLevel.safe => (AppColors.success, Icons.check_circle_rounded),
      SafetyLevel.caution => (AppColors.warning, Icons.warning_amber_rounded),
      SafetyLevel.danger => (AppColors.danger, Icons.dangerous_rounded),
      SafetyLevel.unknown => (AppColors.primary, Icons.help_outline_rounded),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                verdict.headline,
                style: AppTextStyles.titleMedium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verdict.detail,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanActions extends StatelessWidget {
  const _ScanActions({
    required this.state,
    required this.onScanAgain,
    required this.onClose,
    required this.onDiscuss,
  });

  final SafetyScanState state;
  final VoidCallback onScanAgain;
  final VoidCallback onClose;
  final void Function(SafetyVerdict verdict) onDiscuss;

  @override
  Widget build(BuildContext context) {
    // The exact app buttons — same chiclet as everywhere else in Neko.
    switch (state.phase) {
      case SafetyScanPhase.capturing:
      case SafetyScanPhase.analyzing:
        return NekoButton.secondary(label: 'Cancel', onPressed: onClose);
      case SafetyScanPhase.error:
        return Row(
          children: [
            Expanded(
              child: NekoButton.secondary(label: 'Close', onPressed: onClose),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NekoButton.primary(
                label: 'Try again',
                icon: Icons.camera_alt_rounded,
                onPressed: onScanAgain,
              ),
            ),
          ],
        );
      case SafetyScanPhase.result:
        final SafetyVerdict? verdict = state.verdict;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: NekoButton.secondary(
                    label: 'Scan again',
                    onPressed: onScanAgain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NekoButton.primary(
                    label: 'Done',
                    icon: Icons.check_rounded,
                    onPressed: onClose,
                  ),
                ),
              ],
            ),
            if (verdict != null)
              NekoButton.ghost(
                label: 'Discuss in chat',
                onPressed: () => onDiscuss(verdict),
              ),
          ],
        );
      case SafetyScanPhase.idle:
        return NekoButton.secondary(label: 'Close', onPressed: onClose);
    }
  }
}
