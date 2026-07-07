import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, MethodChannel, rootBundle;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:lottie/lottie.dart';

import '../../../neko_motion.dart';
import '../../model/notch_activity.dart';
import '../../model/notch_command.dart';
import '../../notch_channels.dart';
import '../../service/notch_overlay_service.dart';

/// The Dynamic pill that lives in the overlay engine.

class NotchPill extends StatefulWidget {
  const NotchPill({super.key});

  @override
  State<NotchPill> createState() => _NotchPillState();
}

const Cubic _expandCurve = Cubic(0.22, 1.0, 0.36, 1.0);
const Duration _expandDuration = Duration(milliseconds: 460);

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

  /// 1 = present at the compact peek; 0 = the minimal idle pill. Drives the
  /// grow-in on arrival and the melt on recede so neither is a one-frame snap.
  /// Rests at 1 (steady compact) so every other state is unchanged.
  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  )..addStatusListener(_onPresenceStatus);

  /// A forward-only rubber-band settle fired when the card expands (0→1 once),
  /// giving the expanded content a subtle overshoot like iOS's Dynamic Island.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  NotchTheme _theme = NotchTheme.fallback;
  double _topInset = 28;
  bool _expanded = false;
  bool _reduceMotion = false;
  bool _idleEmpty = false;
  // An activity is present but has receded to the minimal pill after its brief
  // peek — tap to bring it back. Keeps the notch out of the way like Apple's
  // Dynamic Island rather than sitting expanded forever.
  bool _minimized = false;
  Timer? _idleEmptyTimer;
  Timer? _recedeTimer;
  static const Duration _peekDuration = Duration(seconds: 4);
  int _shownIndex = 0;
  int _cycleDir = 1;
  // While cycling an EXPANDED card between activity types, hold the box at the
  // taller of the two per-type heights for the cross-fade, so neither the
  // outgoing nor the incoming card is clipped.
  NotchActivityType? _cycleHoldType;
  Timer? _cycleHoldTimer;

  // Content-hugging compact width (Dynamic-Island style): the compact pill sizes
  // to its ACTUAL content, not a fixed 212dp. Measured deterministically with a
  // TextPainter (no layout round-trip → no flicker) and animated between values.
  double _fromCompactW = NotchMetrics.activeWidth.toDouble();
  double _toCompactW = NotchMetrics.activeWidth.toDouble();
  TextScaler _textScaler = TextScaler.noScaling;
  late final AnimationController _widthCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  )..addStatusListener(_onWidthStatus);

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
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
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
    _recedeTimer?.cancel();
    _cycleHoldTimer?.cancel();
    _expand.dispose();
    _pawDrift.dispose();
    _presence.dispose();
    _settle.dispose();
    _widthCtl.dispose();
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
      case RemoveActivityCommand(
        :final String? id,
        :final NotchActivityType? type,
      ):
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
      // A fresh activity peeks out (un-minimises), then recedes again.
      _minimized = false;
    });
    // Size the compact pill to this activity's content (snap; the arrival
    // grow-in below animates idle → this width).
    _syncCompactWidth(animate: false);
    _scheduleDismissIfTransient(activity);
    _scheduleTimerEnd(activity);
    _scheduleRecede();
    _applyFlag();
    if (activity.type == NotchActivityType.assistant) {
      // The AI (Hey Neko) activity is a takeover: present immediately and
      // auto-expand for the whole session — no peek, no auto-recede. (_setExpanded
      // cancels the recede timer scheduled above.)
      _presence.value = 1;
      unawaited(_setExpanded(true));
    } else if (wasQuiet && !_reduceMotion) {
      // Grow the pill in from the idle sliver instead of snapping to compact (the
      // most-seen notch transition). Writing .value = 0 (the lower bound)
      // synchronously reports a `dismissed` status; detach the listener across
      // this reset so it isn't mistaken for a completed recede (which would
      // instantly minimise the fresh arrival).
      _presence
        ..removeStatusListener(_onPresenceStatus)
        ..value = 0
        ..addStatusListener(_onPresenceStatus);
      unawaited(_growInFromIdle());
    } else {
      _presence.value = 1;
      unawaited(_applyWindow());
    }
  }

  /// Sizes the OS window to compact FIRST (so the growing pill isn't clipped by
  /// a still-idle surface), then grows the presence factor 0→1.
  Future<void> _growInFromIdle() async {
    await _applyWindow();
    if (!mounted || _primary == null || _minimized || _expanded) return;
    _presence.forward();
  }

  /// Once a recede has fully melted the pill to idle size, settle into the
  /// minimal state and only NOW shrink the OS window (the inverse of the
  /// grow-window-before-pill order used on arrival), so the compact-sized
  /// surface never clips the shrinking pill mid-melt.
  void _onPresenceStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_minimized && mounted) {
      setState(() => _minimized = true);
      unawaited(_applyWindow());
      _applyFlag();
      _updatePawDrift();
    }
  }

  /// Live activities that must stay readable for their whole lifetime — a map
  /// giving turn-by-turn directions, a running feeding timer, an active call —
  /// stay pinned and never auto-recede. Everything else that lingers (music,
  /// downloads) or is transient (notifications) peeks, then steps aside to the
  /// minimal pill so the island stays out of the way, Dynamic-Island style.
  static bool _staysPinned(NotchActivityType type) =>
      type == NotchActivityType.timer ||
      type == NotchActivityType.navigation ||
      type == NotchActivityType.call;

  /// After a fresh activity has peeked for a few seconds, recede it to the
  /// minimal pill — unless the user has expanded it, or it's a pinned live
  /// activity (see [_staysPinned]). Tapping the minimal pill brings it back.
  ///
  /// When the peeking activity is transient (music, a notification) but a pinned
  /// live activity is waiting underneath, the island promotes that one to the
  /// front instead of minimising to an empty pill — so a running map or timer
  /// stays on screen even as the music that arrived over it recedes.
  void _scheduleRecede() {
    _recedeTimer?.cancel();
    _recedeTimer = Timer(_peekDuration, () {
      final NotchActivity? primary = _primary;
      if (!mounted || _expanded || primary == null || _minimized) return;
      if (_staysPinned(primary.type)) return;
      final int pinnedIndex = _stack.indexWhere(
        (NotchActivity a) => _staysPinned(a.type),
      );
      if (pinnedIndex != -1) {
        setState(() {
          _shownIndex = pinnedIndex;
          _cycleDir = 1;
        });
        _syncCompactWidth(animate: true);
        _applyFlag();
        return;
      }
      _expand.value = 0;
      if (_reduceMotion) {
        setState(() => _minimized = true);
        unawaited(_applyWindow());
        _applyFlag();
        _updatePawDrift();
      } else {
        // Melt back to the minimal pill; _onPresenceStatus settles _minimized
        // and shrinks the OS window once the pill has fully receded.
        _presence.reverse();
      }
    });
  }

  void _unminimize() {
    _recedeTimer?.cancel();
    setState(() => _minimized = false);
    _applyFlag();
    if (_reduceMotion) {
      _presence.value = 1;
      unawaited(_applyWindow());
    } else {
      // Grow the pill back out of the minimal sliver (same path as arrival).
      unawaited(_growInFromIdle());
    }
    _scheduleRecede();
  }

  void _update(NotchActivity activity) {
    final int i = _stack.indexWhere((NotchActivity a) => a.key == activity.key);
    if (i == -1) {
      _push(activity);
      return;
    }
    setState(() => _stack[i] = _stack[i].mergedWith(activity));
    _scheduleTimerEnd(_stack[i]);
    // If the VISIBLE activity's content changed size (e.g. a new track title),
    // re-hug it — animated while at the compact peek, snapped while expanded.
    if (i == _shownIndex.clamp(0, _stack.length - 1)) {
      _syncCompactWidth(animate: !_expanded);
      // An expanded card whose content grew (the AI card gaining a results list,
      // a longer reply) needs the OS window resized to fit — otherwise the taller
      // card is clipped by a still-short surface.
      if (_expanded) unawaited(_applyWindow());
    }
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
        // A firm haptic marks the finish (the SFX chime was removed).
        _haptic('success');
        _remove(id: a.id);
      },
    );
  }

  void _remove({String? id, NotchActivityType? type}) {
    // Remember which activity is showing so it stays shown across the removal.
    // Clamping the index alone silently swaps the visible card when an EARLIER
    // stack entry is the one removed and the list shifts down — e.g. a pinned
    // timer being displaced by an unrelated transient that had promoted the
    // shown index off the end.
    final String? shownKey = _primary?.key;
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
      if (_stack.isEmpty) {
        _expanded = false;
        _minimized = false;
      }
      // Re-locate the shown activity by identity (it may have shifted), falling
      // back to the last card only if it was the one removed.
      final int found = shownKey == null
          ? -1
          : _stack.indexWhere((NotchActivity a) => a.key == shownKey);
      _shownIndex = found != -1
          ? found
          : (_stack.isEmpty ? 0 : _stack.length - 1);
    });
    if (_stack.isEmpty) {
      _recedeTimer?.cancel();
      _presence.value = 1;
    }
    _cycleHoldTimer?.cancel();
    _cycleHoldType = null;
    // A different activity may now be the shown one — hug its width, and re-arm
    // its recede. A removal can reveal a transient that had stepped aside for a
    // pinned activity (music promoted behind a feeding timer that just ended);
    // without this it would sit at the compact peek forever. _scheduleRecede's
    // callback no-ops for a pinned/expanded/minimized primary, so this only
    // melts a genuinely-transient reveal back to the minimal pill.
    if (_primary != null) {
      _syncCompactWidth(animate: false);
      _scheduleRecede();
    }
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
    _recedeTimer?.cancel();
    _cycleHoldTimer?.cancel();
    _hideIdleEmpty(animate: false);
    setState(() {
      _stack.clear();
      _expanded = false;
      _minimized = false;
      _shownIndex = 0;
      _cycleHoldType = null;
    });
    _expand.value = 0;
    _presence.value = 1;
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
    if (!value) {
      // Collapsing mid-cycle: drop any height hold so it can't strand the box
      // oversized.
      _cycleHoldTimer?.cancel();
      _cycleHoldType = null;
    }
    if (value) {
      // Don't recede while the user is looking at the expanded card.
      _recedeTimer?.cancel();
      // Snap fully present before expanding (a swipe-down could land mid-melt).
      _presence.value = 1;
      // A light tick + a gentle rubber-band settle on the expanded content.
      // Manual expands are silent, like Apple's Dynamic Island — the chirp is
      // reserved for Neko noticing something, not for the user's own taps.
      _haptic('selection');
      if (!_reduceMotion) _settle.forward(from: 0);
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
      _scheduleRecede();
    } else {
      _expand.reverse();
      // Collapsed back to the compact peek — start the recede countdown again.
      _scheduleRecede();
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
      if (_minimized) {
        // First tap on a receded activity brings it back to the compact peek.
        _unminimize();
      } else {
        _toggleExpanded();
      }
    } else if (_idleEmpty) {
      _hideIdleEmpty();
    } else {
      _showIdleEmpty();
    }
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final double v = d.primaryVelocity ?? 0;
    if (_primary != null) {
      if (_minimized && v > 80) {
        _unminimize();
        return;
      }
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

  Future<void> _cycle(int dir) async {
    if (_stack.length < 2) return;
    final NotchActivityType? from = _primary?.type;
    setState(() {
      _cycleDir = dir;
      _shownIndex = (_shownIndex + dir) % _stack.length;
      if (_shownIndex < 0) _shownIndex += _stack.length;
      // Hold the expanded box at max(old, new) height for the cross-fade.
      if (_expanded) _cycleHoldType = from;
    });
    _haptic('selection');
    // Hug the newly-shown activity's content width (animated when at the compact
    // peek; snapped when expanded — it applies on the next collapse).
    _syncCompactWidth(animate: !_expanded);
    if (_expanded) {
      // Grow the OS window to the held (max) height BEFORE the box settles, so a
      // short→tall cycle can't clip the incoming card (mirrors _setExpanded's
      // grow-window-before-pill order). resizeOverlay is a native round-trip.
      await _applyWindow();
      _cycleHoldTimer?.cancel();
      _cycleHoldTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() => _cycleHoldType = null);
        // Settle down to the new type's own height once the cross-fade is done.
        unawaited(_applyWindow());
      });
    }
  }

  void _sendControl(String action) async {
    _haptic('light');
    try {
      await _mediaChannel.invokeMethod<void>('control', <String, dynamic>{
        'action': action,
      });
    } on Object {
      unawaited(
        FlutterOverlayWindow.shareData(
          jsonEncode(<String, dynamic>{
            'cmd': NotchChannels.controlCommand,
            'action': action,
          }),
        ),
      );
    }
  }

  /// A short native haptic via the overlay bridge — Flutter's own
  /// `HapticFeedback` is a no-op in the overlay engine, so we round-trip through
  /// NotchBridge's Vibrator. Best-effort; a missing vibrator is silently fine.
  void _haptic(String type) async {
    try {
      await _mediaChannel.invokeMethod<void>('haptic', <String, dynamic>{
        'type': type,
      });
    } on Object {
      // No haptic is fine — the island must never break for a buzz.
    }
  }

  /// Long-press opens the shown activity's source app, if it carries a package
  /// id (system notifications / media do; Neko's own activities don't).
  void _launchShownApp() async {
    final String? pkg = _primary?.packageId;
    if (pkg == null || pkg.isEmpty) return;
    _haptic('selection');
    try {
      await _mediaChannel.invokeMethod<void>('launchApp', <String, dynamic>{
        'package': pkg,
      });
    } on Object {
      // App not launchable / channel not bound — nothing to do.
    }
  }

  /// Opens a web result's URL in the browser (from the AI results card), routed
  /// natively through NotchBridge so it works even when only the overlay is up.
  void _launchUrl(String url) async {
    if (url.isEmpty) return;
    _haptic('light');
    try {
      await _mediaChannel.invokeMethod<void>('launchUrl', <String, dynamic>{
        'url': url,
      });
    } on Object {
      // No browser / channel not bound — nothing to do.
    }
  }

  void _onExpandStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _applyWindow();
      _applyFlag();
    }
  }

  // ── Content-hugging compact width ───────────────────────────────────────────

  /// Measures the ideal compact width for [a] with a [TextPainter]
  /// (deterministic, no layout round-trip → no flicker), so the pill hugs its
  /// content like Apple's Dynamic Island instead of a fixed 212dp.
  double _measureCompactWidth(NotchActivity a) {
    const double hPad = 22; // horizontal padding (11 * 2)
    const double lead = 24 + 9; // artwork + gap
    final double trailing = 10 + _indicatorWidth(a); // gap + indicator

    final String title = a.title.isEmpty ? 'Neko' : a.title;
    double textW = _measureText(
      title,
      _nunito(
        color: _theme.foreground,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
    if (a.type == NotchActivityType.timer && a.endsAtMs != null) {
      final bool hasHours =
          a.endsAtMs! - DateTime.now().millisecondsSinceEpoch >= 3600000;
      textW = math.max(
        textW,
        _measureText(
          hasHours ? '0:00:00' : '00:00',
          _nunito(
            color: _theme.accent,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            tabular: true,
          ),
        ),
      );
    } else if (a.subtitle.isNotEmpty) {
      textW = math.max(
        textW,
        _measureText(
          a.subtitle,
          _nunito(color: _theme.subdued, fontSize: 10.5),
        ),
      );
    }

    // Never wider than the expanded card; never so short it looks stunted.
    final double maxW = math
        .min(300, NotchMetrics.expandedWidth - 8)
        .toDouble();
    return (hPad + lead + textW + 2 + trailing).clamp(150.0, maxW);
  }

  double _measureText(String text, TextStyle style) {
    final TextPainter tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: _textScaler,
    )..layout();
    final double w = tp.width;
    tp.dispose();
    return w;
  }

  /// The trailing indicator's width — mirrors the choice made in [_Compact].
  double _indicatorWidth(NotchActivity a) {
    if (a.type == NotchActivityType.music ||
        a.type == NotchActivityType.assistant) {
      return 20;
    }
    if (a.type == NotchActivityType.timer && a.endsAtMs != null) {
      return a.durationMs != null ? 20 : 18;
    }
    if (a.type == NotchActivityType.navigation) return 18;
    if (a.progress != null) return 20;
    if (a.type == NotchActivityType.call) return 14;
    return 9;
  }

  /// Re-measures the shown activity and retargets the compact width — either
  /// animating the change (grow the window first on a widen, shrink it after on
  /// a narrow) or snapping it (fresh arrival / reduce-motion).
  void _syncCompactWidth({required bool animate}) {
    final NotchActivity? a = _primary;
    if (a == null) return;
    final double target = _measureCompactWidth(a);
    if ((target - _toCompactW).abs() < 0.5) return; // no meaningful change
    if (!animate || _reduceMotion) {
      _fromCompactW = target;
      _toCompactW = target;
      _widthCtl.value = 1;
      return;
    }
    _fromCompactW = _compactW; // start from where we visually are now
    _toCompactW = target;
    if (target > _fromCompactW) {
      unawaited(_growWidthThenAnimate());
    } else {
      // Narrower: animate now; _onWidthStatus shrinks the window on completion.
      _widthCtl.forward(from: 0);
    }
  }

  /// Grows the OS window to the (larger) target width BEFORE animating the pill
  /// wider, so the growing pill is never clipped by a still-narrow surface.
  Future<void> _growWidthThenAnimate() async {
    await _applyWindow();
    if (!mounted) return;
    _widthCtl.forward(from: 0);
  }

  void _onWidthStatus(AnimationStatus status) {
    // Once a width change settles, shrink the OS window down to the (possibly
    // narrower) final compact width.
    if (status == AnimationStatus.completed && mounted) {
      unawaited(_applyWindow());
    }
  }

  int get _idleH => NotchMetrics.idleContent + _topInset.round();

  /// A receded activity sits a little taller than the empty idle sliver so it's
  /// a real tap/drag target to bring the activity back (and its accent underline
  /// is easier to see).
  // The minimized pill IS its own tap window (flutter_overlay_window sizes the
  // OS surface to it). idleContent + 10 left only ~43dp — right at the edge of
  // reliable touch for reactivation. +24 gives a ~57dp window that clears the
  // 48dp target comfortably; the pill only grows a little and stays unobtrusive.
  int get _minimizedH => NotchMetrics.idleContent + 24 + _topInset.round();
  int get _compactH => NotchMetrics.compactContent + _topInset.round();

  /// The animated shown compact width (content-hugging). Rests at [_toCompactW].
  double get _compactW {
    // The one notch expand curve, shared with the expand + presence transitions
    // so every size change reads as the same motion.
    final double wt = _expandCurve.transform(_widthCtl.value.clamp(0.0, 1.0));
    return ui.lerpDouble(_fromCompactW, _toCompactW, wt) ?? _toCompactW;
  }

  /// The OS window width for the compact state: the larger of the two endpoints
  /// while a width change is animating (so the pill is never clipped by a
  /// too-narrow surface), then the settled target.
  int get _compactWindowW {
    final double w = _widthCtl.isAnimating
        ? math.max(_fromCompactW, _toCompactW)
        : _toCompactW;
    return w.ceil();
  }

  int get _expandedH {
    final NotchActivity? p = _primary;
    final int cur;
    if (p != null && p.type == NotchActivityType.assistant) {
      // The AI card is a cat animation + text (~78dp), plus a row per web result
      // shown (max 3).
      cur = 78 + p.results.length.clamp(0, 3) * 30;
    } else {
      cur = _expandedContentForType(p?.type);
    }
    final int held = _cycleHoldType != null
        ? _expandedContentForType(_cycleHoldType)
        : 0;
    return math.max(cur, held) + _topInset.round();
  }

  /// Non-music activities are far shorter than music (which carries a controls
  /// row), so one fixed 136dp expanded height left a large dead void under them.
  /// Size the card per type, each with clip-safe margin over its tallest variant.
  static int _expandedContentForType(NotchActivityType? type) {
    return switch (type) {
      NotchActivityType.navigation => 186, // header + the taller minimap panel
      NotchActivityType.music => NotchMetrics.expandedContent, // 136
      NotchActivityType.timer => 108,
      _ => 92,
    };
  }

  Future<void> _applyWindow({bool force = false}) async {
    final _Win target;
    if (_primary == null) {
      target = _idleEmpty || _expand.value > 0.001 ? _Win.compact : _Win.idle;
    } else if (_minimized && !_expanded && _expand.value < 0.001) {
      // Activity present but receded — sit as the minimal pill.
      target = _Win.idle;
    } else if (_expanded || _expand.value > 0.001) {
      target = _Win.expanded;
    } else {
      target = _Win.compact;
    }

    final (int w, int h) = switch (target) {
      _Win.idle => (
        NotchMetrics.idleWidth,
        _minimized && _primary != null ? _minimizedH : _idleH,
      ),
      _Win.compact => (_compactWindowW, _compactH),
      _Win.expanded => (NotchMetrics.expandedWidth, _expandedH),
    };
    if (!force && w == _winW && h == _winH) return;
    try {
      await FlutterOverlayWindow.resizeOverlay(w, h, false);
      _winW = w;
      _winH = h;
    } on Object {
      // At cold start the overlay method channel can lag a beat behind the Dart
      // UI (MissingPluginException). Leave the cache stale so the next geometry
      // change retries rather than skipping on the (w == _winW) guard.
    }
  }

  void _applyFlag() {
    final bool interactive =
        _primary != null || _idleEmpty || _expand.value > 0.001;
    final OverlayFlag want = interactive
        ? OverlayFlag.defaultFlag
        : OverlayFlag.clickThrough;
    if (want == _flag) return;
    // Only cache the flag once it actually lands; if the channel isn't ready
    // yet at cold start, leave _flag stale so the next _applyFlag retries.
    unawaited(
      FlutterOverlayWindow.updateFlag(want)
          .then<void>((_) {
            _flag = want;
          })
          .catchError((Object _) {}),
    );
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
    _topInset = _theme.topInset > 0
        ? _theme.topInset
        : (mqTop > 0 ? mqTop : 28);
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Capture the (clamped) text scaler so compact-width measurement matches
    // exactly how the text will render.
    _textScaler = MediaQuery.textScalerOf(context);

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onTap,
          onLongPress: _launchShownApp,
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
            animation: Listenable.merge(<Listenable>[
              _expand,
              _presence,
              _settle,
              _widthCtl,
            ]),
            builder: (BuildContext context, Widget? _) => _buildIsland(),
          ),
        ),
      ),
    );
  }

  Widget _buildIsland() {
    final bool hasActivity = _primary != null;
    // Activity present but receded to the minimal pill (its peek is over).
    final bool minimized =
        hasActivity && _minimized && !_expanded && _expand.value < 0.001;
    final bool emptyExpanded =
        !hasActivity && (_idleEmpty || _expand.value > 0.001);
    final double t = _expandCurve.transform(_expand.value.clamp(0.0, 1.0));
    final double emptyT = emptyExpanded ? t : 0.0;
    // Presence: 0 = idle-sized (arriving in / receding out), 1 = full compact
    // peek. Grows the pill in on arrival and melts it out on recede, so neither
    // transition is a one-frame geometry snap. Rests at 1 in steady compact.
    final double pT = _expandCurve.transform(_presence.value.clamp(0.0, 1.0));
    // A subtle rubber-band bump on the expanded content — peaks at ~+3% halfway
    // through the settle, back to 1.0. Rests at 1.0, so a no-op otherwise.
    final double settleScale =
        1 + 0.03 * math.sin(math.pi * _settle.value.clamp(0.0, 1.0));

    // The island widens/heightens as it grows (Dynamic-Island style): idle→
    // compact is driven by presence; compact→expanded by the expand curve.
    final double width;
    final double height;
    final double radius;
    if (minimized) {
      width = NotchMetrics.idleWidth.toDouble();
      height = _minimizedH.toDouble();
      radius = 14;
    } else if (hasActivity) {
      // idle → compact hugs the content width (_compactW); compact → expanded
      // widens to the full card.
      final double compactBaseW =
          NotchMetrics.idleWidth + (_compactW - NotchMetrics.idleWidth) * pT;
      width = compactBaseW + (NotchMetrics.expandedWidth - compactBaseW) * t;
      // idle/minimized → compact height by presence; compact → expanded by t.
      final double compactHh = _minimizedH + (_compactH - _minimizedH) * pT;
      height = compactHh + (_expandedH - compactHh) * t;
      radius = 14 + 18 * t;
    } else {
      width =
          NotchMetrics.idleWidth +
          (NotchMetrics.activeWidth - NotchMetrics.idleWidth) * emptyT;
      height = _idleH + (_compactH - _idleH) * emptyT;
      radius = 14 + 18 * emptyT;
    }
    // The compact content wants its full natural width even while the pill is
    // still growing in (or receding); pin it there and let the ClipRect crop the
    // overhang, so the compact Row never overflows its box mid-animation.
    final double contentW = math.max(width, _compactW);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _theme.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        // A receded pill wears a faint accent underline so it reads as a
        // living, tappable activity — not the empty click-through idle pill.
        border: minimized
            ? Border(
                bottom: BorderSide(
                  color: _theme.accent.withValues(alpha: 0.65),
                  width: 2,
                ),
              )
            : null,
      ),
      child: minimized
          ? const SizedBox.shrink()
          : hasActivity
          ? Transform.scale(
              alignment: Alignment.center,
              scale: settleScale,
              child: Stack(
                children: <Widget>[
                  if (_pawImage != null && _expand.value > 0.5)
                    Positioned.fill(
                      child: Opacity(
                        opacity: ((_expand.value - 0.5) * 2).clamp(0.0, 1.0),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _NotchPawPainter(
                              _pawImage!,
                              _theme.foreground,
                              _pawDrift,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(top: _topInset),
                      child: ClipRect(
                        // Lay the content out at its full width and let this
                        // ClipRect crop it while the pill grows in / recedes, so
                        // the compact Row never overflows the shrinking box.
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minWidth: contentW,
                          maxWidth: contentW,
                          child: AnimatedSwitcher(
                            duration: _reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder:
                                (Widget? current, List<Widget> previous) =>
                                    Stack(
                                      alignment: Alignment.topCenter,
                                      children: <Widget>[...previous, ?current],
                                    ),
                            transitionBuilder:
                                (Widget child, Animation<double> a) {
                                  final Animation<Offset> slide = Tween<Offset>(
                                    begin: Offset(0.35 * _cycleDir, 0),
                                    end: Offset.zero,
                                  ).animate(a);
                                  return FadeTransition(
                                    opacity: a,
                                    child: SlideTransition(
                                      position: slide,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.92,
                                          end: 1,
                                        ).animate(a),
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
                              onOpenUrl: _launchUrl,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : emptyExpanded
          ? _IdleEmptyContent(
              theme: _theme,
              topInset: _topInset,
              opacity: emptyT,
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
  // Bundled Nunito (same family the main app declares) so the overlay engine
  // renders it with no runtime fetch — a separate isolate can't rely on
  // google_fonts' cache being warm.
  return TextStyle(
    fontFamily: 'Nunito',
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: tabular
        ? const <ui.FontFeature>[ui.FontFeature.tabularFigures()]
        : null,
    // Nunito's intrinsic line box is tall (~1.35em); with our tight height:1.1
    // even leading centres each glyph in its box so text never rides high and
    // gets clipped by the fixed-height island containers.
    leadingDistribution: TextLeadingDistribution.even,
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
    NotchActivityType.assistant => Icons.auto_awesome_rounded,
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
  if (t.contains('continue') || t.contains('straight') || t.contains('head ')) {
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
    required this.onOpenUrl,
  });

  final NotchActivity activity;
  final NotchTheme theme;
  final double expandT;
  final int total;
  final int index;
  final void Function(String action) onControl;
  final void Function(String url) onOpenUrl;

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
                onOpenUrl: onOpenUrl,
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
                      // The ticking countdown is the most glanceable thing on the
                      // pill — make it the strongest element (accent + bold),
                      // tying it to the accent-coloured ring, not dim meta text.
                      style: _nunito(
                        color: theme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
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
            else if (activity.type == NotchActivityType.call)
              _PulsingDot(color: theme.accent)
            else
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: theme.accent,
                  shape: BoxShape.circle,
                ),
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
    required this.onOpenUrl,
  });

  final NotchActivity activity;
  final NotchTheme theme;
  final int total;
  final int index;
  final void Function(String action) onControl;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final bool isMusic = activity.type == NotchActivityType.music;
    // The Hey Neko assistant gets its own animated card (cat animation + text +
    // web results) rather than the generic artwork/title/subtitle layout.
    if (activity.type == NotchActivityType.assistant) {
      return _AssistantCard(
        activity: activity,
        theme: theme,
        onOpenUrl: onOpenUrl,
      );
    }
    // Navigation expands into a mini turn-by-turn panel: maneuver glyph,
    // instruction, and a stylised minimap.
    if (activity.type == NotchActivityType.navigation) {
      return _NavExpanded(
        activity: activity,
        theme: theme,
        total: total,
        index: index,
      );
    }
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
                      if (activity.appName != null &&
                          activity.appName!.isNotEmpty)
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
                          maxLines: 1,
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
                if (isMusic)
                  _EqualizerBars(
                    color: theme.accent,
                    active: activity.isPlaying,
                  ),
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
                  const SizedBox(width: 12),
                  _ControlButton(
                    icon: activity.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: theme.foreground,
                    size: 30,
                    onTap: () =>
                        onControl(activity.isPlaying ? 'pause' : 'play'),
                  ),
                  const SizedBox(width: 12),
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
              Center(
                child: _PageDots(
                  total: total,
                  index: index,
                  color: theme.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The expanded navigation card: maneuver glyph + instruction on top, a
/// stylised minimap below. Real map tiles can't render here — the overlay
/// window's engine doesn't composite platform views, and live tiles would need
/// location access plus a maps key inside this second engine — so the panel
/// draws a map-flavoured scene (street grid, accent route, position dot)
/// around the notification's real instruction text, which IS the live data
/// Maps/Waze publish.
class _NavExpanded extends StatelessWidget {
  const _NavExpanded({
    required this.activity,
    required this.theme,
    required this.total,
    required this.index,
  });

  final NotchActivity activity;
  final NotchTheme theme;
  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _maneuverIconFor('${activity.title} ${activity.subtitle}'),
                    color: theme.accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (activity.appName != null &&
                          activity.appName!.isNotEmpty)
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
                        activity.title.isEmpty ? 'Navigating' : activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _nunito(
                          color: theme.foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (activity.subtitle.isNotEmpty)
                        Text(
                          activity.subtitle,
                          maxLines: 1,
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
              ],
            ),
            const SizedBox(height: 9),
            Container(
              height: 92,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.foreground.withValues(alpha: 0.08),
                ),
              ),
              child: RepaintBoundary(
                child: CustomPaint(painter: _MiniMapPainter(theme: theme)),
              ),
            ),
            if (total > 1) ...<Widget>[
              const SizedBox(height: 8),
              Center(
                child: _PageDots(
                  total: total,
                  index: index,
                  color: theme.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Picks a maneuver glyph from the instruction text Maps/Waze publish. Purely
/// textual — nav apps don't expose a structured maneuver through their
/// notification — so unknown phrasings fall back to the generic arrow.
IconData _maneuverIconFor(String instruction) {
  final String t = instruction.toLowerCase();
  if (t.contains('u-turn') || t.contains('u turn')) {
    return Icons.u_turn_left_rounded;
  }
  if (t.contains('roundabout')) return Icons.roundabout_left_rounded;
  if (t.contains('merge')) return Icons.merge_rounded;
  if (t.contains('exit') || t.contains('ramp') || t.contains('fork')) {
    return Icons.fork_right_rounded;
  }
  if (t.contains('left')) return Icons.turn_left_rounded;
  if (t.contains('right')) return Icons.turn_right_rounded;
  if (t.contains('arriv') || t.contains('destination')) {
    return Icons.sports_score_rounded;
  }
  return Icons.navigation_rounded;
}

/// Paints the nav card's stylised minimap: an OPAQUE cool-slate map surface
/// (so the island's drifting paw pattern can't bleed through), a lit gradient
/// with an inner vignette for depth, a water body + park block, a two-tier
/// street grid, a glossy accent route (glow → core → white centreline) with a
/// rounded junction bend and heading chevrons, a teardrop destination pin and a
/// haloed position puck. A static scene — it repaints only on theme change, so
/// it costs nothing while directions tick.
class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter({required this.theme});

  final NotchTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // OPAQUE cool-slate map surface (mostly neutral, faintly tinted by the coat
    // theme) with a soft top-down gradient. Being opaque is the point: the old
    // translucent base let the island's drifting paw pattern bleed through and
    // clutter the map. A neutral map + a themed route reads like a real nav app.
    final Color top =
        Color.lerp(theme.background, const Color(0xFF222C3E), 0.92) ??
        const Color(0xFF222C3E);
    final Color bottom =
        Color.lerp(theme.background, const Color(0xFF10151F), 0.92) ??
        const Color(0xFF10151F);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, <Color>[
          top,
          bottom,
        ]),
    );

    // A touch of geography so the grid isn't floating on nothing: a water body
    // tucked into the top-left, a park block in the bottom-right — both clear of
    // the route and markers.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -size.width * 0.06,
          -size.height * 0.12,
          size.width * 0.32,
          size.height * 0.5,
        ),
        Radius.circular(size.height * 0.26),
      ),
      Paint()..color = const Color(0xFF2E4A6E).withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.7,
          size.height * 0.58,
          size.width * 0.42,
          size.height * 0.6,
        ),
        Radius.circular(size.height * 0.12),
      ),
      Paint()..color = const Color(0xFF31513A).withValues(alpha: 0.5),
    );

    // Street grid, two tiers: brighter avenues, then thin cross-streets.
    final Paint avenue = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final Paint street = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final double fy in <double>[0.34, 0.7]) {
      final double y = size.height * fy;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), avenue);
    }
    for (final double fx in <double>[0.36, 0.74]) {
      final double x = size.width * fx;
      canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), avenue);
    }
    for (final double fy in <double>[0.18, 0.52, 0.86]) {
      final double y = size.height * fy;
      canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), street);
    }
    for (final double fx in <double>[0.18, 0.55, 0.9]) {
      final double x = size.width * fx;
      canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), street);
    }

    // Soft inner vignette for depth — darker toward the edges, lit at the
    // centre. Drawn under the route so the line and markers stay crisp on top.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          size.longestSide * 0.7,
          <Color>[
            const Color(0x00000000),
            Colors.black.withValues(alpha: 0.30),
          ],
          <double>[0.5, 1.0],
        ),
    );

    // The route: bottom-left origin, a rounded junction bend, then a sweep to
    // the top-right destination.
    final Offset start = Offset(size.width * 0.13, size.height * 0.82);
    final Offset bend = Offset(size.width * 0.46, size.height * 0.82);
    final Offset bend2 = Offset(size.width * 0.46, size.height * 0.30);
    final Offset dest = Offset(size.width * 0.9, size.height * 0.30);
    const double r = 13;
    final Path route = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(bend.dx - r, bend.dy)
      ..quadraticBezierTo(bend.dx, bend.dy, bend.dx, bend.dy - r)
      ..lineTo(bend2.dx, bend2.dy + r)
      ..quadraticBezierTo(bend2.dx, bend2.dy, bend2.dx + r, bend2.dy)
      ..lineTo(dest.dx, dest.dy);

    // Layered stroke: blurred glow casing → mid band → bright core → a thin
    // white centre highlight for a glossy nav-line finish.
    canvas.drawPath(
      route,
      Paint()
        ..color = theme.accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = theme.accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = theme.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Two white heading chevrons riding up the vertical leg.
    for (final double fy in <double>[0.46, 0.66]) {
      final double cy = size.height * fy;
      canvas.drawPath(
        Path()
          ..moveTo(bend2.dx - 3.5, cy + 3.5)
          ..lineTo(bend2.dx, cy)
          ..lineTo(bend2.dx + 3.5, cy + 3.5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Destination: a teardrop pin with a soft drop shadow and an accent dot.
    const double pinR = 5.5;
    final Offset head = Offset(dest.dx, dest.dy - pinR * 1.7);
    canvas.drawCircle(
      head.translate(0, 1.2),
      pinR + 0.5,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawPath(
      Path()
        ..moveTo(dest.dx, dest.dy)
        ..lineTo(head.dx - pinR * 0.72, head.dy)
        ..lineTo(head.dx + pinR * 0.72, head.dy)
        ..close(),
      Paint()..color = theme.foreground,
    );
    canvas.drawCircle(head, pinR, Paint()..color = theme.foreground);
    canvas.drawCircle(head, 2.2, Paint()..color = theme.accent);

    // Position puck at the origin: soft halo, white ring, accent core.
    canvas.drawCircle(
      start,
      10.5,
      Paint()..color = theme.accent.withValues(alpha: 0.26),
    );
    canvas.drawCircle(start, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(start, 4.4, Paint()..color = theme.accent);
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) =>
      oldDelegate.theme != theme;
}

/// Maps a Hey Neko phase to its Lottie cat animation. The island is always
/// dark, so the "noir" output cat uses its white-mode variant (matching the Hey
/// Neko page). Lottie renders on the Flutter canvas (pure Dart), so it works in
/// the overlay engine with no plugin.
String _assistantCatFor(String? phase) {
  return switch (phase) {
    'listening' => 'assets/animations/Neko.ai.json',
    'searching' || 'results' => 'assets/animations/Cat_in_Box.json',
    'error' => 'assets/animations/404 Sleep Cat.json',
    // thinking / speaking / anything else → the Cat-Noir output cat.
    _ => 'assets/animations/noir cat whitemode.json',
  };
}

/// The AI-notch card: a phase-driven cat animation beside the live transcript /
/// reply, plus a tappable list of web results once Neko has fetched some.
class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.activity,
    required this.theme,
    required this.onOpenUrl,
  });

  final NotchActivity activity;
  final NotchTheme theme;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final List<NotchResult> results = activity.results;
    final bool listening = activity.phase == 'listening';
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                // RepaintBoundary so each Lottie frame doesn't repaint the whole
                // island. The cat cross-fades between phases (listening →
                // searching → answering) instead of snapping in one frame.
                RepaintBoundary(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                    child: Lottie.asset(
                      _assistantCatFor(activity.phase),
                      key: ValueKey<String>(_assistantCatFor(activity.phase)),
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        activity.title.isEmpty ? 'Hey Neko' : activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _nunito(
                          color: theme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (activity.subtitle.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 3),
                        Text(
                          activity.subtitle,
                          maxLines: results.isEmpty ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: _nunito(
                            color: listening ? theme.foreground : theme.subdued,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (results.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              for (final NotchResult r in results.take(3))
                _AssistantResultRow(
                  result: r,
                  theme: theme,
                  onOpenUrl: onOpenUrl,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One tappable web-result row on the AI results card.
class _AssistantResultRow extends StatelessWidget {
  const _AssistantResultRow({
    required this.result,
    required this.theme,
    required this.onOpenUrl,
  });

  final NotchResult result;
  final NotchTheme theme;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpenUrl(result.url),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Icon(Icons.public_rounded, size: 15, color: theme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _nunito(color: theme.foreground, fontSize: 12),
              ),
            ),
            Icon(Icons.north_east_rounded, size: 13, color: theme.subdued),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.activity,
    required this.theme,
    required this.size,
  });

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
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }
    final IconData glyph = activity.type == NotchActivityType.navigation
        ? _maneuverIcon(activity.title)
        : _iconFor(activity.type);
    // Contrast the glyph against the accent chip: a dark glyph on a light accent
    // (some coat palettes are pale), white on a dark one — so it never washes
    // out whichever of the twelve themes is active.
    final Color onAccent = theme.accent.computeLuminance() > 0.18
        ? const Color(0xFF15151A)
        : Colors.white;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(r),
      ),
      child: Icon(glyph, color: onAccent, size: size * 0.55),
    );
  }
}

class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

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
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: NekoMotion.pressIn,
        curve: NekoMotion.standardCurve,
        // A full 48dp tap target (Material minimum) around the 24/30 glyph — the
        // Icon centres itself in the box, so the glyph size is unchanged.
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.total,
    required this.index,
    required this.color,
  });

  final int total;
  final int index;
  final Color color;

  static const double _dot = 6;
  static const double _gap = 7;
  static const double _active = 16;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
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
            duration: reduceMotion ? Duration.zero : NekoMotion.standard,
            curve: NekoMotion.enter,
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

/// A gently pulsing dot — the compact indicator for an incoming call. Gives a
/// call urgency without dead answer/decline buttons (the notch has no telephony
/// path). Reduce-motion aware: holds a static dot when animations are off.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
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
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          final double size = 8 + 3 * _c.value;
          return Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.55 + 0.45 * _c.value),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
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
    final String text = h > 0
        ? '$h:${two(m)}:${two(s)}'
        : '${two(m)}:${two(s)}';
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
  _NotchPawPainter(this.image, this.tint, this.progress)
    : super(repaint: progress);

  final ui.Image image;
  final Color tint;
  final Animation<double> progress;

  static const double _tile = 46;
  static const double _pawSize = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(
        tint.withValues(alpha: 0.10),
        BlendMode.srcIn,
      );
    final Rect src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
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
  bool shouldRepaint(covariant _NotchPawPainter old) =>
      old.image != image || old.tint != tint;
}
