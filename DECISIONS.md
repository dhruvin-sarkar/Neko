# Autonomous Decisions

One line per significant judgment call made while building, for review.

- Context7/MCP was not actually available in this environment, so the GoRouter + Riverpod redirect pattern was validated via web search and the `dart-flutter-patterns` skill instead.
- Skill files live outside the workspace sandbox; `dart-flutter-patterns` was read via shell, the rest applied from knowledge plus the explicit design spec.
- Kept Firebase on the v2/v4 line per instruction; added `firebase_storage ^11.6.x` as the compatible version.
- Treated STARTING_PROMPT design tokens as source of truth over UI_GUIDELINES where they conflicted (white onboarding, `#F5C275` home, coral, Nunito).
- Auth precedes onboarding (per the explicit redirect rules); Akshat's Hero "welcome" craft was folded into the onboarding Step 0 welcome rather than a separate route.
- `/auth/login` is the unauthenticated landing; its "New to Neko? Get started" links to register (honors "not authed → /auth/login").
- Used flat GoRoutes instead of a ShellRoute, because the home screen owns its custom nav pill per the design (a shell would duplicate chrome).
- Dropped the "personalities" concept from the old onboarding; it is not in the Firestore schema.
- Derived the user display name from the email local-part on email registration (onboarding collects the cat's name, not the owner's); Google sign-in uses the real name.
- `dailyCalorieTarget` is computed at save time from weight and activity (RER × activity factor), giving the home calorie features real data later.
- Banner stagger uses stable `ValueKey(cat.id)` so the entrance never replays on Firestore updates, instead of a separate "hasAnimated" flag.
- The flat "Duolingo depth" button shadow lives in the custom button widgets (zero-blur offset shadow), since Material elevation cannot express it.
- Generated `*.g.dart` / `*.freezed.dart` files are committed so the project compiles for judges without a build_runner step.
- Local, ephemeral view state (focus glow, press scale, password visibility) is driven by listenables/controllers, keeping Riverpod for app state only.
- `shared_preferences` was removed once the SharedPreferences-based onboarding/login flags were replaced by Firestore + Firebase auth state.
- The sleeping-cat and logo assets are 1×1 placeholders; the add-cat section falls back to a Material icon until real art is dropped in.
