# Buno

An 8-bay power bank rental station for university campuses (graduation
project, ElSewedy University of Technology, 2026).

This is a **monorepo**: one git repository and one Dart pub workspace for
every part of Buno.

```
apps/
  mobile/          Flutter app (Arabic, RTL, dark). See apps/mobile/README.md
  server/          Backend: a modular monolith on shelf
packages/
  buno_shared/     API contract shared by app and server (paths, DTOs, rules)
pubspec.yaml       Workspace root: one `pub get`, one pubspec.lock
```

## Getting started

```bash
flutter pub get                          # once, at the root, for every member
cd apps/mobile && flutter run            # the app
cd apps/server && dart run bin/server.dart   # the API on :8080 (PORT to change)
```

Tests run per member: `flutter test` in `apps/mobile`, `dart test` in
`apps/server` and `packages/buno_shared`.

## Server: modular monolith

One process and one deployable, split inside into modules that each own
their data and routes:

| Module | Routes | Depends on |
|---|---|---|
| auth | `POST /v1/auth/code`, `POST /v1/auth/verify` | — |
| stations | `GET /v1/stations`, `GET /v1/stations/<code>` | — |
| wallet | `GET /v1/wallet` | — |
| rentals | `POST /v1/rentals`, `GET /v1/rentals/current`, `POST /v1/rentals/<id>/return` | stations, wallet |
| promo | `GET /v1/promo/offers`, `POST /v1/promo/redeem` | — |
| favorites | `GET /v1/favorites`, `PUT`/`DELETE /v1/favorites/<code>` | stations |

Rules:

- Each module lives in `apps/server/lib/src/modules/<name>/`. Its `api.dart`
  is the public face (module class and service interface); `internal/` is
  private. `test/module_boundaries_test.dart` fails if a module imports
  another module's `internal/` files.
- Modules get their dependencies as interfaces (`StationsApi`, `WalletApi`)
  in the composition root, `lib/buno_server.dart`. Nothing else wires them.
- Signed-in routes are wrapped with `context.authed`; send
  `Authorization: Bearer <token>` from `/v1/auth/verify`.
- Data is in memory and mirrors the app's mocks. Any 4-digit code signs in,
  and prices stay placeholders, like the app.

A module can later move to its own service by putting an HTTP client behind
the same interface.
