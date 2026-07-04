import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, MethodChannel, rootBundle;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

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
    _hideIdleEmpty(animate: false);
    setState(() {
      _stack.removeWhere((NotchActivity a) => a.key == activity.key);
      _stack.add(activity);
      _shownIndex = _stack.length - 1;
      _cycleDir = 1;
    });
    _scheduleDismissIfTransient(activity);
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
  }

  void _remove({String? id, NotchActivityType? type}) {
    setState(() {
      _stack.removeWhere((NotchActivity a) {
        final bool byId = id != null && id.isNotEmpty && a.id == id;
        final bool byType = type != null && a.type == type;
        return byId || byType;
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


  void _setExpanded(bool value) {
    if (_primary == null || _expanded == value) return;
    setState(() => _expanded = value);
    if (value) {
      _applyWindow();
      _expand.forward();
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
    _applyWindow(force: true);
    _applyFlag();
    _expand.forward(from: 0);
  }

  void _hideIdleEmpty({bool animate = true}) {
    _idleEmptyTimer?.cancel();
    if (!_idleEmpty) return;
    setState(() => _idleEmpty = false);
    if (animate) {
      _expand.reverse();
    } else {
      _expand.value = 0;
      _applyWindow(force: true);
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


  void _applyWindow({bool force = false}) {
    final _Win target;
    if (_primary == null) {
      target = _idleEmpty || _expand.value > 0.001 ? _Win.compact : _Win.idle;
    } else if (_expanded || _expand.value > 0.001) {
      target = _Win.expanded;
    } else {
      target = _Win.compact;
    }

    final (int w, int h) = switch (target) {
      _Win.idle => (NotchMetrics.idleWidth, _idleH),
      _Win.compact => (NotchMetrics.activeWidth, _compactH),
      _Win.expanded => (NotchMetrics.activeWidth, _expandedH),
    };
    if (!force && w == _winW && h == _winH) return;
    _winW = w;
    _winH = h;
    unawaited(FlutterOverlayWindow.resizeOverlay(w, h, false));
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
    if (_expanded && _primary != null) {
      if (!_pawDrift.isAnimating) _pawDrift.repeat();
    } else if (_pawDrift.isAnimating) {
      _pawDrift.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mqTop = MediaQuery.paddingOf(context).top;
    _topInset = _theme.topInset > 0 ? _theme.topInset : (mqTop > 0 ? mqTop : 28);

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
    final double width = hasActivity
        ? NotchMetrics.activeWidth.toDouble()
        : NotchMetrics.idleWidth +
            (NotchMetrics.activeWidth - NotchMetrics.idleWidth) * emptyT;
    final double height = hasActivity
        ? (_compactH + (_expandedH - _compactH) * t)
        : _idleH + (_compactH - _idleH) * emptyT;
    final double radius = 14 + 18 * (hasActivity ? t : emptyT);

    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _theme.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
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
                          expandT: _expand.value,
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
              ? _IdleEmptyContent(theme: _theme, topInset: _topInset, opacity: emptyT)
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
            'Nothing to display',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.subdued,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(NotchActivityType type) {
  return switch (type) {
    NotchActivityType.music => Icons.music_note_rounded,
    NotchActivityType.notification => Icons.notifications_rounded,
    NotchActivityType.timer => Icons.timer_rounded,
    NotchActivityType.call => Icons.call_rounded,
    NotchActivityType.navigation => Icons.navigation_rounded,
    NotchActivityType.download => Icons.download_rounded,
    NotchActivityType.generic => Icons.pets_rounded,
  };
}

Uint8List? _decodeArt(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  if (identical(b64, _lastArtKey)) return _lastArtBytes;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
                  style: TextStyle(
                    color: theme.foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                if (activity.subtitle.isNotEmpty)
                  Text(
                    activity.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.subdued, fontSize: 10.5, height: 1.1),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (activity.type == NotchActivityType.music)
            _AudioWaves(color: theme.accent, active: activity.isPlaying)
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
    return Padding(
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
                        style: TextStyle(
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
                      style: TextStyle(
                        color: theme.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (activity.subtitle.isNotEmpty)
                      Text(
                        activity.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.subdued, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (isMusic) _AudioWaves(color: theme.accent, active: activity.isPlaying),
            ],
          ),
          if (activity.progress != null) ...<Widget>[
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
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(r)),
      child: Icon(_iconFor(activity.type), color: Colors.white, size: size * 0.55),
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

class _AudioWaves extends StatefulWidget {
  const _AudioWaves({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  State<_AudioWaves> createState() => _AudioWavesState();
}

class _AudioWavesState extends State<_AudioWaves> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AudioWaves old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.active && _c.isAnimating) {
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
      width: 26,
      height: 24,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(4, (int i) {
              final double phase = (_c.value + i * 0.22) % 1.0;
              final double t = widget.active ? 0.35 + 0.65 * (1 - (phase - 0.5).abs() * 2) : 0.4;
              return Container(
                width: 3.5,
                height: 22 * t,
                decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(2)),
              );
            }),
          );
        },
      ),
    );
  }
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
