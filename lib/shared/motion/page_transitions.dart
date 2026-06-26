import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

/// Page transition helpers used by the router's route definitions.
///
/// Every screen in the app sits on a single shared, translucent paw
/// background, so any horizontal "slide" makes two screens visibly overlap and
/// drift. These transitions deliberately avoid sideways motion: pages
/// **fade through** (the outgoing content fades out before the incoming content
/// fades in, with a whisper of scale), so over the shared background it reads
/// as one clean, premium cross-dissolve — never two screens at once.
abstract final class PageTransitions {
  const PageTransitions._();

  static const Duration _duration = Duration(milliseconds: 320);

  // ── Paw Curtain Transition (branded context-switch handoff) ──
  static const Duration _curtainDuration = Duration(milliseconds: 1100);

  /// Panel fill for the curtain — the brand background colour.
  static const Color _kCurtainColor = AppColors.primary;

  /// Tintable colour for the paw motif drawn on top of the panel.
  static const Color _kPawBrandColor = AppColors.snowWhite;

  // ── Blur Fade Transition (Profile ⇄ Home) ──
  static const Duration _blurDuration = Duration(milliseconds: 360);
  static const double _blurMaxSigma = 16.0;

  /// The default app transition: a clean fade-through. The outgoing page fades
  /// out early, then the incoming page fades in with a subtle scale-up — no
  /// sideways motion, so nothing is seen sliding away.
  static CustomTransitionPage<void> fadeThrough({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) {
          return FadeTransition(opacity: animation, child: child);
        }
        return FadeTransition(
          opacity: _exitFade(secondaryAnimation),
          child: FadeTransition(
            opacity: _enterFade(animation),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(begin: 0.97, end: 1.0).chain(
                  CurveTween(
                    curve: const Interval(0.30, 1.0, curve: Curves.easeOut),
                  ),
                ),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// A plain curved cross-fade (kept for any lightweight handoff).
  static CustomTransitionPage<void> fade({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: _exitFade(secondaryAnimation),
          child: FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  /// Branded curtain handoff: a solid panel sweeps diagonally to fully cover
  /// the screen at the midpoint (masking the page swap), a walking paw-print
  /// trail crosses it, then the panel retreats off the opposite corner to
  /// reveal the new page. The page being covered also fades out, so nothing
  /// shows beside the panel. Honors reduce-motion with a quick fade.
  static CustomTransitionPage<void> pawCurtain({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: _curtainDuration,
      reverseTransitionDuration: _curtainDuration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
            child: child,
          );
        }

        final Widget content = Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Incoming page: masked (opacity 0) until the panel fully covers
            // at the midpoint, then crisp on reveal.
            AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) => Opacity(
                opacity: _curtainContentOpacity(animation.value),
                child: child,
              ),
            ),
            // Full-screen curtain panel + paw trail, above both pages.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _PawCurtainPainter(
                    progress: animation,
                    panelColor: _kCurtainColor,
                    pawColor: _kPawBrandColor,
                  ),
                ),
              ),
            ),
          ],
        );

        // When another page pushes over this one, fade it out cleanly.
        return FadeTransition(opacity: _exitFade(secondaryAnimation), child: content);
      },
    );
  }

  /// A blur + cross-fade: the incoming page fades in while sharpening from a
  /// soft blur (and reverses on pop). Used for Profile ⇄ Home.
  static CustomTransitionPage<void> blurFade({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: _blurDuration,
      reverseTransitionDuration: _blurDuration,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) {
          return FadeTransition(opacity: animation, child: child);
        }
        final Animation<double> eased = animation.drive(
          CurveTween(curve: Curves.easeOut),
        );
        final Widget content = AnimatedBuilder(
          animation: eased,
          child: child,
          builder: (context, child) {
            final double v = eased.value.clamp(0.0, 1.0);
            final double sigma = (1.0 - v) * _blurMaxSigma;
            final Widget faded = Opacity(opacity: v, child: child);
            if (sigma < 0.05) return faded;
            return ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: faded,
            );
          },
        );
        return FadeTransition(opacity: _exitFade(secondaryAnimation), child: content);
      },
    );
  }

  /// Incoming opacity for the fade-through: invisible until 30%, then eases in.
  static Animation<double> _enterFade(Animation<double> animation) =>
      animation.drive(
        CurveTween(curve: const Interval(0.30, 1.0, curve: Curves.easeOut)),
      );

  /// Outgoing opacity driven by [secondaryAnimation]: fades out over the first
  /// 35% as a new page covers this one, so two screens never overlap.
  static Animation<double> _exitFade(Animation<double> secondaryAnimation) =>
      secondaryAnimation.drive(
        Tween<double>(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: const Interval(0.0, 0.35, curve: Curves.easeIn)),
        ),
      );
}

/// App-wide page transition for routes that don't use a [CustomTransitionPage]
/// (notably the [StatefulShellRoute] home shell). Matches the [fadeThrough]
/// feel — a clean fade with a whisper of scale-up — so reaching Home (e.g. from
/// the onboarding celebration) settles in gently instead of using the platform
/// default. Set via [ThemeData.pageTransitionsTheme].
class NekoPageTransitionsBuilder extends PageTransitionsBuilder {
  const NekoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final Animation<double> fade = animation.drive(
      CurveTween(curve: const Interval(0.15, 1.0, curve: Curves.easeOut)),
    );
    final Animation<double> scale = animation.drive(
      Tween<double>(
        begin: 0.98,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(scale: scale, child: child),
    );
  }
}

/// Wraps a tab branch so switching tabs plays a quick blur-in + fade: the new
/// branch appears softly blurred and sharpens into focus. Preserves each
/// branch's state (the child is the shell's IndexedStack).
class BlurBranchSwitcher extends StatefulWidget {
  const BlurBranchSwitcher({
    super.key,
    required this.index,
    required this.child,
  });

  /// The currently active branch index; a change triggers the blur-in.
  final int index;
  final Widget child;

  @override
  State<BlurBranchSwitcher> createState() => _BlurBranchSwitcherState();
}

class _BlurBranchSwitcherState extends State<BlurBranchSwitcher>
    with SingleTickerProviderStateMixin {
  static const double _maxSigma = 12.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void didUpdateWidget(BlurBranchSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    final Animation<double> eased = _controller.drive(
      CurveTween(curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: eased,
      child: widget.child,
      builder: (context, child) {
        final double v = eased.value.clamp(0.0, 1.0);
        final double sigma = (1.0 - v) * _maxSigma;
        final Widget content = Opacity(opacity: 0.5 + 0.5 * v, child: child);
        if (sigma < 0.05) return content;
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: content,
        );
      },
    );
  }
}

// ── Paw Curtain — pure helper functions ──

/// Triangular coverage fraction with a single peak at the midpoint.
double _curtainCoverage(double t) =>
    t <= 0.5 ? (t / 0.5) : (1.0 - (t - 0.5) / 0.5);

/// Panel alpha; reaches full opacity well before the midpoint.
double _curtainPanelOpacity(double t) => (t * 8).clamp(0.0, 1.0).toDouble();

/// Page-content alpha: fully masked (0.0) through the covering phase, then
/// snaps to fully opaque exactly at the midpoint — while the panel still
/// covers the screen, so the flip is invisible and the previous screen can
/// never show through the uncovered region.
double _curtainContentOpacity(double t) => t <= 0.5 ? 0.0 : 1.0;

/// Linear interpolation helper.
double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Centre of a paw print at fraction `t` along the diagonal, clamped to stay
/// `inset` away from each edge.
Offset _pawMotifOffset(double t, Size size, {double inset = 48}) {
  final double tc = t.clamp(0.0, 1.0).toDouble();
  final double maxX = math.max(inset, size.width - inset);
  final double maxY = math.max(inset, size.height - inset);
  final double minX = math.min(inset, maxX);
  final double minY = math.min(inset, maxY);
  final double x = _lerp(minX, maxX, tc).clamp(minX, maxX).toDouble();
  final double y = _lerp(minY, maxY, tc).clamp(minY, maxY).toDouble();
  return Offset(x, y);
}

// ── Diagonal half-plane panel geometry ──

/// Builds the panel path for progress `t`. Phase 1 (t ≤ 0.5) grows the covered
/// region from the start corner; Phase 2 (t > 0.5) grows the uncovered region
/// so the panel retreats off the opposite corner. `extent = w + h` makes
/// coverage exactly full-screen at t = 0.5.
Path _panelPath(Size size, double t) {
  final double extent = size.width + size.height;
  if (t <= 0.5) {
    final double front = extent * (t / 0.5);
    return _halfPlaneBelowDiagonal(size, front);
  }
  final double back = extent * ((t - 0.5) / 0.5);
  return _halfPlaneAboveDiagonal(size, back);
}

/// Covered region for Phase 1: where `x + y <= front`, clipped to the screen.
Path _halfPlaneBelowDiagonal(Size size, double front) {
  final List<Offset> clipped = _clipRectToHalfPlane(
    size,
    (Offset p) => p.dx + p.dy - front,
    keepNegative: true,
  );
  return _polygonPath(clipped);
}

/// Uncovered-complement region for Phase 2: where `x + y >= back`.
Path _halfPlaneAboveDiagonal(Size size, double back) {
  final List<Offset> clipped = _clipRectToHalfPlane(
    size,
    (Offset p) => p.dx + p.dy - back,
    keepNegative: false,
  );
  return _polygonPath(clipped);
}

/// Sutherland–Hodgman clip of the screen rectangle against a single half-plane.
List<Offset> _clipRectToHalfPlane(
  Size size,
  double Function(Offset) f, {
  required bool keepNegative,
}) {
  final List<Offset> rect = <Offset>[
    Offset.zero,
    Offset(size.width, 0),
    Offset(size.width, size.height),
    Offset(0, size.height),
  ];

  bool inside(double value) => keepNegative ? value <= 0 : value >= 0;

  final List<Offset> out = <Offset>[];
  for (int i = 0; i < rect.length; i++) {
    final Offset cur = rect[i];
    final Offset nxt = rect[(i + 1) % rect.length];
    final double fc = f(cur);
    final double fn = f(nxt);
    final bool curIn = inside(fc);
    final bool nxtIn = inside(fn);

    if (curIn) out.add(cur);
    if (curIn != nxtIn) {
      final double denom = fc - fn;
      final double tt = denom == 0 ? 0.0 : fc / denom;
      out.add(
        Offset(
          cur.dx + (nxt.dx - cur.dx) * tt,
          cur.dy + (nxt.dy - cur.dy) * tt,
        ),
      );
    }
  }
  return out;
}

/// Builds a closed [Path] from an ordered list of polygon vertices.
Path _polygonPath(List<Offset> points) {
  final Path path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }
  path.close();
  return path;
}

/// Tintable dog-paw motif: a rounded main pad plus four toe beans in an arc,
/// all one [Path] so it fills uniformly with a single colour.
Path _pawPath(Offset center, double scale) {
  final Path path = Path();

  path.addRRect(
    RRect.fromRectXY(
      Rect.fromCenter(
        center: center.translate(0, scale * 0.35),
        width: scale,
        height: scale * 0.9,
      ),
      scale * 0.45,
      scale * 0.45,
    ),
  );

  const List<Offset> toes = <Offset>[
    Offset(-0.45, -0.55),
    Offset(-0.15, -0.8),
    Offset(0.15, -0.8),
    Offset(0.45, -0.55),
  ];
  for (final Offset toe in toes) {
    path.addOval(
      Rect.fromCircle(
        center: center.translate(toe.dx * scale, toe.dy * scale),
        radius: scale * 0.18,
      ),
    );
  }

  return path;
}

/// Paints the diagonal colored panel and the walking paw-print trail, driven
/// by the route [progress] animation.
class _PawCurtainPainter extends CustomPainter {
  _PawCurtainPainter({
    required this.progress,
    required this.panelColor,
    required this.pawColor,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color panelColor;
  final Color pawColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;
    final double coverage = _curtainCoverage(t);
    if (coverage <= 0) return;

    final Paint panelPaint = Paint()
      ..color = panelColor.withValues(alpha: _curtainPanelOpacity(t));
    canvas.drawPath(_panelPath(size, t), panelPaint);

    _paintPawTrail(canvas, size, t);
  }

  /// Draws a sequence of paw prints stepping along the diagonal.
  void _paintPawTrail(Canvas canvas, Size size, double t) {
    const int count = 6;
    final double pawScale = size.shortestSide * 0.055;

    final double angle = math.atan2(size.height, size.width);
    final Offset normal = Offset(-math.sin(angle), math.cos(angle));
    final double sideStep = size.shortestSide * 0.05;

    final double trailFade = t <= 0.5
        ? 1.0
        : (1.0 - (t - 0.5) / 0.30).clamp(0.0, 1.0).toDouble();
    if (trailFade <= 0) return;

    for (int i = 0; i < count; i++) {
      final double f = (i + 0.5) / count;
      final double appearAt = _lerp(0.08, 0.46, f);
      final double a = ((t - appearAt) / 0.08).clamp(0.0, 1.0).toDouble();
      if (a <= 0) continue;

      final Offset base = _pawMotifOffset(f, size);
      final double side = i.isEven ? 1.0 : -1.0;
      final Offset center = base + normal * (sideStep * side);

      final Paint paint = Paint()
        ..color = pawColor.withValues(alpha: a * trailFade);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2 + side * 0.12);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(_pawPath(center, pawScale), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PawCurtainPainter old) =>
      old.progress.value != progress.value ||
      old.panelColor != panelColor ||
      old.pawColor != pawColor;
}

/// Plays the paw curtain as a full-screen overlay and navigates underneath it.
///
/// The curtain sweeps closed; at its midpoint — when the screen is fully
/// covered — [onCovered] is invoked so the caller can navigate (the swap is
/// hidden); then the curtain sweeps open to reveal the new screen. Use this to
/// get the branded curtain when moving into a destination that can't host a
/// [CustomTransitionPage] (e.g. finishing onboarding / adding a cat → the Home
/// shell).
///
/// Honors reduce-motion by skipping the overlay and navigating immediately.
Future<void> playPawCurtain(
  BuildContext context, {
  required VoidCallback onCovered,
}) {
  if (MediaQuery.of(context).disableAnimations) {
    onCovered();
    return Future<void>.value();
  }

  final OverlayState overlay = Overlay.of(context, rootOverlay: true);
  final Completer<void> done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _PawCurtainOverlay(
      onCovered: onCovered,
      onComplete: () {
        if (entry.mounted) entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

/// The animated overlay used by [playPawCurtain]: a self-running paw curtain
/// that fires [onCovered] at the midpoint and [onComplete] when it finishes.
class _PawCurtainOverlay extends StatefulWidget {
  const _PawCurtainOverlay({required this.onCovered, required this.onComplete});

  final VoidCallback onCovered;
  final VoidCallback onComplete;

  @override
  State<_PawCurtainOverlay> createState() => _PawCurtainOverlayState();
}

class _PawCurtainOverlayState extends State<_PawCurtainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PageTransitions._curtainDuration,
  );
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _controller
      ..addListener(_onTick)
      ..addStatusListener(_onStatus)
      ..forward();
  }

  void _onTick() {
    // Fire once the panel fully covers the screen (the midpoint).
    if (!_covered && _controller.value >= 0.5) {
      _covered = true;
      widget.onCovered();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _PawCurtainPainter(
            progress: _controller,
            panelColor: PageTransitions._kCurtainColor,
            pawColor: PageTransitions._kPawBrandColor,
          ),
        ),
      ),
    );
  }
}
