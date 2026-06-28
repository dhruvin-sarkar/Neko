import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  static const Duration _curtainDuration = Duration(milliseconds: 900);

  /// Panel fill for the curtain — the brand background colour.
  static Color get _kCurtainColor => AppColors.primary;

  /// Tintable colour for the paw motif drawn on top of the panel.
  static const Color _kPawBrandColor = Color(0xFFFFFFFF);

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

  /// Branded curtain handoff: a solid panel sweeps in diagonally to fully cover
  /// the screen, optionally **holds** at full cover (so the incoming page can
  /// finish laying out its elements), then retreats off the opposite corner to
  /// reveal the now-ready page. A walking paw trail crosses during the sweep.
  ///
  /// [coverIn] is the progress at which the panel reaches full cover; [coverOut]
  /// is where it begins to open. The gap between them is the hold. With the
  /// defaults (both `0.5`) there's no hold. Honors reduce-motion with a fade.
  static CustomTransitionPage<void> pawCurtain({
    required LocalKey key,
    required Widget child,
    Duration? duration,
    double coverIn = 0.5,
    double coverOut = 0.5,
  }) {
    final Duration d = duration ?? _curtainDuration;
    unawaited(_ensurePawCurtainImage());
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: d,
      reverseTransitionDuration: d,
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
            // Incoming page: masked (opacity 0) until the panel fully covers,
            // then crisp — so it's revealed only once it's laid out behind the
            // panel.
            AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) => Opacity(
                opacity: _curtainContentOpacity(animation.value, coverIn),
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
                    coverIn: coverIn,
                    coverOut: coverOut,
                  ),
                ),
              ),
            ),
          ],
        );

        // When another page pushes over this one, fade it out cleanly.
        return FadeTransition(
          opacity: _exitFade(secondaryAnimation),
          child: content,
        );
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
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: faded,
            );
          },
        );
        return FadeTransition(
          opacity: _exitFade(secondaryAnimation),
          child: content,
        );
      },
    );
  }

  /// The cat-profile reveal: the profile arrives crisp (fade + gentle scale-up)
  /// while the avatar flies in via its Hero and Home recedes — blurred — behind
  /// it. Keeping the incoming page sharp lets the avatar land cleanly; the
  /// diffuse background is the screen being left (see [NekoPageTransitions
  /// Builder], which blurs the shell as it's covered).
  static CustomTransitionPage<void> profileReveal({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.of(context).disableAnimations) {
          return FadeTransition(opacity: animation, child: child);
        }
        // The page fades in early (0–55%) so it's already present when the
        // avatar Hero lands inside the header card — the avatar arrives into a
        // settled screen rather than onto bare background. A gentle scale-up
        // makes it read as the banner expanding open.
        final Animation<double> fade = animation.drive(
          CurveTween(curve: const Interval(0.0, 0.55, curve: Curves.easeOut)),
        );
        final Animation<double> scale = animation.drive(
          Tween<double>(
            begin: 0.94,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );
        return FadeTransition(
          opacity: _exitFade(secondaryAnimation),
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
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

/// Eases the wrapped content *back* as another route is pushed over it — fading
/// it out while softly blurring and shrinking it — so the screen recedes into
/// the background instead of staying visible beneath the incoming one.
///
/// It reads the enclosing route's [ModalRoute.secondaryAnimation] directly, so
/// it works for the Home shell (whose recede the theme's transitions builder
/// can't reliably drive through go_router's shell page). Wrap a screen's body
/// in this to get a clean, diffuse hand-off when pushing a detail route.
class RecedeOnCover extends StatelessWidget {
  const RecedeOnCover({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> anim =
        ModalRoute.of(context)?.secondaryAnimation ?? kAlwaysDismissedAnimation;
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (context, child) {
        final double s = anim.value.clamp(0.0, 1.0);
        if (s <= 0.001) return child!;
        // Recede over the first ~45% so the screen is gone well before the
        // incoming detail content fades in (no overlap, no abrupt removal).
        final double t = Curves.easeInOut.transform((s / 0.45).clamp(0.0, 1.0));
        final double sigma = t * 10.0;
        final Widget faded = Opacity(
          opacity: 1.0 - t,
          child: Transform.scale(scale: 1.0 - 0.04 * t, child: child),
        );
        if (sigma < 0.05) return faded;
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: sigma,
            sigmaY: sigma,
            tileMode: TileMode.decal,
          ),
          child: faded,
        );
      },
    );
  }
}

/// Wraps a tab branch so switching tabs plays a quick, clean cross-fade.
/// Preserves each branch's state (the child is the shell's IndexedStack).
class BlurBranchSwitcher extends StatefulWidget {
  const BlurBranchSwitcher({
    super.key,
    required this.index,
    required this.child,
  });

  /// The currently active branch index; a change triggers the fade-in.
  final int index;
  final Widget child;

  @override
  State<BlurBranchSwitcher> createState() => _BlurBranchSwitcherState();
}

class _BlurBranchSwitcherState extends State<BlurBranchSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
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
    return FadeTransition(
      opacity: _controller.drive(
        Tween<double>(
          begin: 0.55,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
      ),
      child: widget.child,
    );
  }
}

// ── Paw Curtain — pure helper functions ──

/// Visible coverage: full from the moment the panel reaches cover ([coverOut]),
/// then recedes to zero as it opens. Used to short-circuit painting once
/// nothing is covered.
double _curtainCoverage(double t, double coverOut) =>
    t <= coverOut ? 1.0 : (1.0 - (t - coverOut) / (1.0 - coverOut));

/// Page-content alpha: masked (0.0) while the panel sweeps in, then opaque from
/// [coverIn] on — so the page is revealed (and held) only once it's fully
/// covered, never while the previous screen could still peek through.
double _curtainContentOpacity(double t, double coverIn) =>
    t < coverIn ? 0.0 : 1.0;

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

/// Builds the panel path for progress `t`. Up to [coverIn] the covered region
/// grows diagonally from the start corner (going-in sweep); between [coverIn]
/// and [coverOut] it holds full-screen (so the new page can finish laying out);
/// after [coverOut] the panel retreats off the opposite corner to reveal it.
Path _panelPath(Size size, double t, double coverIn, double coverOut) {
  final double extent = size.width + size.height;
  if (t <= coverIn) {
    // Going-in: covered region grows diagonally to full cover.
    final double front = extent * (coverIn <= 0 ? 1.0 : t / coverIn);
    return _halfPlaneBelowDiagonal(size, front);
  }
  if (t <= coverOut) {
    // Hold: stay fully covered while the incoming page renders.
    return Path()..addRect(Offset.zero & size);
  }
  // Going-out: the uncovered region grows, so the panel retreats off the
  // opposite corner.
  final double back = extent * ((t - coverOut) / (1.0 - coverOut));
  return _halfPlaneAboveDiagonal(size, back);
}

/// Uncovered-complement region for the reveal: where `x + y >= back`.
Path _halfPlaneAboveDiagonal(Size size, double back) {
  final List<Offset> clipped = _clipRectToHalfPlane(
    size,
    (Offset p) => p.dx + p.dy - back,
    keepNegative: false,
  );
  return _polygonPath(clipped);
}

/// Covered region growing from the start corner (the diagonal going-in):
/// where `x + y <= front`, clipped to the screen.
Path _halfPlaneBelowDiagonal(Size size, double front) {
  final List<Offset> clipped = _clipRectToHalfPlane(
    size,
    (Offset p) => p.dx + p.dy - front,
    keepNegative: true,
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

/// The paw artwork, decoded once for the curtain trail so it matches the
/// background paw. Null until loaded; the trail falls back to a vector paw.
ui.Image? _pawCurtainImage;
Future<void>? _pawCurtainImageLoad;

Future<void> _ensurePawCurtainImage() {
  if (_pawCurtainImage != null) return Future<void>.value();
  return _pawCurtainImageLoad ??= () async {
    try {
      final data = await rootBundle.load('assets/images/paw.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      _pawCurtainImage = frame.image;
    } on Object {
      // Keep the vector fallback if the asset can't be decoded.
    }
  }();
}

/// Paints the diagonal colored panel and the walking paw-print trail, driven
/// by the route [progress] animation.
class _PawCurtainPainter extends CustomPainter {
  _PawCurtainPainter({
    required this.progress,
    required this.panelColor,
    required this.pawColor,
    this.coverIn = 0.5,
    this.coverOut = 0.5,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color panelColor;
  final Color pawColor;
  final double coverIn;
  final double coverOut;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;
    final double coverage = _curtainCoverage(t, coverOut);
    if (coverage <= 0) return;

    final Paint panelPaint = Paint()..color = panelColor;
    canvas.drawPath(_panelPath(size, t, coverIn, coverOut), panelPaint);

    _paintPawTrail(canvas, size, t);
  }

  /// Draws a sequence of paw prints stepping along the diagonal.
  void _paintPawTrail(Canvas canvas, Size size, double t) {
    const int count = 6;
    final double pawScale = size.shortestSide * 0.055;

    final double angle = math.atan2(size.height, size.width);
    final Offset normal = Offset(-math.sin(angle), math.cos(angle));
    final double sideStep = size.shortestSide * 0.05;

    final double trailFade = t <= coverIn
        ? 1.0
        : (1.0 - (t - coverIn) / 0.30).clamp(0.0, 1.0).toDouble();
    if (trailFade <= 0) return;

    for (int i = 0; i < count; i++) {
      final double f = (i + 0.5) / count;
      final double appearAt = _lerp(0.04, coverIn * 0.9, f);
      final double a = ((t - appearAt) / (coverIn * 0.35))
          .clamp(0.0, 1.0)
          .toDouble();
      if (a <= 0) continue;

      final Offset base = _pawMotifOffset(f, size);
      final double side = i.isEven ? 1.0 : -1.0;
      final Offset center = base + normal * (sideStep * side);

      final double alpha = a * trailFade;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2 + side * 0.12);
      final ui.Image? img = _pawCurtainImage;
      if (img != null) {
        // The same paw artwork as the background, tinted to the brand paw
        // colour — so one paw is used throughout the app.
        final double s = pawScale * 2.4;
        final Paint paint = Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(
            pawColor.withValues(alpha: alpha),
            BlendMode.srcIn,
          );
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          paint,
        );
      } else {
        canvas.drawPath(
          _pawPath(Offset.zero, pawScale),
          Paint()..color = pawColor.withValues(alpha: alpha),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PawCurtainPainter old) =>
      old.progress.value != progress.value ||
      old.panelColor != panelColor ||
      old.pawColor != pawColor ||
      old.coverIn != coverIn ||
      old.coverOut != coverOut;
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
/// Plays the branded paw curtain as a full-screen overlay around a hand-off.
/// The sequence is deliberate and gap-free:
///
///   1. the curtain sweeps **closed** (a diagonal panel with a walking paw
///      trail) until it fully covers the screen;
///   2. [onCovered] runs and the curtain **holds** at full cover until that
///      future completes — so the caller can change screens (sign out,
///      navigate) entirely hidden behind the cover;
///   3. the curtain sweeps **open** to reveal the now-current screen.
///
/// Because the reveal waits for [onCovered], the previous screen is never seen
/// during the open even when the swap is asynchronous (e.g. sign-out, where we
/// wait for auth to clear and the router to land on Welcome).
///
/// Honors reduce-motion by skipping the overlay and running [onCovered]
/// immediately.
///
/// When [instantCover] is true the cover appears full-screen from the first
/// frame (no diagonal sweep-in) — used for sign-out, where the screen being
/// left must never be visible. Otherwise the panel sweeps in diagonally.
Future<void> playPawCurtain(
  BuildContext context, {
  required FutureOr<void> Function() onCovered,
  bool instantCover = false,
}) async {
  if (MediaQuery.of(context).disableAnimations) {
    await onCovered();
    return;
  }
  unawaited(_ensurePawCurtainImage());

  final OverlayState overlay = Overlay.of(context, rootOverlay: true);
  final Completer<void> done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _PawCurtainOverlay(
      onCovered: onCovered,
      instantCover: instantCover,
      onComplete: () {
        if (entry.mounted) entry.remove();
        if (!done.isCompleted) done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

/// The animated overlay used by [playPawCurtain]: sweeps closed, awaits
/// [onCovered] while fully covering the screen, holds, then sweeps open and
/// fires [onComplete].
class _PawCurtainOverlay extends StatefulWidget {
  const _PawCurtainOverlay({
    required this.onCovered,
    required this.onComplete,
    this.instantCover = false,
  });

  final FutureOr<void> Function() onCovered;
  final VoidCallback onComplete;
  final bool instantCover;

  @override
  State<_PawCurtainOverlay> createState() => _PawCurtainOverlayState();
}

class _PawCurtainOverlayState extends State<_PawCurtainOverlay>
    with TickerProviderStateMixin {
  /// How long the fully-covered screen lingers before sweeping open.
  static const Duration _holdDuration = Duration(milliseconds: 420);

  late final AnimationController _close = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final CurvedAnimation _closeCurve = CurvedAnimation(
    parent: _close,
    curve: Curves.easeInOut,
  );
  late final CurvedAnimation _openCurve = CurvedAnimation(
    parent: _open,
    curve: Curves.easeInOutCubic,
  );

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _open.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
    _runSequence();
  }

  Future<void> _runSequence() async {
    if (_started) return;
    _started = true;

    // 1. Going-in: the panel sweeps in (or, for sign-out, covers instantly) and
    // the paw trail walks across — until the screen is fully covered.
    await _close.forward();
    if (!mounted) return;

    // 2. Hand off (navigate / sign out) while fully covered. Runs AFTER the
    // cover completes — never during initState/build — so the navigation
    // inside [onCovered] actually takes effect instead of being dropped.
    await _runHandoff();
    if (!mounted) return;

    // 3. Hold the full-screen cover for a beat so the swap settles cleanly.
    await Future<void>.delayed(_holdDuration);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 4. Going-out: sweep open to reveal the now-current screen.
    await _open.forward();
  }

  Future<void> _runHandoff() async {
    try {
      await widget.onCovered();
    } on Object {
      // Ignore — we still open to reveal whatever screen is now current.
    }
  }

  @override
  void dispose() {
    _closeCurve.dispose();
    _openCurve.dispose();
    _close.dispose();
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _OverlayCurtainPainter(
            close: _closeCurve,
            open: _openCurve,
            instantCover: widget.instantCover,
            panelColor: PageTransitions._kCurtainColor,
            pawColor: PageTransitions._kPawBrandColor,
          ),
        ),
      ),
    );
  }
}

/// Paints the overlay curtain: the panel sweeps in diagonally (or covers the
/// whole screen instantly when [instantCover] is set), holds full-screen with a
/// walking paw trail, then sweeps open — retreating off the far corner — to
/// reveal the new screen.
class _OverlayCurtainPainter extends CustomPainter {
  _OverlayCurtainPainter({
    required this.close,
    required this.open,
    required this.panelColor,
    required this.pawColor,
    this.instantCover = false,
  }) : super(repaint: Listenable.merge(<Listenable>[close, open]));

  final Animation<double> close;
  final Animation<double> open;
  final Color panelColor;
  final Color pawColor;
  final bool instantCover;

  @override
  void paint(Canvas canvas, Size size) {
    final double c = close.value;
    final double o = open.value;
    final double extent = size.width + size.height;

    final Path panel;
    if (o > 0) {
      // Going-out: the panel retreats off the far corner to reveal the screen.
      panel = _halfPlaneAboveDiagonal(size, extent * o);
    } else if (instantCover) {
      // Sign-out: cover the whole screen at once so it's never visible.
      panel = Path()..addRect(Offset.zero & size);
    } else {
      // Going-in: the covered region grows diagonally from the start corner.
      panel = _halfPlaneBelowDiagonal(size, extent * c);
    }
    canvas.drawPath(panel, Paint()..color = panelColor);

    _paintPawTrail(canvas, size, c, o);
  }

  void _paintPawTrail(Canvas canvas, Size size, double c, double o) {
    const int count = 6;
    final double pawScale = size.shortestSide * 0.055;
    final double angle = math.atan2(size.height, size.width);
    final Offset normal = Offset(-math.sin(angle), math.cos(angle));
    final double sideStep = size.shortestSide * 0.05;

    // Paws walk in during the close, then fade out as the panel opens.
    final double trailFade = (1.0 - o / 0.5).clamp(0.0, 1.0).toDouble();
    if (trailFade <= 0) return;

    for (int i = 0; i < count; i++) {
      final double f = (i + 0.5) / count;
      final double appearAt = _lerp(0.05, 0.85, f);
      final double a = ((c - appearAt) / 0.15).clamp(0.0, 1.0).toDouble();
      if (a <= 0) continue;

      final Offset base = _pawMotifOffset(f, size);
      final double side = i.isEven ? 1.0 : -1.0;
      final Offset center = base + normal * (sideStep * side);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2 + side * 0.12);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawPath(
        _pawPath(center, pawScale),
        Paint()..color = pawColor.withValues(alpha: a * trailFade),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_OverlayCurtainPainter old) =>
      old.close.value != close.value ||
      old.open.value != open.value ||
      old.panelColor != panelColor ||
      old.pawColor != pawColor;
}
