import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, MethodChannel, rootBundle;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/notch_activity.dart';
import '../../model/notch_command.dart';
import '../../notch_channels.dart';
import '../../service/notch_overlay_service.dart';
import '../notch_sfx.dart';

/// The Dynamic pill that lives in the overlay engine.

class NotchPill extends StatefulWidget {
  const NotchPill({super.key});

  @override
  State<NotchPill> createState() => _NotchPillState();
}

const Cubic _expandCurve = Cubic(0.22, 1.0, 0.36, 1.0);
const Duration _expandDuration = Duration(milliseconds: 460);

/// Transparent margin (dp) around the active pill, giving the accent lift-glow
/// room to render outside the pill body without being clipped by the window.
const int _glowPad = 18;

enum _Win { idle, compact, expanded }

class _NotchPillState extends State<NotchPill>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<NotchActivity> _stack = <NotchActivity>[];
  final Map<String, Timer> _dismissTimers = <String, Timer>{};
  final Map<String, Timer> _timerEnders = <String, Timer>{};
  StreamSubscription<dynamic>? _sub;

  /// 0 = compact, 1 = expanded. Drives both height and content cross-fade.
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: _expandDuration,
  )..addStatusListener(_onExpandStatus);

  late final AnimationController _pawDrift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  NotchTheme _theme = NotchTheme.fallback;
  double _topInset = 28;
  bool _expanded = false;
  bool _reduceMotion = false;
  bool _idleEmpty = false;
  Timer? _idleEmptyTimer;
  int _shownIndex = 0;
  int _cycleDir = 1;

  int _winW = NotchMetrics.idleWidth;
  int _winH = NotchMetrics.idleContent + 28;
  OverlayFlag _flag = OverlayFlag.defaultFlag;

  ui.Image? _pawImage;
  static const Duration _notificationTtl = Duration(seconds: 6);
  static const MethodChannel _mediaChannel = MethodChannel('neko/notch_media');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = FlutterOverlayWindow.overlayListener.listen(_onMessage);
    _loadPaw();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyWindow(force: true);
      _applyFlag();
    });
  }

  Future<void> _loadPaw() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/paw.png');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      if (mounted) setState(() => _pawImage = frame.image);
    } on Object {
      // ignore
    }
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyWindow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _idleEmptyTimer?.cancel();
    _expand.dispose();
    _pawDrift.dispose();
    for (final Timer t in _dismissTimers.values) {
      t.cancel();
    }
    for (final Timer t in _timerEnders.values) {
      t.cancel();
    }
    _pawImage?.dispose();
    super.dispose();
  }

  // ── Incoming commands ───────────────────────────────────────────────────────

  void _onMessage(Object? raw) {
    final NotchCommand? command = NotchCommand.tryParse(raw);
    if (command == null) return;
    switch (command) {
      case PushActivityCommand(:final NotchActivity activity):
        _push(activity);
      case UpdateActivityCommand(:final NotchActivity activity):
        _update(activity);
      case RemoveActivityCommand(:final String? id, :final NotchActivityType? type):
        _remove(id: id, type: type);
      case ClearCommand():
        _clearAll();
      case NotchThemeCommand(:final NotchTheme theme):
        setState(() => _theme = theme);
    }
  }

  void _push(NotchActivity activity) {
    // A countdown that already ran out (e.g. restored after a long reboot)
    // must not appear just to vanish.
    if (_isExpiredTimer(activity)) return;
    final bool wasQuiet = _stack.isEmpty;
    _hideIdleEmpty(animate: false);
    setState(() {
      _stack.removeWhere((NotchActivity a) => a.key == activity.key);
      _stack.add(activity);
      _shownIndex = _stack.length - 1;
      _cycleDir = 1;
    });
    _scheduleDismissIfTransient(activity);
    _scheduleTimerEnd(activity);
    // A soft chirp as the island wakes from nothing — Neko noticing.
    if (wasQuiet) unawaited(NotchSfx.chirp(scale: 0.6));
    _applyWindow();
    _applyFlag();
  }

  void _update(NotchActivity activity) {
    final int i = _stack.indexWhere((NotchActivity a) => a.key == activity.key);
    if (i == -1) {
      _push(activity);
      return;
    }
    setState(() => _stack[i] = _stack[i].mergedWith(activity));
    _scheduleTimerEnd(_stack[i]);
  }

  bool _isExpiredTimer(NotchActivity a) =>
      a.type == NotchActivityType.timer &&
      a.endsAtMs != null &&
      a.endsAtMs! <= DateTime.now().millisecondsSinceEpoch;

  /// Self-removes a countdown shortly after it reaches zero, so the island
  /// cleans up even if the app engine (which also schedules a removal) is dead.
  void _scheduleTimerEnd(NotchActivity a) {
    if (a.type != NotchActivityType.timer || a.endsAtMs == null) return;
    final Duration left = DateTime.fromMillisecondsSinceEpoch(
      a.endsAtMs!,
    ).difference(DateTime.now());
    _timerEnders[a.key]?.cancel();
    _timerEnders[a.key] = Timer(
      (left.isNegative ? Duration.zero : left) +
          const Duration(milliseconds: 1200),
      () {
        _timerEnders.remove(a.key);
        unawaited(NotchSfx.trill());
        _remove(id: a.id);
      },
    );
  }

  void _remove({String? id, NotchActivityType? type}) {
    setState(() {
      _stack.removeWhere((NotchActivity a) {
        final bool byId = id != null && id.isNotEmpty && a.id == id;
        final bool byType = type != null && a.type == type;
        final bool match = byId || byType;
        if (match) {
          // Cancel any pending end-of-countdown trill and auto-dismiss for this
          // activity — otherwise a cancelled timer still announces completion
          // (a happy trill) minutes later, and the Timer leaks until then.
          _timerEnders.remove(a.key)?.cancel();
          _dismissTimers.remove(a.key)?.cancel();
        }
        return match;
      });
      if (_stack.isEmpty) _expanded = false;
      if (_shownIndex >= _stack.length) {
        _shownIndex = _stack.isEmpty ? 0 : _stack.length - 1;
      }
    });
    if (!_expanded) _expand.value = 0;
    _applyWindow();
    _applyFlag();
    _updatePawDrift();
  }

  void _clearAll() {
    for (final Timer t in _dismissTimers.values) {
      t.cancel();
    }
    _dismissTimers.clear();
    _hideIdleEmpty(animate: false);
    setState(() {
      _stack.clear();
      _expanded = false;
      _shownIndex = 0;
    });
    _expand.value = 0;
    _applyWindow();
    _applyFlag();
    _updatePawDrift();
  }

  void _scheduleDismissIfTransient(NotchActivity activity) {
    if (activity.isOngoing) return;
    _dismissTimers[activity.key]?.cancel();
    _dismissTimers[activity.key] = Timer(_notificationTtl, () {
      _dismissTimers.remove(activity.key);
      _remove(id: activity.id);
    });
  }

  NotchActivity? get _primary {
    if (_stack.isEmpty) return null;
    return _stack[_shownIndex.clamp(0, _stack.length - 1)];
  }


  Future<void> _setExpanded(bool value) async {
    if (_primary == null || _expanded == value) return;
    setState(() => _expanded = value);
    if (value) {
      // A happy chirp as the island opens up.
      unawaited(NotchSfx.chirp());
      if (_reduceMotion) {
        _expand.value = 1;
        await _applyWindow();
      } else {
        // Grow the OS window BEFORE the pill draws larger, so the expanding
        // card isn't clipped by a still-compact surface for the first frames.
        await _applyWindow();
        if (!mounted || !_expanded) return;
        _expand.forward();
      }
    } else if (_reduceMotion) {
      _expand.value = 0;
    } else {
      _expand.reverse();
    }
    _updatePawDrift();
  }

  void _toggleExpanded() => _setExpanded(!_expanded);

  void _showIdleEmpty() {
    if (_primary != null || _idleEmpty) return;
    setState(() => _idleEmpty = true);
    _idleEmptyTimer?.cancel();
    _idleEmptyTimer = Timer(const Duration(seconds: 5), () => _hideIdleEmpty());
    unawaited(_applyWindow(force: true));
    _applyFlag();
    if (_reduceMotion) {
      _expand.value = 1;
    } else {
      _expand.forward(from: 0);
    }
  }

  void _hideIdleEmpty({bool animate = true}) {
    _idleEmptyTimer?.cancel();
    if (!_idleEmpty) return;
    setState(() => _idleEmpty = false);
    if (animate && !_reduceMotion) {
      _expand.reverse();
    } else {
      _expand.value = 0;
      unawaited(_applyWindow(force: true));
      _applyFlag();
    }
  }

  void _onTap() {
    if (_primary != null) {
      _toggleExpanded();
    } else if (_idleEmpty) {
      _hideIdleEmpty();
    } else {
      _showIdleEmpty();
    }
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final double v = d.primaryVelocity ?? 0;
    if (_primary != null) {
      if (v > 80) {
        _setExpanded(true);
      } else if (v < -80) {
        _setExpanded(false);
      }
      return;
    }
    if (v > 80) {
      _showIdleEmpty();
    } else if (v < -80) {
      _hideIdleEmpty();
    }
  }

  void _cycle(int dir) {
    if (_stack.length < 2) return;
    setState(() {
      _cycleDir = dir;
      _shownIndex = (_shownIndex + dir) % _stack.length;
      if (_shownIndex < 0) _shownIndex += _stack.length;
    });
  }

  void _sendControl(String action) async {
    try {
      await _mediaChannel.invokeMethod<void>('control', <String, dynamic>{'action': action});
    } on Object {
      unawaited(
        FlutterOverlayWindow.shareData(
          jsonEncode(<String, dynamic>{'cmd': NotchChannels.controlCommand, 'action': action}),
        ),
      );
    }
  }


  void _onExpandStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _applyWindow();
      _applyFlag();
    }
  }

  int get _idleH => NotchMetrics.idleContent + _topInset.round();
  int get _compactH => NotchMetrics.compactContent + _topInset.round();
  int get _expandedH => NotchMetrics.expandedContent + _topInset.round();


  Future<void> _applyWindow({bool force = false}) async {
    final _Win target;
    if (_primary == null) {
      target = _idleEmpty || _expand.value > 0.001 ? _Win.compact : _Win.idle;
    } else if (_expanded || _expand.value > 0.001) {
      target = _Win.expanded;
    } else {
      target = _Win.compact;
    }

    // A transparent margin around the ACTIVE pill so the accent lift-glow (the
    // Apple-style soft separation from arbitrary backdrops) has room to render
    // outside the pill body. Idle stays flush and minimal — no glow, no pad.
    const int glow = _glowPad;
    final (int w, int h) = switch (target) {
      _Win.idle => (NotchMetrics.idleWidth, _idleH),
      _Win.compact => (NotchMetrics.activeWidth + 2 * glow, _compactH + glow),
      _Win.expanded => (NotchMetrics.expandedWidth + 2 * glow, _expandedH + glow),
    };
    if (!force && w == _winW && h == _winH) return;
    _winW = w;
    _winH = h;
    await FlutterOverlayWindow.resizeOverlay(w, h, false);
  }

  void _applyFlag() {
    final bool interactive =
        _primary != null || _idleEmpty || _expand.value > 0.001;
    final OverlayFlag want =
        interactive ? OverlayFlag.defaultFlag : OverlayFlag.clickThrough;
    if (want == _flag) return;
    _flag = want;
    unawaited(FlutterOverlayWindow.updateFlag(want));
  }

  void _updatePawDrift() {
    // The infinite paw drift is exactly the kind of ambient motion reduce-motion
    // is meant to stop; hold it still when that's set.
    if (_expanded && _primary != null && !_reduceMotion) {
      if (!_pawDrift.isAnimating) _pawDrift.repeat();
    } else if (_pawDrift.isAnimating) {
      _pawDrift.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mqTop = MediaQuery.paddingOf(context).top;
    _topInset = _theme.topInset > 0 ? _theme.topInset : (mqTop > 0 ? mqTop : 28);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onVerticalDragEnd: _onVerticalDragEnd,
          onHorizontalDragEnd: (DragEndDetails d) {
            final double v = d.primaryVelocity ?? 0;
            if (v < -80) {
              _cycle(1);
            } else if (v > 80) {
              _cycle(-1);
            }
          },
          child: AnimatedBuilder(
            animation: _expand,
            builder: (BuildContext context, Widget? _) => _buildIsland(),
          ),
        ),
      ),
    );
  }

  Widget _buildIsland() {
    final bool hasActivity = _primary != null;
    final bool emptyExpanded = !hasActivity && (_idleEmpty || _expand.value > 0.001);
    final double t = _expandCurve.transform(_expand.value.clamp(0.0, 1.0));
    final double emptyT = emptyExpanded ? t : 0.0;
    // The island widens as it grows (Dynamic-Island style): the expanded window
    // is already wide, the visual pill animates across it.
    final double width = hasActivity
        ? NotchMetrics.activeWidth +
            (NotchMetrics.expandedWidth - NotchMetrics.activeWidth) * t
        : NotchMetrics.idleWidth +
            (NotchMetrics.activeWidth - NotchMetrics.idleWidth) * emptyT;
    final double height = hasActivity
        ? (_compactH + (_expandedH - _compactH) * t)
        : _idleH + (_compactH - _idleH) * emptyT;
    final double radius = 14 + 18 * (hasActivity ? t : emptyT);
    final bool assistantActive =
        _primary?.type == NotchActivityType.assistant;

    // Neko's ears perk up around the punch-hole whenever the island is awake —
    // subtle against the ink, warmer while Hey Neko is live.
    final Widget ears = Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: _topInset,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _CatEarsPainter(
              // Warm to the accent while Hey Neko is live; otherwise a clearly
              // readable light silhouette against the dark pill.
              color: assistantActive
                  ? _theme.accent
                  : _theme.foreground.withValues(alpha: 0.4),
              perk: 0.72 + 0.28 * (hasActivity ? t : emptyT),
            ),
          ),
        ),
      ),
    );

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _theme.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        // Soft accent lift so the pill separates from any backdrop (Apple's
        // Dynamic Island uses the same trick). Active states only; the window
        // is padded to give it room. The shadow above the pill clips into the
        // status bar, which is what we want — the glow reads below and beside.
        boxShadow: (hasActivity || emptyExpanded)
            ? <BoxShadow>[
                BoxShadow(
                  color: _theme.accent.withValues(
                    alpha: assistantActive ? 0.42 : 0.28,
                  ),
                  blurRadius: 20,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
      child: hasActivity
          ? Stack(
              children: <Widget>[
                if (_pawImage != null && _expand.value > 0.5)
                  Positioned.fill(
                    child: Opacity(
                      opacity: ((_expand.value - 0.5) * 2).clamp(0.0, 1.0),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _NotchPawPainter(_pawImage!, _theme.foreground, _pawDrift),
                        ),
                      ),
                    ),
                  ),
                ears,
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(top: _topInset),
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (Widget? current, List<Widget> previous) =>
                            Stack(alignment: Alignment.topCenter, children: <Widget>[
                          ...previous,
                          ?current,
                        ]),
                        transitionBuilder: (Widget child, Animation<double> a) {
                          final Animation<Offset> slide = Tween<Offset>(
                            begin: Offset(0.35 * _cycleDir, 0),
                            end: Offset.zero,
                          ).animate(a);
                          return FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: slide,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.92, end: 1).animate(a),
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _ActivityContent(
                          key: ValueKey<String>(_primary!.key),
                          activity: _primary!,
                          theme: _theme,
                          // The emphasized curve (not raw controller value) so
                          // the content cross-fade tracks the box it lives in.
                          expandT: t,
                          total: _stack.length,
                          index: _shownIndex.clamp(0, _stack.length - 1),
                          onControl: _sendControl,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : emptyExpanded
              ? Stack(
                  children: <Widget>[
                    ears,
                    _IdleEmptyContent(
                      theme: _theme,
                      topInset: _topInset,
                      opacity: emptyT,
                    ),
                  ],
                )
              : const SizedBox.shrink(),
    );
  }
}

class _IdleEmptyContent extends StatelessWidget {
  const _IdleEmptyContent({
    required this.theme,
    required this.topInset,
    required this.opacity,
  });

  final NotchTheme theme;
  final double topInset;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Padding(
        padding: EdgeInsets.only(top: topInset),
        child: Center(
          child: Text(
            'Neko’s napping 😴',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _nunito(color: theme.subdued, fontSize: 12.5),
          ),
        ),
      ),
    );
  }
}

/// The notch's text style — the app's Nunito, so the pill reads as the same
/// product as the rest of Neko rather than a bare system overlay. The main app
/// loads Nunito on launch, so the overlay engine picks it up from the shared
/// font cache (falling back gracefully to the system font if it isn't there).
TextStyle _nunito({
  required Color color,
  required double fontSize,
  FontWeight fontWeight = FontWeight.w500,
  double height = 1.1,
  double? letterSpacing,
  bool tabular = false,
}) {
  return GoogleFonts.nunito(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular
        ? const <ui.FontFeature>[ui.FontFeature.tabularFigures()]
        : null,
  );
}

IconData _iconFor(NotchActivityType type) {
  return switch (type) {
    NotchActivityType.music => Icons.music_note_rounded,
    NotchActivityType.notification => Icons.notifications_rounded,
    NotchActivityType.timer => Icons.timer_rounded,
    NotchActivityType.call => Icons.call_rounded,
    NotchActivityType.navigation => Icons.navigation_rounded,
    NotchActivityType.download => Icons.download_rounded,
    NotchActivityType.assistant => Icons.mic_rounded,
    NotchActivityType.generic => Icons.pets_rounded,
  };
}

/// A next-turn glyph inferred from the navigation notification's maneuver text
/// (Maps/Waze put "Turn left onto…", "Continue…", "Arrive" in the title), so a
/// nav activity shows the actual direction instead of a generic arrow.
IconData _maneuverIcon(String title) {
  final String t = title.toLowerCase();
  if (t.contains('u-turn') || t.contains('u turn')) {
    return Icons.u_turn_left_rounded;
  }
  if (t.contains('roundabout')) return Icons.roundabout_left_rounded;
  if (t.contains('slight left')) return Icons.turn_slight_left_rounded;
  if (t.contains('slight right')) return Icons.turn_slight_right_rounded;
  if (t.contains('left')) return Icons.turn_left_rounded;
  if (t.contains('right')) return Icons.turn_right_rounded;
  if (t.contains('merge')) return Icons.merge_rounded;
  if (t.contains('arrive') ||
      t.contains('destination') ||
      t.contains('arriving')) {
    return Icons.place_rounded;
  }
  if (t.contains('continue') ||
      t.contains('straight') ||
      t.contains('head ')) {
    return Icons.straight_rounded;
  }
  return Icons.navigation_rounded;
}

Uint8List? _decodeArt(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  // Compare by value, not identity: JSON decoding makes a fresh string each
  // media update, so identity never matched and the art was re-decoded every
  // time. Value equality lets the cache actually hold across position/state
  // updates for the same track.
  if (b64 == _lastArtKey) return _lastArtBytes;
  try {
    _lastArtBytes = base64Decode(b64);
    _lastArtKey = b64;
    return _lastArtBytes;
  } on FormatException {
    return null;
  }
}

String? _lastArtKey;
Uint8List? _lastArtBytes;

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    super.key,
    required this.activity,
    required this.theme,
    required this.expandT,
    required this.total,
    required this.index,
    required this.onControl,
  });

  final NotchActivity activity;
  final NotchTheme theme;
  final double expandT;
  final int total;
  final int index;
  final void Function(String action) onControl;

  @override
  Widget build(BuildContext context) {
    final double compactO = (1 - expandT / 0.55).clamp(0.0, 1.0);
    final double expandedO = ((expandT - 0.45) / 0.55).clamp(0.0, 1.0);
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        if (compactO > 0.01)
          Opacity(
            opacity: compactO,
            child: Transform.scale(
              scale: 0.94 + 0.06 * compactO,
              alignment: Alignment.topCenter,
              child: _Compact(activity: activity, theme: theme),
            ),
          ),
        if (expandedO > 0.01)
          Opacity(
            opacity: expandedO,
            child: Transform.scale(
              scale: 0.94 + 0.06 * expandedO,
              alignment: Alignment.topCenter,
              child: _Expanded(
                activity: activity,
                theme: theme,
                total: total,
                index: index,
                onControl: onControl,
              ),
            ),
          ),
      ],
    );
  }
}

/// leading artwork, title/subtitle, indicator
class _Compact extends StatelessWidget {
  const _Compact({required this.activity, required this.theme});

  final NotchActivity activity;
  final NotchTheme theme;

  @override
  Widget build(BuildContext context) {
    // Never-scroll wrapper: lets the content take its natural height and clip
    // cleanly instead of throwing a sub-pixel RenderFlex overflow at odd font
    // metrics.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Row(
        children: <Widget>[
          _Artwork(activity: activity, theme: theme, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.title.isEmpty ? 'Neko' : activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _nunito(
                    color: theme.foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (activity.type == NotchActivityType.timer &&
                    activity.endsAtMs != null)
                  _Countdown(
                    endsAtMs: activity.endsAtMs!,
                    style: _nunito(
                      color: theme.subdued,
                      fontSize: 10.5,
                      tabular: true,
                    ),
                  )
                else if (activity.subtitle.isNotEmpty)
                  Text(
                    activity.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _nunito(color: theme.subdued, fontSize: 10.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (activity.type == NotchActivityType.music ||
              activity.type == NotchActivityType.assistant)
            _EqualizerBars(color: theme.accent, active: activity.isPlaying)
          else if (activity.type == NotchActivityType.timer &&
              activity.endsAtMs != null &&
              activity.durationMs != null)
            _TimerRing(activity: activity, theme: theme)
          else if (activity.type == NotchActivityType.timer &&
              activity.endsAtMs != null)
            // A mirrored system timer has no known total; the countdown text
            // ticks, so show a static glyph rather than a frozen-full ring.
            Icon(Icons.timer_rounded, color: theme.accent, size: 18)
          else if (activity.type == NotchActivityType.navigation)
            Icon(_maneuverIcon(activity.title), color: theme.accent, size: 18)
          else if (activity.progress != null)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                value: activity.progress!.clamp(0.0, 1.0),
                strokeWidth: 3,
                backgroundColor: theme.foreground.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
              ),
            )
          else
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
            ),
        ],
      ),
      ),
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({
    required this.activity,
    required this.theme,
    required this.total,
    required this.index,
    required this.onControl,
  });

  final NotchActivity activity;
  final NotchTheme theme;
  final int total;
  final int index;
  final void Function(String action) onControl;

  @override
  Widget build(BuildContext context) {
    final bool isMusic = activity.type == NotchActivityType.music;
    final bool isAssistant = activity.type == NotchActivityType.assistant;
    final bool isTimer =
        activity.type == NotchActivityType.timer && activity.endsAtMs != null;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Artwork(activity: activity, theme: theme, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (activity.appName != null && activity.appName!.isNotEmpty)
                      Text(
                        activity.appName!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _nunito(
                          color: theme.subdued,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    Text(
                      activity.title.isEmpty ? 'Neko' : activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _nunito(
                        color: theme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (isTimer)
                      _Countdown(
                        endsAtMs: activity.endsAtMs!,
                        style: _nunito(
                          color: theme.foreground,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          tabular: true,
                        ),
                      )
                    else if (activity.subtitle.isNotEmpty)
                      Text(
                        activity.subtitle,
                        maxLines: isAssistant ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: _nunito(
                          color: theme.subdued,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                  ],
                ),
              ),
              if (isMusic || isAssistant)
                _EqualizerBars(color: theme.accent, active: activity.isPlaying),
            ],
          ),
          if (isTimer && activity.durationMs != null) ...<Widget>[
            const SizedBox(height: 9),
            _TimerBar(activity: activity, theme: theme),
          ] else if (activity.progress != null) ...<Widget>[
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: activity.progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: theme.foreground.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
              ),
            ),
          ],
          if (isMusic) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _ControlButton(
                  icon: Icons.skip_previous_rounded,
                  color: theme.foreground,
                  size: 24,
                  onTap: () => onControl('previous'),
                ),
                const SizedBox(width: 20),
                _ControlButton(
                  icon: activity.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: theme.foreground,
                  size: 30,
                  onTap: () => onControl(activity.isPlaying ? 'pause' : 'play'),
                ),
                const SizedBox(width: 20),
                _ControlButton(
                  icon: Icons.skip_next_rounded,
                  color: theme.foreground,
                  size: 24,
                  onTap: () => onControl('next'),
                ),
              ],
            ),
          ] else if (total > 1) ...<Widget>[
            const SizedBox(height: 8),
            Center(child: _PageDots(total: total, index: index, color: theme.foreground)),
          ],
        ],
      ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.activity, required this.theme, required this.size});

  final NotchActivity activity;
  final NotchTheme theme;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = _decodeArt(activity.albumArt);
    final double r = size * 0.28;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    final IconData glyph = activity.type == NotchActivityType.navigation
        ? _maneuverIcon(activity.title)
        : _iconFor(activity.type);
    // Contrast the glyph against the accent chip: a dark glyph on a light accent
    // (some coat palettes are pale), white on a dark one — so it never washes
    // out whichever of the twelve themes is active.
    final Color onAccent = theme.accent.computeLuminance() > 0.55
        ? const Color(0xFF15151A)
        : Colors.white;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(r)),
      child: Icon(glyph, color: onAccent, size: size * 0.55),
    );
  }
}

class _ControlButton extends StatefulWidget {
  const _ControlButton({required this.icon, required this.color, required this.size, required this.onTap});

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = 0.8),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.total, required this.index, required this.color});

  final int total;
  final int index;
  final Color color;

  static const double _dot = 6;
  static const double _gap = 7;
  static const double _active = 16;

  @override
  Widget build(BuildContext context) {
    final double width = total * _dot + (total - 1) * _gap;
    return SizedBox(
      width: width,
      height: _dot,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < total; i++)
            Positioned(
              left: i * (_dot + _gap),
              top: 0,
              child: Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: index * (_dot + _gap) - (_active - _dot) / 2,
            top: 0,
            child: Container(
              width: _active,
              height: _dot,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(_dot / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tidy three-bar audio equaliser — the Apple-Dynamic-Island-style indicator
/// for music and Hey Neko. Bars bounce while audio is live and settle to short
/// even bars when it isn't. Reduce-motion aware.
class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(_EqualizerBars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final bool play = widget.active && !_reduceMotion;
    if (play && !_c.isAnimating) {
      _c.repeat();
    } else if (!play && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) => CustomPaint(
          painter: _EqualizerPainter(
            color: widget.color,
            t: _c.value,
            active: widget.active && !_reduceMotion,
          ),
        ),
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  const _EqualizerPainter({
    required this.color,
    required this.t,
    required this.active,
  });

  final Color color;
  final double t;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const int bars = 3;
    const double barW = 3.4;
    final double gap = (size.width - bars * barW) / (bars - 1);
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    for (int i = 0; i < bars; i++) {
      final double phase = t * 2 * math.pi + i * 1.9;
      final double amp = active ? (0.5 + 0.5 * math.sin(phase)).abs() : 0.3;
      final double h = size.height * (0.26 + 0.64 * amp);
      final double x = i * (barW + gap);
      final double top = (size.height - h) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, barW, h),
          const Radius.circular(1.7),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter old) =>
      old.t != t || old.color != color || old.active != active;
}

/// Two little ears perked around the punch-hole camera — drawn in the island's
/// status-bar zone so the cutout itself reads as Neko's face.
class _CatEarsPainter extends CustomPainter {
  const _CatEarsPainter({required this.color, required this.perk});

  final Color color;

  /// 0..1 — how far the ears have perked up (grows with the island).
  final double perk;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < 8) return;
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Two upright triangular ears — the app's own cat-ear language
    // (`cat_eared_icon.dart`) — flanking the punch-hole so the cutout reads as
    // Neko's face. A clear gap in the middle leaves the camera untouched.
    final double cx = size.width / 2;
    final double baseY = size.height;
    final double earH = (size.height * 0.7 * perk).clamp(0.0, 17.0);
    const double earW = 15;
    const double halfGap = 11; // clearance for the camera on each side

    for (int side = 0; side < 2; side++) {
      final double dir = side == 0 ? -1 : 1;
      final double innerX = cx + dir * halfGap;
      final double outerX = cx + dir * (halfGap + earW);
      final double apexX = cx + dir * (halfGap + earW * 0.5);
      final Path ear = Path()
        ..moveTo(innerX, baseY)
        ..lineTo(apexX, baseY - earH)
        ..lineTo(outerX, baseY)
        ..close();
      canvas.drawPath(ear, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _CatEarsPainter old) =>
      old.color != color || old.perk != perk;
}

/// A self-ticking countdown label driven by the activity's absolute end time —
/// no per-second pushes from the app engine needed.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.endsAtMs, required this.style});

  final int endsAtMs;
  final TextStyle style;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(_Countdown old) {
    super.didUpdateWidget(old);
    if (old.endsAtMs != widget.endsAtMs) _arm();
  }

  void _arm() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_remaining() <= Duration.zero) _ticker?.cancel();
    });
  }

  Duration _remaining() {
    final Duration left = DateTime.fromMillisecondsSinceEpoch(
      widget.endsAtMs,
    ).difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Duration left = _remaining();
    final int h = left.inHours;
    final int m = left.inMinutes % 60;
    final int s = left.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    final String text = h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
    return Text(text, maxLines: 1, style: widget.style);
  }
}

/// Self-ticking draining ring for a countdown in the compact pill.
class _TimerRing extends StatefulWidget {
  const _TimerRing({required this.activity, required this.theme});

  final NotchActivity activity;
  final NotchTheme theme;

  @override
  State<_TimerRing> createState() => _TimerRingState();
}

class _TimerRingState extends State<_TimerRing> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        value: _remainingFraction(widget.activity),
        strokeWidth: 3,
        backgroundColor: widget.theme.foreground.withValues(alpha: 0.22),
        valueColor: AlwaysStoppedAnimation<Color>(widget.theme.accent),
      ),
    );
  }
}

/// Self-ticking draining bar for a countdown in the expanded card.
class _TimerBar extends StatefulWidget {
  const _TimerBar({required this.activity, required this.theme});

  final NotchActivity activity;
  final NotchTheme theme;

  @override
  State<_TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<_TimerBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: _remainingFraction(widget.activity),
        minHeight: 4,
        backgroundColor: widget.theme.foreground.withValues(alpha: 0.22),
        valueColor: AlwaysStoppedAnimation<Color>(widget.theme.accent),
      ),
    );
  }
}

/// Fraction of a countdown still left (1 → just started, 0 → done).
double _remainingFraction(NotchActivity activity) {
  final int? endsAt = activity.endsAtMs;
  final int? total = activity.durationMs;
  if (endsAt == null || total == null || total <= 0) return 1;
  final int left = endsAt - DateTime.now().millisecondsSinceEpoch;
  return (left / total).clamp(0.0, 1.0);
}

/// Tiles the paw artwork faintly and drifts it seamlessly (only while expanded).
class _NotchPawPainter extends CustomPainter {
  _NotchPawPainter(this.image, this.tint, this.progress) : super(repaint: progress);

  final ui.Image image;
  final Color tint;
  final Animation<double> progress;

  static const double _tile = 46;
  static const double _pawSize = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(tint.withValues(alpha: 0.10), BlendMode.srcIn);
    final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final double shift = progress.value * 2 * _tile;
    final int cols = (size.width / _tile).ceil() + 2;
    final int rows = (size.height / _tile).ceil() + 2;
    for (int r = -2; r <= rows; r++) {
      final double stagger = r.isEven ? 0 : _tile / 2;
      for (int c = -2; c <= cols; c++) {
        final Rect dst = Rect.fromCenter(
          center: Offset(c * _tile + stagger + shift, r * _tile + shift),
          width: _pawSize,
          height: _pawSize,
        );
        canvas.drawImageRect(image, src, dst, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NotchPawPainter old) => old.image != image || old.tint != tint;
}
