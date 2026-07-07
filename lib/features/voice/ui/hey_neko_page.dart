import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/notch/model/notch_command.dart';
import '../../../core/notch/service/notch_theme_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/neko_button.dart';
import '../../settings/providers/theme_controller.dart';
import '../../../shared/services/search_service.dart';
import '../providers/hey_neko_controller.dart';
import '../providers/wake_word_controller.dart';

/// The dedicated "Hey Neko" experience, presented as the AI notch expanded into
/// a full takeover rather than a bright app page: a dark island panel — the
/// exact same [NotchThemeMapper] palette the physical notch uses — with cat ears
/// on its brow, the listening cat sliding up from the bottom while the mic is
/// open, and the Cat-Noir output cat looping while Neko answers.
class HeyNekoPage extends ConsumerStatefulWidget {
  const HeyNekoPage({super.key});

  static const String _listeningCat = 'assets/animations/Neko.ai.json';
  // The white-mode variant of Le Petit Chat "Cat Noir" — legible on the dark
  // pill where the black original would wash out.
  static const String _outputCat = 'assets/animations/noir cat whitemode.json';
  // The cat-in-a-box search animation, shown while searching the web + showing
  // the results.
  static const String _searchCat = 'assets/animations/Cat_in_Box.json';
  // The sleepy 404 cat, shown on any error / not-found state.
  static const String _errorCat = 'assets/animations/404 Sleep Cat.json';

  /// The Lottie cat for a given phase (null = no cat).
  static String? catFor(HeyNekoPhase phase) => switch (phase) {
    HeyNekoPhase.listening => _listeningCat,
    HeyNekoPhase.searching || HeyNekoPhase.results => _searchCat,
    HeyNekoPhase.thinking || HeyNekoPhase.speaking => _outputCat,
    HeyNekoPhase.error => _errorCat,
    HeyNekoPhase.idle => null,
  };

  @override
  ConsumerState<HeyNekoPage> createState() => _HeyNekoPageState();
}

class _HeyNekoPageState extends ConsumerState<HeyNekoPage> {
  late final HeyNekoController _voice = ref.read(
    heyNekoControllerProvider.notifier,
  );
  late final WakeWordController _wake = ref.read(
    wakeWordControllerProvider.notifier,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Await the wake loop fully releasing the mic before starting the
      // session: channel ordering guarantees the cancelled loop's stray
      // 'done'/'notListening' status is drained before the new session
      // re-points the shared recogniser callbacks — otherwise that stray
      // status lands mid-session and instantly fails it with "didn't catch
      // that" the moment tap-to-talk is opened with the wake word enabled.
      await _wake.pause();
      if (!mounted) return;
      _voice.start();
    });
  }

  @override
  void dispose() {
    _voice.cancel();
    _wake.resume();
    super.dispose();
  }

  void _close() {
    if (mounted) context.pop();
  }

  void _typeInstead() {
    if (!mounted) return;
    // `go` swaps the pushed page for the chat tab so the user can type instead.
    context.go(Routes.chat);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeControllerProvider);

    final NotchTheme t = NotchThemeMapper.fromPalette(AppColors.palette);
    final HeyNekoState state = ref.watch(heyNekoControllerProvider);
    final Color scrim = Color.lerp(t.background, Colors.black, 0.5)!;

    return Scaffold(
      backgroundColor: scrim,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: t.foreground.withValues(alpha: 0.7),
                  ),
                  onPressed: _close,
                  tooltip: 'Close',
                ),
              ),
              const Spacer(),
              _IslandPanel(theme: t, state: state),
              const SizedBox(height: 28),
              _Actions(
                theme: t,
                state: state,
                onSubmit: _voice.submit,
                onRetry: _voice.start,
                onClose: _close,
                onTypeInstead: _typeInstead,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark island card: ears on top, a status line, the reply/transcript text,
/// and the cat animation anchored at the bottom.
class _IslandPanel extends StatelessWidget {
  const _IslandPanel({required this.theme, required this.state});

  final NotchTheme theme;
  final HeyNekoState state;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final bool showResults =
        state.phase == HeyNekoPhase.results && state.results.isNotEmpty;
    final String? catAsset = HeyNekoPage.catFor(state.phase);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.foreground.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cross-fade the title between phases so the largest text on the
              // page doesn't hard-snap while everything beneath it eases.
              AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  _title(state.phase),
                  key: ValueKey<HeyNekoPhase>(state.phase),
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: theme.foreground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Ease the panel's height as the body swaps (text ↔ results ↔
              // status) instead of jumping.
              AnimatedSize(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 44,
                    maxHeight: 240,
                  ),
                  child: showResults
                      ? _ResultsList(theme: theme, results: state.results)
                      : state.phase == HeyNekoPhase.searching
                      // The results fetch is a real network round-trip, so its
                      // waiting moment gets a skeleton list (the app's shimmer),
                      // not a cat — then swaps to the real results when they land.
                      ? _ResultsSkeleton(theme: theme)
                      : SingleChildScrollView(
                          child: Text(
                            _body(state),
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: _bodyMuted(state)
                                  ? theme.subdued
                                  : theme.foreground,
                              height: 1.45,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              // The cat anchored at the bottom of the panel: the listening cat
              // slides up while capturing, the Cat-Noir output cat loops while
              // Neko answers, and the cat-in-a-box loops while searching the web
              // and showing results.
              SizedBox(
                height: 108,
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  switchInCurve: reduceMotion
                      ? Curves.linear
                      : Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: reduceMotion ? Offset.zero : const Offset(0, 0.6),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: catAsset == null
                      ? const SizedBox.shrink(key: ValueKey<String>('none'))
                      : Lottie.asset(
                          catAsset,
                          key: ValueKey<String>(catAsset),
                          repeat: !reduceMotion,
                          animate: !reduceMotion,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _title(HeyNekoPhase phase) => switch (phase) {
    HeyNekoPhase.idle => 'All done',
    HeyNekoPhase.listening => 'Listening…',
    HeyNekoPhase.thinking => 'Neko’s thinking…',
    HeyNekoPhase.searching => 'Searching the web…',
    HeyNekoPhase.speaking => 'Neko says',
    HeyNekoPhase.results => 'A few options',
    // State-descriptive like every other phase (not the bare product name).
    HeyNekoPhase.error => 'Neko missed that',
  };

  String _body(HeyNekoState state) => switch (state.phase) {
    HeyNekoPhase.error =>
      state.message ?? 'Something went wrong. Please try again.',
    HeyNekoPhase.speaking => state.reply,
    HeyNekoPhase.thinking => state.transcript,
    HeyNekoPhase.searching => state.transcript,
    HeyNekoPhase.listening =>
      state.transcript.isEmpty
          ? 'Say something — feeding, grooming, health, anything cat.'
          : state.transcript,
    HeyNekoPhase.results => '',
    // Keep the answer on screen during the brief auto-close beat rather than
    // flashing an empty "All done" card.
    HeyNekoPhase.idle => state.reply,
  };

  bool _bodyMuted(HeyNekoState state) =>
      state.phase == HeyNekoPhase.listening && state.transcript.isEmpty;
}

/// Skeleton placeholder cards shown while the web search is in flight, so the
/// results moment reads as "a list is loading" rather than "a cat is thinking".
/// Reuses the app's [Shimmer], tuned dark to sit calmly on the AI panel and
/// shaped like the real result cards so the swap doesn't jump.
class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton({required this.theme});

  final NotchTheme theme;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: theme.foreground.withValues(alpha: 0.06),
        highlightColor: theme.foreground.withValues(alpha: 0.16),
        period: const Duration(milliseconds: 1400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The tappable web results shown for a "results" voice query. Each opens in the
/// browser; the Cat-in-a-box search animation loops beneath.
class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.theme, required this.results});

  final NotchTheme theme;
  final List<SearchResult> results;

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on Object catch (e, st) {
      AppLogger.warning('Could not open search result', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final SearchResult r in results)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _open(r.url),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.foreground.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.foreground.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: theme.foreground,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (r.description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                r.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: theme.subdued,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: theme.accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.theme,
    required this.state,
    required this.onSubmit,
    required this.onRetry,
    required this.onClose,
    required this.onTypeInstead,
  });

  final NotchTheme theme;
  final HeyNekoState state;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;
  final VoidCallback onClose;
  final VoidCallback onTypeInstead;

  @override
  Widget build(BuildContext context) {
    // The exact app buttons (NekoButton chiclet) — same shape, press, and colour
    // language as the rest of Neko, no bespoke glow/gradient.
    switch (state.phase) {
      case HeyNekoPhase.listening:
        return NekoButton.primary(
          label: 'Done',
          icon: Icons.check_rounded,
          onPressed: onSubmit,
        );
      case HeyNekoPhase.thinking:
      case HeyNekoPhase.searching:
        return NekoButton.secondary(label: 'Cancel', onPressed: onClose);
      case HeyNekoPhase.speaking:
        // The answer is on screen to read — this is the deliberate finish.
        return NekoButton.primary(
          label: 'Done',
          icon: Icons.check_rounded,
          onPressed: onClose,
        );
      case HeyNekoPhase.results:
        return NekoButton.primary(
          label: 'Done',
          icon: Icons.check_rounded,
          onPressed: onClose,
        );
      case HeyNekoPhase.error:
        return Row(
          children: [
            Expanded(
              child: NekoButton.secondary(
                label: 'Type instead',
                onPressed: onTypeInstead,
              ),
            ),
            if (!state.micDenied) ...[
              const SizedBox(width: 12),
              Expanded(
                child: NekoButton.primary(
                  label: 'Try again',
                  icon: Icons.mic_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        );
      case HeyNekoPhase.idle:
        return NekoButton.primary(
          label: 'Done',
          icon: Icons.check_rounded,
          onPressed: onClose,
        );
    }
  }
}
