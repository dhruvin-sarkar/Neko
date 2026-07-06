# Requirements Document

## Introduction

Refine and extend the page transition animations in the Neko app so navigation feels smoother, more organic, and polished. The original work replaced a mechanical easing curve with a physics-based spring curve (slight overshoot) and added a secondary outgoing-page animation (subtle slide + fade) so both pages participate in forward navigation. A curved cross-fade was also applied to lightweight handoffs.

This update adds a new branded transition — the **Paw Curtain Transition** — for major context-switch handoffs (splash, welcome, onboarding, login). A full-screen colored panel sweeps diagonally across the screen, fully covering it mid-transition while an animated dog-paw motif travels across the panel, then sweeps off the opposite corner to reveal the new page. Critically, the page swap and a fade occur while the screen is fully covered so the user never sees page elements appearing or popping mid-transition — a problem observed with the lighter transitions. The Paw Curtain replaces the plain fade previously used for splash, welcome, and onboarding handoffs. The spring slide-from-right transition is retained unchanged for routine forward pushes (profile detail, edit cat, register).

## Glossary

- **PageTransitions**: The centralized helper class at `lib/shared/motion/page_transitions.dart` that produces `CustomTransitionPage` instances used by `go_router` route definitions.
- **SlideFromRight Transition**: The transition applied to routine forward navigation routes (register, profile detail, edit cat) where the incoming page enters from the right edge of the screen.
- **Fade Transition**: The curved cross-fade transition retained as a helper for lightweight handoffs where neither a slide nor a curtain is appropriate.
- **Paw Curtain Transition**: A branded transition where a full-screen solid-color panel sweeps diagonally to fully cover the screen, displays an animated dog-paw motif, performs the page swap while covered, then sweeps off the opposite corner to reveal the incoming page.
- **Curtain Overlay Layer**: A full-screen rendering layer (e.g. a `CustomPainter` or stacked `AnimatedBuilder` driven by the route animation) that sits above BOTH the outgoing and incoming pages during the sweep, so the colored panel masks the page swap.
- **Paw Motif**: A tintable vector graphic (a `CustomPainter` path or `Icon`/SVG) of a dog paw print, rendered on the Curtain Overlay Layer, that translates and rotates slightly along the diagonal during the sweep; it may include one or more staggered prints to suggest walking.
- **Context-Switch Handoff**: A major navigation handoff between distinct app contexts: splash, welcome, onboarding, and login.
- **Routine Forward Push**: A standard forward navigation within an established context (register, profile detail, edit cat).
- **Reduce Motion Setting**: The operating-system accessibility preference (exposed via `MediaQuery.disableAnimations` / `MediaQueryData.accessibleNavigation`) that signals the user prefers reduced motion.
- **Spring Curve**: A physics-driven animation curve that simulates spring dynamics, producing slight overshoot before settling, giving a lively organic feel.
- **Primary Animation**: The `animation` parameter in `transitionsBuilder` that drives the incoming page.
- **Secondary Animation**: The `secondaryAnimation` parameter in `transitionsBuilder` that drives the outgoing page when a new page pushes on top.
- **Outgoing Page Animation**: The visual effect applied to the page being navigated away from (slide left and fade out) during a forward navigation.
- **Router**: The `GoRouter` configuration in `lib/app/router.dart` that maps routes to page builders.

## Requirements

### Requirement 1: Spring-Based Motion Curve for SlideFromRight

**User Story:** As a user, I want forward page transitions to feel lively and natural, so that navigation feels polished rather than mechanical.

#### Acceptance Criteria

1. WHEN the SlideFromRight Transition animates the incoming page, THE PageTransitions SHALL use a Spring Curve with slight overshoot instead of `Curves.easeOutCubic`.
2. THE PageTransitions SHALL configure the Spring Curve to produce a visually perceptible but subtle overshoot that does not exceed approximately 5% of the total travel distance.
3. THE PageTransitions SHALL maintain a SlideFromRight Transition forward duration between 260ms and 320ms.
4. THE PageTransitions SHALL maintain a SlideFromRight Transition reverse (pop) duration between 220ms and 280ms.

### Requirement 2: Outgoing Page Animation for SlideFromRight

**User Story:** As a user, I want the current page to animate away when I navigate forward, so that transitions feel continuous with a sense of depth between screens.

#### Acceptance Criteria

1. WHEN a forward SlideFromRight Transition occurs, THE PageTransitions SHALL animate the outgoing page with a leftward horizontal offset.
2. WHEN a forward SlideFromRight Transition occurs, THE PageTransitions SHALL animate the outgoing page with a fade-out opacity reduction.
3. THE PageTransitions SHALL drive the Outgoing Page Animation using the Secondary Animation parameter provided by `go_router`.
4. THE PageTransitions SHALL limit the outgoing page leftward offset to no more than 30% of the screen width to keep the effect subtle.
5. WHEN the transition reverses (pop), THE PageTransitions SHALL reverse the outgoing page animation so the returning page slides back from the left and fades in.

### Requirement 3: Spring-Based Motion Curve for Fade Transition

**User Story:** As a user, I want fade transitions to feel smooth and organic, consistent with the rest of the app.

#### Acceptance Criteria

1. WHEN the Fade Transition animates the incoming page, THE PageTransitions SHALL use a smooth decelerating curve that feels consistent with the spring-based motion used in slide transitions.
2. THE PageTransitions SHALL maintain the Fade Transition duration between 260ms and 320ms.

### Requirement 4: Preserve Existing Navigation Structure and UI

**User Story:** As a developer, I want the animation refinement to be self-contained, so that no existing screens, routes, or navigation logic are affected.

#### Acceptance Criteria

1. THE PageTransitions SHALL apply the Paw Curtain Transition to the splash, welcome, onboarding, and login handoffs, and the SlideFromRight Transition to the register, profile detail, and edit cat routes.
2. THE PageTransitions SHALL confine all changes to `lib/shared/motion/page_transitions.dart` and, if needed, the route wiring in `lib/app/router.dart`.
3. THE Router SHALL continue to use the same route paths, redirects, and `StatefulShellRoute` configuration without modification.
4. THE PageTransitions SHALL preserve the existing method signatures (`slideFromRight` and `fade`) so existing calling code requires no changes.

### Requirement 5: Incoming Page Fast Fade Retained

**User Story:** As a user, I want the incoming page on slide transitions to still fade in quickly at the start, so the page does not appear to pop in abruptly from a transparent state.

#### Acceptance Criteria

1. WHEN the SlideFromRight Transition begins, THE PageTransitions SHALL apply a leading opacity animation to the incoming page that completes within the first half of the transition duration.
2. THE PageTransitions SHALL drive the incoming page opacity from fully transparent to fully opaque.

### Requirement 6: Paw Curtain Transition for Context-Switch Handoffs

**User Story:** As a user, I want major context switches to use a distinctive branded curtain sweep, so that significant transitions feel intentional and on-brand.

#### Acceptance Criteria

1. THE PageTransitions SHALL provide a new transition method (e.g. `pawCurtain`) that produces the Paw Curtain Transition, in addition to the existing `slideFromRight` and `fade` methods.
2. WHEN the Paw Curtain Transition plays forward, THE PageTransitions SHALL sweep a full-screen solid-color panel diagonally across the screen until the panel fully covers the screen at the transition midpoint.
3. WHILE the panel fully covers the screen, THE PageTransitions SHALL animate the Paw Motif translating and rotating along the diagonal across the panel.
4. WHEN the transition continues past the midpoint, THE PageTransitions SHALL sweep the panel off the opposite corner to reveal the incoming page.
5. THE PageTransitions SHALL render the Paw Motif as a vector that is tintable to a configurable brand color.

### Requirement 7: Full Masking of the Page Swap

**User Story:** As a user, I want the new page to be fully hidden while it is being prepared, so that I never see page elements appearing or popping mid-transition.

#### Acceptance Criteria

1. WHILE the panel fully covers the screen, THE PageTransitions SHALL perform the swap from the outgoing page to the incoming page.
2. WHILE the panel fully covers the screen, THE PageTransitions SHALL apply a fade to the page content so that no incoming page element is visible to the user before the panel begins to reveal it.
3. WHEN the Paw Curtain Transition is at its midpoint, THE PageTransitions SHALL render the colored panel at full opacity covering the entire screen.

### Requirement 8: Paw Curtain Duration

**User Story:** As a user, I want the curtain sweep to last long enough to read the paw motion, so that the branded animation is legible rather than a flash.

#### Acceptance Criteria

1. THE PageTransitions SHALL set the Paw Curtain Transition duration between 500ms and 700ms.
2. THE PageTransitions SHALL apply the 260ms-to-320ms duration constraint only to the SlideFromRight Transition and the Fade Transition, treating the Paw Curtain Transition duration as a deliberate exception.

### Requirement 9: Overlay Layer Above Both Pages

**User Story:** As a developer, I want the colored panel to render above both the outgoing and incoming pages, so that the swap is reliably masked regardless of page content.

#### Acceptance Criteria

1. THE PageTransitions SHALL render the colored panel and Paw Motif on a Curtain Overlay Layer that sits above both the outgoing page and the incoming page during the sweep.
2. THE PageTransitions SHALL drive the Curtain Overlay Layer from the route animation provided by `go_router`.
3. THE PageTransitions SHALL implement the Curtain Overlay Layer using a full-screen rendering construct (a `CustomPainter` or stacked `AnimatedBuilder`) rather than placing the panel solely inside the incoming page's content subtree.

### Requirement 10: Reduce Motion Accessibility Fallback

**User Story:** As a user who prefers reduced motion, I want a calmer transition, so that the app respects my operating-system accessibility setting.

#### Acceptance Criteria

1. WHERE the Reduce Motion Setting is enabled, THE PageTransitions SHALL replace the Paw Curtain Transition with a plain quick fade.
2. WHERE the Reduce Motion Setting is enabled, THE PageTransitions SHALL omit the diagonal panel sweep and the Paw Motif animation.
