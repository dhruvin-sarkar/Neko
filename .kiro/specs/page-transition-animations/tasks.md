# Implementation Plan: Page Transition Animations

## Overview

Enhance the page transitions in `lib/shared/motion/page_transitions.dart`. The first phase (complete) introduced a physics-based spring curve with slight overshoot, outgoing-page animations for `slideFromRight`, and a smooth decelerating curve for `fade`.

This phase adds the branded **Paw Curtain Transition** for major context-switch handoffs (splash, welcome, onboarding, login): a full-screen colored panel sweeps diagonally to fully cover the screen at the midpoint, an animated dog-paw motif travels across it, the page swap and content fade happen while fully covered, then the panel sweeps off the opposite corner to reveal the incoming page. Implementation is confined to `lib/shared/motion/page_transitions.dart` (the transition) and `lib/app/router.dart` (route wiring only).

## Tasks

- [x] 1. Implement _SpringCurve class and update slideFromRight
  - [x] 1.1 Add dart:math import and implement the `_SpringCurve` custom Curve class
    - Add `import 'dart:math' as math;` at the top of `page_transitions.dart`
    - Create a private `_SpringCurve extends Curve` class with `const` constructor
    - Implement `transformInternal(double t)` using damped oscillation: `1.0 - math.exp(-_beta * t) * math.cos(_omega * t)` with `_beta = 8.0` and `_omega = 12.0`
    - _Requirements: 1.1, 1.2_

  - [x] 1.2 Replace easing curve and add outgoing page animation in slideFromRight
    - Replace `Curves.easeOutCubic` with `const _SpringCurve()` in the incoming page position tween
    - Add outgoing page animations driven by `secondaryAnimation`:
      - Outgoing position: `Offset.zero` → `Offset(-0.25, 0)` with `Curves.easeInOut`
      - Outgoing opacity: `1.0` → `0.7` with `Curves.easeIn`
    - Restructure widget tree: wrap existing `SlideTransition`/`FadeTransition` for incoming page inside outgoing page `SlideTransition` + `FadeTransition`
    - Preserve existing incoming opacity interval `(0, 0.5, curve: Curves.easeOut)` for fast-fade
    - Keep `_duration` (280ms) and `_reverseDuration` (240ms) unchanged
    - _Requirements: 1.1, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 5.1, 5.2_

- [x] 2. Update fade transition with decelerating curve
  - [x] 2.1 Replace raw opacity with curved FadeTransition in fade method
    - Change `FadeTransition(opacity: animation, child: child)` to use `animation.drive(CurveTween(curve: Curves.easeOutCubic))`
    - Preserve `_duration` (280ms) and existing method signature
    - _Requirements: 3.1, 3.2, 4.4_

- [ ] 3. Checkpoint - Verify compilation and existing slide/fade behavior
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Property-based tests for spring curve and existing slide/fade behaviors
  - [ ]* 4.1 Write property test for spring curve overshoot bounds
    - **Property 1: Spring curve overshoot is bounded**
    - Test that for all t in [0, 1], the curve output > 0 when t > 0, the max exceeds 1.0, and never exceeds 1.05
    - Create test file `test/shared/motion/page_transitions_test.dart`
    - Use dart:math randomized t values across the range
    - **Validates: Requirements 1.1, 1.2**

  - [ ]* 4.2 Write property test for outgoing page offset bounds
    - **Property 2: Outgoing page offset is bounded leftward**
    - Test that for all secondary animation values t in [0, 1], the outgoing offset dx is in [-0.30, 0.0]
    - Evaluate the outgoing position tween at randomized t values
    - **Validates: Requirements 2.1, 2.4**

  - [ ]* 4.3 Write property test for outgoing page opacity non-increasing
    - **Property 3: Outgoing page opacity is non-increasing**
    - Test that for any t₁ < t₂ in [0, 1], opacity(t₂) ≤ opacity(t₁), and opacity(1) < 1.0
    - Evaluate the outgoing opacity tween at sorted randomized pairs
    - **Validates: Requirements 2.2**

  - [ ]* 4.4 Write property test for secondary animation round-trip
    - **Property 4: Secondary animation round-trip restores original state**
    - Test that at secondary animation value 0, outgoing offset = Offset.zero and opacity = 1.0
    - **Validates: Requirements 2.5**

  - [ ]* 4.5 Write property test for incoming fast-fade completes in first half
    - **Property 5: Incoming page fast-fade completes in first half**
    - Test that for all t ≥ 0.5, incoming opacity = 1.0, and at t = 0 opacity = 0.0
    - Evaluate incoming opacity tween at randomized t values
    - **Validates: Requirements 5.1, 5.2**

  - [ ]* 4.6 Write property test for fade curve monotonicity
    - **Property 6: Fade curve is monotonically non-decreasing**
    - Test that for any t₁ < t₂ in [0, 1], fade curve output at t₂ ≥ output at t₁
    - Evaluate `Curves.easeOutCubic` at randomized sorted pairs
    - **Validates: Requirements 3.1**

- [ ] 5. Add Paw Curtain constants and pure helper functions
  - [x] 5.1 Add Paw Curtain constants to `page_transitions.dart`
    - Add `static const Duration _curtainDuration = Duration(milliseconds: 600);` (within the 500–700ms window, per design §10)
    - Add `static const Color _kCurtainColor` (panel fill / brand background)
    - Add `static const Color _kPawBrandColor` (tintable paw motif color)
    - Keep existing `_duration` (280ms) and `_reverseDuration` (240ms) untouched
    - _Requirements: 6.5, 8.1, 8.2_

  - [x] 5.2 Implement coverage and opacity helper functions
    - Implement `_curtainCoverage(double t)` → triangular peak: `t <= 0.5 ? t / 0.5 : 1.0 - (t - 0.5) / 0.5` (0 at endpoints, 1.0 at t=0.5) (design §5)
    - Implement `_curtainPanelOpacity(double t)` → `(t * 8).clamp(0.0, 1.0)` so it reaches 1.0 well before t=0.5 (design §5)
    - Implement `_curtainContentOpacity(double t)` → 0.0 for all t ≤ 0.5, ramping to 1.0 by t=1.0 via `Interval(0.5, 1.0, curve: Curves.easeIn)` (design §4, §6)
    - _Requirements: 6.2, 6.4, 7.1, 7.2, 7.3_

  - [x] 5.3 Implement paw motif transform helpers and diagonal panel path geometry
    - Implement `_pawMotifOffset(double t, Size size, {double inset = 48})` interpolating the motif center along the diagonal, clamped within `inset` from each edge (design §6)
    - Implement `_pawMotifRotation(double t)` → gentle wobble `math.sin(t * 2π) * 0.15` (design §6)
    - Implement the diagonal half-plane panel path: `_panelPath(Size, double t)` plus `_halfPlaneBelowDiagonal(Size, front)` (covered region where `x + y <= front`, Phase 1) and `_halfPlaneAboveDiagonal(Size, back)` (uncovered region where `x + y >= back`, Phase 2), with `extent = w + h` so coverage is exactly full-screen at t=0.5 (design §5)
    - _Requirements: 6.2, 6.3, 6.4_

  - [x] 5.4 Implement the tintable `_pawPath` vector
    - Build a single `Path` from primitive shapes: a rounded main pad (`addRRect`) plus 3–4 toe beans (`addOval`) arranged in an arc (design §7)
    - Ensure the whole motif fills with one `Paint()..color = pawColor` so it is uniformly tintable to `_kPawBrandColor` (no asset dependency)
    - _Requirements: 6.5_

  - [ ]* 5.5 Write property test for full coverage and opacity at the midpoint
    - **Property 7: Panel reaches full coverage and full opacity at the midpoint**
    - Test that `_curtainCoverage(0.5) == 1.0` AND `_curtainPanelOpacity(0.5) == 1.0`
    - Add to `test/shared/motion/page_transitions_test.dart`
    - **Validates: Requirements 6.2, 7.3**

  - [ ]* 5.6 Write property test for content masking before reveal
    - **Property 8: Incoming page content is fully masked before the reveal**
    - Test that for all t in [0, 0.5], `_curtainContentOpacity(t) == 0.0`, and `_curtainContentOpacity(1.0) == 1.0`
    - Use randomized t values in [0, 0.5]
    - **Validates: Requirements 7.1, 7.2**

  - [ ]* 5.7 Write property test for single-peak coverage profile
    - **Property 9: Coverage rises then falls with a single peak at the midpoint**
    - Test non-decreasing on [0, 0.5], non-increasing on [0.5, 1.0], and `_curtainCoverage(0) == 0`, `_curtainCoverage(1) == 0`
    - Use sorted randomized pairs within each half
    - **Validates: Requirements 6.2, 6.4**

  - [ ]* 5.8 Write property test for paw motif staying within screen bounds
    - **Property 10: Paw motif stays within screen bounds**
    - Test that for all t in [0, 1] and randomized screen `Size` values, `_pawMotifOffset(t, size)` lies within the screen rectangle (inset from each edge)
    - **Validates: Requirements 6.3**

- [ ] 6. Implement _PawCurtainPainter
  - [x] 6.1 Implement the `_PawCurtainPainter extends CustomPainter`
    - Constructor takes `progress` (the route `Animation<double>`), `panelColor`, `pawColor`; pass `super(repaint: progress)` so it repaints off the route animation (design §8)
    - In `paint`: early-return when `_curtainCoverage(t) <= 0`; fill `_panelPath(size, t)` with `panelColor.withOpacity(_curtainPanelOpacity(t))`; then `save`/`translate`/`rotate` and draw `_pawPath` at `_pawMotifOffset`/`_pawMotifRotation`, then `restore`
    - Implement `shouldRepaint` comparing `progress.value`, `panelColor`, and `pawColor`
    - _Requirements: 6.2, 6.3, 9.1, 9.2, 9.3_

- [ ] 7. Implement the pawCurtain method
  - [x] 7.1 Implement `pawCurtain({required LocalKey key, required Widget child})`
    - Return a `CustomTransitionPage<void>` with `transitionDuration` and `reverseTransitionDuration` set to `_curtainDuration` (~600ms)
    - In `transitionsBuilder`: reduce-motion early-return — when `MediaQuery.of(context).disableAnimations` is true, return a plain `FadeTransition` (no painter, no sweep, no motif)
    - Otherwise return a `Stack(fit: StackFit.expand, ...)` with the page content wrapped in a `FadeTransition` driven by `_curtainContentOpacity` (0 until t≈0.5) as the bottom layer, and a full-screen `Positioned.fill` → `IgnorePointer` → `CustomPaint(painter: _PawCurtainPainter(progress: animation, ...))` as the topmost layer (design §4)
    - Match the existing `{required LocalKey key, required Widget child}` signature so the router calls it interchangeably
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 7.1, 7.2, 7.3, 8.1, 9.1, 9.2, 9.3, 10.1, 10.2_

  - [ ]* 7.2 Write property test for the reduce-motion fallback
    - **Property 11: Reduce-motion fallback contains no curtain painter**
    - Pump `pawCurtain` inside a `MediaQuery(disableAnimations: true)` and assert the returned subtree is a plain `FadeTransition` with no `CustomPaint`/`_PawCurtainPainter`
    - **Validates: Requirements 10.1, 10.2**

  - [ ]* 7.3 Write property test for transition duration ranges
    - **Property 12: Transition durations respect their ranges**
    - Assert `pawCurtain` `transitionDuration` ∈ [500ms, 700ms]; `slideFromRight`/`fade` forward ∈ [260ms, 320ms]; slide reverse ∈ [220ms, 280ms]
    - **Validates: Requirements 8.1, 8.2**

  - [ ]* 7.4 Write widget test for the overlay layer being topmost
    - With animations enabled, pump a `pawCurtain` transition and assert the topmost layer of its subtree is the full-screen `CustomPaint` overlay above the page content
    - _Requirements: 9.1, 9.3_

  - [ ]* 7.5 Write widget test for the paw motif brand tint
    - Assert the `_PawCurtainPainter` is configured with `pawColor == _kPawBrandColor` so the motif tints to the brand color
    - _Requirements: 6.5_

- [ ] 8. Checkpoint - Verify compilation and Paw Curtain tests
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Wire the router to the Paw Curtain
  - [x] 9.1 Repoint context-switch handoffs in `lib/app/router.dart`
    - Change the `pageBuilder`s for splash, welcome, onboarding, and login to `PageTransitions.pawCurtain(key: state.pageKey, child: ...)` (splash/welcome/onboarding were `fade`, login was `slideFromRight`)
    - Keep register, profile detail, and edit cat on `PageTransitions.slideFromRight`
    - Leave route paths, redirects, and the `StatefulShellRoute` configuration unchanged
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 9.2 Write router test for the route → transition mapping
    - Assert splash/welcome/onboarding/login resolve to `pawCurtain` pages and register/profile/edit-cat resolve to `slideFromRight` pages; confirm paths and redirects are unchanged
    - _Requirements: 4.1, 4.2, 4.3_

- [ ] 10. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Implementation changes are confined to `lib/shared/motion/page_transitions.dart` and `lib/app/router.dart`; tests live in `test/shared/motion/page_transitions_test.dart` and a router test
- The `fade` method is retained as a public helper but is no longer wired to splash/welcome/onboarding
- Pure-helper property tests (Properties 7–10) target functions directly with no widget pump; Property 11 is a widget-level reduce-motion check and Property 12 verifies duration ranges
- Property tests use randomized inputs (and randomized `Size` for the paw motif) within the valid domain to approximate property-based testing in Dart's `flutter_test` framework
- Checkpoints ensure incremental validation: existing behavior after Task 3, curtain behavior after Task 8, and the full wiring after Task 10

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "5.1"] },
    { "id": 1, "tasks": ["5.2", "5.3", "5.4"] },
    { "id": 2, "tasks": ["5.5", "5.6", "5.7", "5.8", "6.1"] },
    { "id": 3, "tasks": ["7.1"] },
    { "id": 4, "tasks": ["7.2", "7.3", "7.4", "7.5", "9.1"] },
    { "id": 5, "tasks": ["9.2"] }
  ]
}
```
