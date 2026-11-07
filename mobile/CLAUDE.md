# Buno — project memory for Claude Code

Buno is an 8-bay power bank rental station for university campuses (graduation project, ElSewedy University of Technology, 2026). This repo is a monorepo (one Dart pub workspace): `apps/mobile` the Flutter app (Arabic first, right-to-left, dark theme), `apps/server` the backend as a modular monolith (shelf), `packages/buno_shared` the API contract both use. See README.md.

## Commands
- `flutter pub get` at the repo root resolves every member (one `pubspec.lock` at the root).
- App, from `apps/mobile`: `flutter analyze` · `flutter test test/<file>_test.dart` (run only the test you touched) · `flutter run --route /<name>` opens one screen directly
- Server, from `apps/server`: `dart analyze` · `dart test` · `dart run bin/server.dart`

## Server rules
- One module per domain in `apps/server/lib/src/modules/<name>/`: `api.dart` is public, `internal/` is private. Modules use each other only through `api.dart` interfaces, wired in `lib/buno_server.dart` (`test/module_boundaries_test.dart` enforces it).
- New routes and DTOs go in `packages/buno_shared` first (`ApiPaths`, `dtos.dart`), then the module.
- Same mock rules as the app: in-memory data, placeholder prices.

## Where things are (app; paths relative to `apps/mobile/`)
- `lib/app_routes.dart` route table + bottom-nav tabs (`tabs` list; `null` = tab not built)
- `lib/theme/buno_tokens.dart`, `buno_tokens_ext.dart` colours, type, sizes, motion. Never hard-code a colour or size that a token covers.
- `lib/widgets/` reusable pieces. Reuse before creating: `BunoText` (Arabic text, numbers in Sora isolated LTR), `buno_buttons.dart`, `BunoIcon` (SVG, sizes 18/22/28), `BunoChargeRing`, `BunoChargeBar`, `BunoStationCard`, `BunoBottomNav`, `BunoTabHeader`, `BunoBackButton`, `BunoTextField`, `BunoChip`, `BunoStatusPill`, `BunoPressable`.
- `lib/data/` mocks: `mock_auth.dart`, `phone_battery.dart` (battery_plus). New mocks go here.
- `assets/lottie/` 48 animated icons (see `docs/ANIMATIONS.md`).
- `docs/reference/` one PNG per screen still to build (layout + copy reference, see `docs/SCREENS.md`).

## App rules
- Match the look of the screens already built (home, wallet, profile, active rental). Reference PNGs show layout and content, not exact styling.
- Arabic (RTL, default) and English (LTR), switched in Settings. Every user-facing string is `tr('عربي', 'English')` from `lib/l10n/buno_locale.dart`; `const` data (enums, mock lists) uses `Tr('عربي', 'English')` and a getter. Use directional layout (`EdgeInsetsDirectional`, `AlignmentDirectional`), never hard-coded left/right. `test/english_test.dart` fails on any Arabic left on an English screen.
- Numbers and prices through `BunoText` so they stay LTR.
- Prices stay as placeholders exactly like the existing screens: `[السعر]`, `[الرصيد]`, `[المدة]`. Never invent prices.
- One primary button per screen, at the bottom.
- Respect reduced motion: if `MediaQuery.of(context).disableAnimations` is true, show the last frame of an animation instead of playing it.
- No new packages unless the prompt names them.
- Every new screen gets a route in `app_routes.dart` and a test in `test/` that pumps it at the 6 phone sizes used in `home_screen_test.dart` (no overflow, RTL).
- Don't refactor or reformat files the task doesn't touch.

## Working style (saves tokens)
- Read only the files the task names, plus what they import if needed.
- Don't paste full files back in chat; reply with a short list of files changed and what to check.
- If something is unclear, ask one question before writing code.
