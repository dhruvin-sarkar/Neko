# Design Document

## Overview

This design refines the existing page transitions in the Neko app by replacing mechanical easing curves with physics-based spring curves and adding outgoing-page animations. It also introduces a new branded **Paw Curtain Transition** for major context-switch handoffs (splash, welcome, onboarding, login). Changes are scoped to `lib/shared/motion/page_transitions.dart` (the transition implementations) and `lib/app/router.dart` (route wiring only), preserving the existing method signatures and navigation structure.

The approach:
1. Replace `Curves.easeOutCubic` in `slideFromRight` with a custom spring-based `Curve` (`_SpringCurve`) that produces slight overshoot. (unchanged)
2. Add a secondary animation layer to `slideFromRight` that slides the outgoing page leftward and fades it out. (unchanged)
3. Replace the raw `FadeTransition(opacity: animation)` in `fade` with a curved opacity tween using a decelerating curve consistent with the spring motion feel. The `fade` method is **retained** as a public helper. (unchanged)
4. **Add a new `pawCurtain({required LocalKey key, required Widget child})` method** that returns a `CustomTransitionPage` with a ~600ms duration. A full-screen solid-color panel sweeps diagonally to fully cover the screen at the midpoint, displays an animated dog-paw motif, performs the page swap while fully covered, then sweeps off the opposite corner to reveal the incoming page. The page content is faded so nothing is visible until the panel begins revealing it.
5. **Re-wire the router** so splash, welcome, onboarding, and login use `pawCurtain`; register, profile detail, and edit cat keep `slideFromRight`. The plain `fade` is no longer wired to splash/welcome/onboarding, but the method remains available.
6. **Honor reduce-motion**: when `MediaQuery.disableAnimations` is set, `pawCurtain` degrades to a plain quick `FadeTransition` and skips the painter entirely.

### What stays the same

The existing `_SpringCurve`, the `slideFromRight` spring + outgoing-page animation, and the curved `fade` are preserved exactly as designed. The Paw Curtain is purely additive: a new method plus a re-pointing of four route `pageBuilder`s.

## Architecture

### Component Structure

```
lib/shared/motion/page_transitions.dart
├── PageTransitions (abstract final class — existing signatures preserved)
│   ├── slideFromRight({required LocalKey key, required Widget child})   [unchanged]
│   │   └── transitionsBuilder uses:
│   │       ├── _springCurve (incoming page slide + fast opacity)
│   │       └── secondaryAnimation (outgoing page slide-left + fade-out)
│   ├── fade({required LocalKey key, required Widget child})             [retained]
│   │   └── transitionsBuilder uses:
│   │       └── _fadeCurve (smooth deceleration)
│   └── pawCurtain({required LocalKey key, required Widget child})       [NEW]
│       └── transitionDuration = _curtainDuration (~600ms)
│       └── transitionsBuilder:
│           ├── reduce-motion check → plain FadeTransition (no painter)
│           └── otherwise: Stack
│               ├── bottom: page content wrapped in FadeTransition
│               │           (opacity driven by _curtainContentOpacity → 0 until t≈0.5)
│               └── top:    CustomPaint(_PawCurtainPainter(t: animation.value))
│                           (diagonal panel + paw motif, full-screen)
├── Private curves / helpers
│   ├── _SpringCurve → custom damped-oscillation curve            [unchanged]
│   ├── _fadeCurve → Curves.easeOutCubic                          [unchanged]
│   ├── _PawCurtainPainter extends CustomPainter (NEW)
│   │   ├── paints diagonal solid-color panel per phase model
│   │   └── paints paw motif (main pad + toe beans) translated/rotated
│   ├── _curtainCoverage(t) / _curtainPanelOpacity(t) / _curtainContentOpacity(t)
│   └── _pawMotifOffset(t, size) / _pawMotifRotation(t)
└── Constants
    ├── _duration → Duration(280ms)            [unchanged — slide/fade]
    ├── _reverseDuration → Duration(240ms)     [unchanged]
    ├── _curtainDuration → Duration(600ms)     [NEW — within 500–700ms]
    └── _kPawBrandColor → const Color(...)      [NEW — tintable motif color]

lib/app/router.dart  [wiring only]
    ├── splash      → PageTransitions.pawCurtain   (was .fade)
    ├── welcome     → PageTransitions.pawCurtain   (was .fade)
    ├── onboarding  → PageTransitions.pawCurtain   (was .fade)
    ├── login       → PageTransitions.pawCurtain   (was .slideFromRight)
    ├── register    → PageTransitions.slideFromRight (unchanged)
    ├── profile     → PageTransitions.slideFromRight (unchanged)
    └── edit cat    → PageTransitions.slideFromRight (unchanged)
```

### Data Flow

```
GoRouter (router.dart)
    │
    ├─► PageTransitions.slideFromRight / .fade (unchanged API)
    │
    └─► PageTransitions.pawCurtain (NEW; same {key, child} shape)
PageTransitions
    │
    ├─ slideFromRight transitionsBuilder:
    │   ├─ animation (primary) ──► incoming page position (spring curve)
    │   ├─ animation (primary) ──► incoming page opacity (fast-fade interval)
    │   └─ secondaryAnimation ──► outgoing page position + opacity
    │
    ├─ fade transitionsBuilder:
    │   └─ animation (primary) ──► incoming page opacity (decelerate curve)
    │
    └─ pawCurtain transitionsBuilder:
        ├─ MediaQuery.disableAnimations? ──► FadeTransition only (early return)
        ├─ animation.value (t) ──► _curtainContentOpacity ──► page content fade
        └─ animation.value (t) ──► _PawCurtainPainter:
                                    ├─ _curtainCoverage(t)   → diagonal panel extent
                                    ├─ _curtainPanelOpacity(t)→ panel alpha
                                    └─ _pawMotifOffset/Rotation(t) → paw transform
```

### Layering rationale (Requirement 9)

`go_router`'s `transitionsBuilder` wraps the **incoming** page's `child`; whatever the builder returns is composited above that incoming page, and the framework holds the **outgoing** page beneath the route while the transition runs. By returning a `Stack` whose **top layer** is a full-screen `CustomPaint`, the colored panel draws above the incoming page content. At the midpoint the panel is at full coverage and full opacity across the entire viewport, so it also masks the outgoing page beneath the route — neither page is visible at `t = 0.5`. This satisfies "overlay above both pages" without having to reach outside the route's own subtree (no `Overlay` insertion, no global navigator manipulation).

## Detailed Design

### 1. Spring Curve Implementation

A custom `Curve` subclass encapsulating spring dynamics with controlled overshoot:

```dart
/// A spring-like curve that overshoots slightly before settling at 1.0.
/// Uses a damped oscillation formula: 1 - e^(-β·t) · cos(ω·t)
/// Tuned so max overshoot ≈ 3-4% (never exceeds 5%).
class _SpringCurve extends Curve {
  const _SpringCurve();

  // Damping coefficient — higher = less oscillation
  static const double _beta = 8.0;
  // Angular frequency — controls oscillation speed
  static const double _omega = 12.0;

  @override
  double transformInternal(double t) {
    // Damped oscillation settling at 1.0
    return 1.0 - math.exp(-_beta * t) * math.cos(_omega * t);
  }
}
```

The constants `_beta` and `_omega` are tuned so the curve:
- Is monotonically increasing for practical purposes in the visible range.
- Overshoots 1.0 briefly (by ~3–4%).
- Settles back to exactly 1.0 at `t = 1.0` (enforced by Flutter clamping the final value).

**Why not `Curves.elasticOut`?** It overshoots by ~30%, far exceeding the 5% budget. A custom curve gives precise control.

### 2. SlideFromRight — Enhanced transitionsBuilder

```dart
static CustomTransitionPage<void> slideFromRight({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: _duration,        // 280ms (unchanged)
    reverseTransitionDuration: _reverseDuration, // 240ms (unchanged)
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // ── Incoming page: slide from right with spring overshoot ──
      final incomingPosition = animation.drive(
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .chain(CurveTween(curve: const _SpringCurve())),
      );

      // ── Incoming page: fast opacity (0→1 in first 50% of duration) ──
      final incomingOpacity = animation.drive(
        Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: const Interval(0, 0.5, curve: Curves.easeOut)),
        ),
      );

      // ── Outgoing page: slide left by ≤30% + fade out ──
      final outgoingPosition = secondaryAnimation.drive(
        Tween<Offset>(begin: Offset.zero, end: const Offset(-0.25, 0))
            .chain(CurveTween(curve: Curves.easeInOut)),
      );

      final outgoingOpacity = secondaryAnimation.drive(
        Tween<double>(begin: 1, end: 0.7)
            .chain(CurveTween(curve: Curves.easeIn)),
      );

      // Stack: outgoing page behind, incoming page on top
      return SlideTransition(
        position: outgoingPosition,
        child: FadeTransition(
          opacity: outgoingOpacity,
          child: SlideTransition(
            position: incomingPosition,
            child: FadeTransition(
              opacity: incomingOpacity,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
```

**Key decisions:**
- Outgoing offset is `Offset(-0.25, 0)` — 25% leftward, well under the 30% cap.
- Outgoing opacity reduces to 0.7 (not 0.0) — enough to create depth without a harsh disappearance, consistent with premium feel.
- The `secondaryAnimation` automatically reverses on pop, so requirement 2.5 is handled by Flutter's animation system.

### 3. Fade — Smooth Decelerating Curve

```dart
static CustomTransitionPage<void> fade({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: _duration,  // 280ms (unchanged)
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}
```

`Curves.easeOutCubic` is a smooth decelerating curve that starts fast and settles gently — consistent with the spring's settling behavior while remaining appropriate for cross-fade scenarios where overshoot in opacity would look wrong (opacity > 1.0 has no visual effect anyway).

> Note: `fade` is retained as a public helper for any lightweight handoff, but it is no longer wired to splash/welcome/onboarding — those now use `pawCurtain` (see §4 and the router wiring in §9).

### 4. Paw Curtain — new `pawCurtain` method

A new public method mirroring the existing `{key, child}` shape so the router calls it identically. Its duration is a deliberate exception to the 260–320ms rule (Requirement 8).

```dart
static CustomTransitionPage<void> pawCurtain({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: _curtainDuration,        // 600ms (within 500–700ms)
    reverseTransitionDuration: _curtainDuration,  // symmetric sweep
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // ── Reduce-motion fallback (Requirement 10) ──
      // No painter, no diagonal sweep, no paw motif — just a quick fade.
      final bool reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
          child: child,
        );
      }

      // ── Page content fade: invisible until the panel fully covers ──
      // contentOpacity == 0 for all t <= 0.5, then ramps to 1.0 by reveal end.
      final Animation<double> contentOpacity = animation.drive(
        Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
        ),
      );

      // ── Overlay layer driven directly by the route animation ──
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Bottom: the (incoming) page content, masked until reveal.
          FadeTransition(opacity: contentOpacity, child: child),
          // Top: the full-screen curtain panel + paw motif.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PawCurtainPainter(
                  progress: animation,        // repaints with the animation
                  panelColor: _kCurtainColor,
                  pawColor: _kPawBrandColor,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
```

**Why a `CustomPainter` for the overlay (Requirement 9.3)?**
- **Single repaint surface.** The whole sweep (panel + paw + toe beans) is one paint pass on one layer instead of many animated widgets, so it repaints cheaply each frame.
- **Precise diagonal clip.** The diagonal edge is geometry, not a rectangle. A painter draws an exact polygon/path for the moving diagonal front; doing the same with clip widgets would be awkward and allocation-heavy.
- **Above both pages.** As the top child of the `Stack` returned from `transitionsBuilder`, the painter composites above the incoming page, and at full coverage masks the outgoing page beneath the route — exactly the overlay semantics Requirement 9 asks for, without inserting into a global `Overlay`.
- **Drive from the route animation.** Passing `animation` as the painter's `repaint` listenable ties every frame to `go_router`'s progress (Requirement 9.2).

### 5. Phase model and diagonal sweep math

Let `t = animation.value ∈ [0, 1]`. The sweep is split at the midpoint:

- **Phase 1 — cover (`t: 0 → 0.5`)**: the diagonal panel grows from the start corner until it covers the whole screen. Coverage fraction goes `0 → 1`.
- **Midpoint (`t = 0.5`)**: panel at **full coverage** and **full opacity**; the page swap and content fade are completely masked.
- **Phase 2 — reveal (`t: 0.5 → 1.0`)**: the panel retreats off the opposite corner; coverage goes `1 → 0`, uncovering the incoming page.

**Coverage fraction** (single peak at the midpoint):

```dart
// 0 at t=0, 1 at t=0.5, back to 0 at t=1.0 — a symmetric triangular peak.
double _curtainCoverage(double t) =>
    t <= 0.5 ? (t / 0.5) : (1.0 - (t - 0.5) / 0.5);
```

**Panel opacity** — solid through the covering phase, full at the midpoint:

```dart
// Opaque once it begins covering; only the very first sliver fades in so the
// leading edge isn't a hard pop. Guarantees opacity == 1.0 at t == 0.5.
double _curtainPanelOpacity(double t) =>
    (t * 8).clamp(0.0, 1.0).toDouble(); // reaches 1.0 well before t=0.5
```

**Diagonal wipe geometry.** The panel is the region behind a moving diagonal *front* (a line at 45° relative to the screen rectangle). To fully cover a `w × h` screen, the front must travel the combined extent `D = w + h` (so the diagonal line clears both the top-left and bottom-right corners). Define the front position by how far it has advanced along that extent:

```dart
// Phase 1: front advances from the top-left corner toward bottom-right.
// Phase 2: a trailing front advances the same way, uncovering behind it.
//
// For a top-left → bottom-right wipe, points (x, y) are "covered" when
// (x + y) <= front, where front sweeps 0 .. (w + h).
Path _panelPath(Size size, double t) {
  final double w = size.width, h = size.height;
  final double extent = w + h;

  if (t <= 0.5) {
    // Covering: leading front advances 0 → extent across the first half.
    final double front = extent * (t / 0.5);
    return _halfPlaneBelowDiagonal(size, front); // region where x + y <= front
  } else {
    // Revealing: trailing front advances 0 → extent across the second half,
    // so the *uncovered* region grows from the start corner.
    final double back = extent * ((t - 0.5) / 0.5);
    return _halfPlaneAboveDiagonal(size, back);   // region where x + y >= back
  }
}
```

`_halfPlaneBelowDiagonal` builds a polygon by clipping the line `x + y = front` to the screen rectangle (the covered side is the corner the sweep starts from); `_halfPlaneAboveDiagonal` is its complement for the reveal phase. Both clamp to the screen so the panel is exactly full-screen at `front = extent` (i.e. `t = 0.5`).

The painter then fills that path with `panelColor.withOpacity(_curtainPanelOpacity(t))`.

### 6. Paw motif transform

The paw motif rides along the same diagonal so it reads as "walking" across the panel. Its center is interpolated from the start corner to the opposite corner, with a slight rotation and an optional staggered second print.

```dart
// Position: travel along the diagonal from top-left → bottom-right, kept a
// little inside the edges by `inset` so the motif never clips off-screen.
Offset _pawMotifOffset(double t, Size size, {double inset = 48}) {
  final double x = lerpDouble(inset, size.width - inset, t)!;
  final double y = lerpDouble(inset, size.height - inset, t)!;
  return Offset(x, y);
}

// Rotation: a gentle wobble around the diagonal heading (~ -0.15 .. +0.15 rad).
double _pawMotifRotation(double t) =>
    (math.sin(t * math.pi * 2) * 0.15); // small, never a full spin

// Optional staggered prints: draw N paws offset slightly back along the
// diagonal, each with decreasing opacity, to suggest footsteps.
double _pawPrintOpacity(int index) =>
    (1.0 - index * 0.35).clamp(0.0, 1.0).toDouble();
```

During Phase 1 and Phase 2 the motif is only meaningfully visible while the panel covers it; the painter draws the paw only where `panelOpacity > 0` so beans never float over a bare page.

### 7. Paw shape (tintable vector — Requirement 6.5)

The paw is drawn directly in the painter from primitive shapes so it tints to any brand color via a single `Paint.color`, with no asset dependency:

- **Main pad**: one rounded shape (an `addRRect` on a slightly squashed rect, or a `cubicTo` blob) for the central pad.
- **Toe beans**: 3–4 small circles (`addOval`) arranged in an arc above the main pad.
- All sub-shapes are added to one `Path` and filled with a single `Paint()..color = pawColor`, so the motif is uniformly tintable.

```dart
Path _pawPath(Offset center, double scale) {
  final Path p = Path();
  // Main pad — squashed rounded rect / blob.
  p.addRRect(RRect.fromRectXY(
    Rect.fromCenter(center: center.translate(0, scale * 0.35),
        width: scale, height: scale * 0.9),
    scale * 0.45, scale * 0.45,
  ));
  // Toe beans — small circles in an arc.
  const List<Offset> toes = [Offset(-0.45, -0.55), Offset(-0.15, -0.8),
                             Offset(0.15, -0.8), Offset(0.45, -0.55)];
  for (final Offset toe in toes) {
    p.addOval(Rect.fromCircle(
      center: center.translate(toe.dx * scale, toe.dy * scale),
      radius: scale * 0.18,
    ));
  }
  return p;
}
```

The painter applies `_pawMotifOffset`/`_pawMotifRotation` via `canvas.translate` + `canvas.rotate` before drawing `_pawPath`, then draws optional staggered prints behind it.

### 8. `_PawCurtainPainter`

```dart
class _PawCurtainPainter extends CustomPainter {
  _PawCurtainPainter({
    required this.progress,        // the route animation (repaint listenable)
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
    if (coverage <= 0) return; // nothing to draw at the very start/end

    // 1) Diagonal panel.
    final Paint panelPaint = Paint()
      ..color = panelColor.withOpacity(_curtainPanelOpacity(t));
    canvas.drawPath(_panelPath(size, t), panelPaint);

    // 2) Paw motif (only while the panel is visibly covering).
    final Offset center = _pawMotifOffset(t, size);
    final double rot = _pawMotifRotation(t);
    final Paint pawPaint = Paint()..color = pawColor;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(_pawPath(center, size.shortestSide * 0.08), pawPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PawCurtainPainter old) =>
      old.progress.value != progress.value ||
      old.panelColor != panelColor ||
      old.pawColor != pawColor;
}
```

### 9. Router wiring (`lib/app/router.dart`)

Only the four context-switch `pageBuilder`s change; paths, redirects, and the `StatefulShellRoute` are untouched (Requirement 4.3).

```dart
// Context-switch handoffs → Paw Curtain
GoRoute(path: Routes.splash,     pageBuilder: (c, s) =>
    PageTransitions.pawCurtain(key: s.pageKey, child: const SplashScreen())),
GoRoute(path: Routes.welcome,    pageBuilder: (c, s) =>
    PageTransitions.pawCurtain(key: s.pageKey, child: const WelcomeScreen())),
GoRoute(path: Routes.onboarding, pageBuilder: (c, s) =>
    PageTransitions.pawCurtain(key: s.pageKey, child: const OnboardingScreen())),
GoRoute(path: Routes.login,      pageBuilder: (c, s) =>
    PageTransitions.pawCurtain(key: s.pageKey, child: const LoginScreen())),

// Routine forward pushes → unchanged
GoRoute(path: Routes.register,        pageBuilder: ... slideFromRight ...),
GoRoute(path: Routes.profilePattern,  pageBuilder: ... slideFromRight ...),
//   └─ 'edit' subroute              pageBuilder: ... slideFromRight ...
```

### 10. Constants

```dart
static const Duration _duration = Duration(milliseconds: 280);       // slide/fade
static const Duration _reverseDuration = Duration(milliseconds: 240); // slide pop
static const Duration _curtainDuration = Duration(milliseconds: 600); // paw curtain

static const Color _kCurtainColor = Color(0xFF...);   // panel fill (brand bg)
static const Color _kPawBrandColor = Color(0xFF...);  // tintable paw motif color
```

The slide/fade values remain within the 260–320ms (forward) and 220–280ms (reverse) ranges. `_curtainDuration` sits at 600ms, inside the 500–700ms window and treated as a deliberate exception to the slide/fade constraint (Requirement 8).

## Components and Interfaces

The feature is a self-contained motion module with no cross-feature interfaces. Its public surface is the `PageTransitions` class; everything else is private to `page_transitions.dart`.

### Public interface — `PageTransitions`

| Method | Signature | Used by | Status |
|--------|-----------|---------|--------|
| `slideFromRight` | `CustomTransitionPage<void> slideFromRight({required LocalKey key, required Widget child})` | register, profile detail, edit cat | unchanged |
| `fade` | `CustomTransitionPage<void> fade({required LocalKey key, required Widget child})` | retained helper (no longer wired to splash/welcome/onboarding) | unchanged signature |
| `pawCurtain` | `CustomTransitionPage<void> pawCurtain({required LocalKey key, required Widget child})` | splash, welcome, onboarding, login | **new** |

All three share the same `{required LocalKey key, required Widget child}` shape so `router.dart` calls them interchangeably (Requirement 4.4).

### Private collaborators

| Symbol | Kind | Responsibility |
|--------|------|----------------|
| `_SpringCurve` | `Curve` | Damped-oscillation curve with bounded overshoot (slide). |
| `_PawCurtainPainter` | `CustomPainter` | Paints the diagonal panel + paw motif; repaints off the route animation. |
| `_curtainCoverage(t)` | fn `double→double` | Triangular coverage fraction peaking at the midpoint. |
| `_curtainPanelOpacity(t)` | fn `double→double` | Panel alpha; reaches 1.0 by the midpoint. |
| `_curtainContentOpacity(t)` | fn `double→double` | Page content alpha; 0 until t≈0.5, then ramps to 1.0. |
| `_pawMotifOffset(t, size)` | fn `→Offset` | Diagonal travel of the motif, clamped within an inset. |
| `_pawMotifRotation(t)` | fn `double→double` | Small wobble rotation for the motif. |
| `_pawPath(center, scale)` | fn `→Path` | Tintable paw vector (main pad + toe beans). |

### Consumer — `router.dart`

The router depends only on the `PageTransitions` static API. The only change is repointing four `pageBuilder`s from `fade`/`slideFromRight` to `pawCurtain` (see §9). No route paths, redirects, or `StatefulShellRoute` branches change (Requirements 4.2, 4.3).

## Data Models

This feature has no persisted or domain data models. Its "models" are the transient, animation-derived values computed per frame from a single scalar input `t = animation.value ∈ [0, 1]`:

| Value | Type | Domain | Meaning |
|-------|------|--------|---------|
| `t` | `double` | `[0, 1]` | Route animation progress (input). |
| coverage | `double` | `[0, 1]` | Fraction of the screen the panel covers; peaks at `t = 0.5`. |
| panel opacity | `double` | `[0, 1]` | Alpha of the colored panel. |
| content opacity | `double` | `[0, 1]` | Alpha of the page content; 0 for `t ≤ 0.5`. |
| paw offset | `Offset` | within screen `Size` | Motif center along the diagonal. |
| paw rotation | `double` (rad) | `≈[-0.15, 0.15]` | Motif wobble. |

Configuration constants (`_curtainDuration`, `_kCurtainColor`, `_kPawBrandColor`) are the only stored state, all compile-time `const`.

## Error Handling

This feature involves purely visual animation logic with no I/O, network, or state-management concerns. The key failure modes:

| Scenario | Mitigation |
|----------|-----------|
| Spring curve evaluates outside [0, ~1.05] range | Flutter clamps final transform to destination; overshoot is visually bounded by the Tween endpoints. Unit-test the curve bounds. |
| secondaryAnimation not provided by go_router | go_router always provides secondaryAnimation (it may be `kAlwaysDismissedAnimation` when there's no outgoing page). The outgoing animation gracefully does nothing at value 0. |
| Duration values accidentally changed | Compile-time constants; property tests verify range. |
| Reduce-motion enabled mid-app | `MediaQuery.of(context).disableAnimations` is read inside `transitionsBuilder` per build, so a change is picked up on the next transition; the painter branch is skipped entirely (no partial sweep). |
| Paw motif drifts off-screen | `_pawMotifOffset` is clamped within an `inset` margin from both edges; property test verifies bounds for all t. |
| Painter runs when fully transparent | `_PawCurtainPainter.paint` early-returns when `_curtainCoverage(t) <= 0`, avoiding wasted work at the very start/end. |
| Page elements visible mid-swap | `_curtainContentOpacity` is 0 for all `t <= 0.5`, and panel opacity is 1.0 at the midpoint, so the swap is fully masked. Property tests verify both. |
| go_router does not provide a real outgoing page | At full coverage the opaque panel covers the entire viewport regardless of what is beneath, so masking holds even on the initial route. |

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Spring curve overshoot is bounded

*For any* evaluation point t in [0, 1], the spring curve's output SHALL be greater than 0 at t > 0 AND the maximum output across all t SHALL exceed 1.0 (exhibiting overshoot) AND never exceed 1.05 (≤ 5% overshoot).

**Validates: Requirements 1.1, 1.2**

### Property 2: Outgoing page offset is bounded leftward

*For any* secondary animation value t in [0, 1], the outgoing page horizontal offset SHALL be in the range [-0.30, 0.0], ensuring the leftward displacement never exceeds 30% of screen width.

**Validates: Requirements 2.1, 2.4**

### Property 3: Outgoing page opacity is non-increasing

*For any* two secondary animation values t₁ < t₂ in [0, 1], the outgoing page opacity at t₂ SHALL be less than or equal to the opacity at t₁, and the opacity at t = 1 SHALL be strictly less than 1.0.

**Validates: Requirements 2.2**

### Property 4: Secondary animation round-trip restores original state

*For any* secondary animation that progresses from 0 → 1 → 0 (push then pop), the outgoing page's offset and opacity at secondary value 0 SHALL equal their initial values (Offset.zero and opacity 1.0).

**Validates: Requirements 2.5**

### Property 5: Incoming page fast-fade completes in first half

*For any* primary animation value t ≥ 0.5, the incoming page opacity SHALL equal 1.0, and at t = 0 it SHALL equal 0.0.

**Validates: Requirements 5.1, 5.2**

### Property 6: Fade curve is monotonically non-decreasing

*For any* two evaluation points t₁ < t₂ in [0, 1], the fade transition curve's output at t₂ SHALL be greater than or equal to its output at t₁.

**Validates: Requirements 3.1**

### Property 7: Panel reaches full coverage and full opacity at the midpoint

*For any* Paw Curtain Transition, at `t = 0.5` the coverage fraction `_curtainCoverage(t)` SHALL equal 1.0 (the panel covers the full screen) AND the panel opacity `_curtainPanelOpacity(t)` SHALL equal 1.0.

**Validates: Requirements 6.2, 7.3**

### Property 8: Incoming page content is fully masked before the reveal

*For any* animation value t in [0, 0.5], the page content opacity `_curtainContentOpacity(t)` SHALL equal 0.0, and for t = 1.0 it SHALL equal 1.0 — so no incoming page element is visible before the panel begins revealing it.

**Validates: Requirements 7.1, 7.2**

### Property 9: Coverage rises then falls with a single peak at the midpoint

*For any* two values t₁ < t₂ in [0, 0.5], `_curtainCoverage(t₁) ≤ _curtainCoverage(t₂)` (non-decreasing while covering); *for any* two values t₁ < t₂ in [0.5, 1.0], `_curtainCoverage(t₁) ≥ _curtainCoverage(t₂)` (non-increasing while revealing); AND `_curtainCoverage(0) = 0`, `_curtainCoverage(1) = 0`. The panel therefore reaches full coverage exactly once, at the midpoint.

**Validates: Requirements 6.2, 6.4**

### Property 10: Paw motif stays within screen bounds

*For any* animation value t in [0, 1] and any screen `Size`, the paw motif center `_pawMotifOffset(t, size)` SHALL lie within the screen rectangle (inset from each edge), so the motif never clips off-screen during its diagonal travel.

**Validates: Requirements 6.3**

### Property 11: Reduce-motion fallback contains no curtain painter

*For any* `pawCurtain` invocation built while `MediaQuery.disableAnimations` is true, and for any animation value t in [0, 1], the returned transition subtree SHALL be a plain `FadeTransition` containing no `_PawCurtainPainter` (no diagonal sweep and no paw motif).

**Validates: Requirements 10.1, 10.2**

### Property 12: Transition durations respect their ranges

*For any* `pawCurtain` page, the `transitionDuration` SHALL be within [500ms, 700ms]; AND the `slideFromRight` and `fade` forward durations SHALL remain within [260ms, 320ms] (with the slide reverse duration within [220ms, 280ms]), confirming the curtain is a deliberate exception rather than a regression of the existing constraints.

**Validates: Requirements 8.1, 8.2**

## Testing Strategy

A dual approach: property tests for the universal, input-varying math, and example/widget tests for structural and configuration guarantees.

### Property tests (≥100 iterations each)

The animation helpers (`_curtainCoverage`, `_curtainPanelOpacity`, `_curtainContentOpacity`, `_pawMotifOffset`, `_SpringCurve`) are pure functions of `t` (and `Size`), ideal for property-based testing over random `t ∈ [0,1]` and random screen sizes. Each test references its design property using the tag format **Feature: page-transition-animations, Property {number}: {property_text}**.

- Property 1 — `_SpringCurve` overshoot bounded (existing).
- Properties 2–5 — slide outgoing/incoming behavior (existing).
- Property 6 — fade curve monotonic (existing).
- Property 7 — coverage and panel opacity both equal 1.0 at `t = 0.5`.
- Property 8 — content opacity == 0 for all `t ≤ 0.5`, == 1.0 at `t = 1.0`.
- Property 9 — coverage non-decreasing on `[0,0.5]`, non-increasing on `[0.5,1]`, zero at the endpoints (single peak).
- Property 10 — `_pawMotifOffset(t, size)` within bounds for all `t` and random sizes.
- Property 11 — reduce-motion build yields a `FadeTransition` with no `_PawCurtainPainter`.
- Property 12 — duration ranges for `pawCurtain` (500–700ms) and `slideFromRight`/`fade` (260–320ms / 220–280ms).

### Example & widget tests

- `pawCurtain` returns a `CustomTransitionPage`; `slideFromRight`/`fade` signatures unchanged (Requirements 6.1, 4.4).
- Widget test: with animations enabled, the topmost layer of the `pawCurtain` subtree is the `CustomPaint` overlay (Requirements 9.1, 9.3).
- Widget test: with `MediaQuery(disableAnimations: true)`, no `CustomPaint`/`_PawCurtainPainter` is present (Requirements 10.1, 10.2).
- Golden/widget test: paw motif tints to `_kPawBrandColor` (Requirement 6.5).
- Router test: splash/welcome/onboarding/login resolve to `pawCurtain` pages; register/profile/edit-cat remain `slideFromRight`; paths and redirects unchanged (Requirements 4.1, 4.2, 4.3).

### Notes

- Property tests target the pure helpers directly (no widget pump needed), keeping iterations cheap.
- The page swap being masked (Requirement 7.1) is verified indirectly: Property 7 (full opaque coverage at midpoint) plus Property 8 (content hidden through the midpoint) together guarantee nothing is visible during the swap.
