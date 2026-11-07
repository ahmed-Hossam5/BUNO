# Buno

Flutter app for Buno, an 8-bay power bank rental station for university
campuses. Arabic first, right-to-left, dark theme. Everything runs on local
mocks (`lib/data/`): nothing is sent anywhere, any 4-digit code passes, and
prices stay as placeholders (`[السعر]`, `[الرصيد]`, `[المدة]`).

## Screens

Reference numbers are the PNGs in `docs/reference/` (or Brand Board pages
for the first screens).

| Screen | Reference | Route |
|---|---|---|
| Home (map, nearest station, scan CTA) | Board 7 | `/` |
| Splash (logo intro) | 35 | `/splash` |
| Onboarding (3 slides) | Board 1–3 | `/onboarding` |
| Login (e-mail or Sign in with Apple) | Board 4 | `/login` |
| Sign-up | Board 5 | `/signup` |
| Code verification | Board 6 | `/verify` |
| Permissions | 36 | `/permissions` |
| University e-mail (optional) | 37 | `/verify-uni` |
| Reserve a bay (phone low) | 43 | `/reserve` |
| Reserved (countdown) | 34 | `/reserved` |
| Scan QR (scan-failed state on a non-Buno QR) | 01, 28 | `/scan` |
| Type the station code | 02 | `/scan/code` |
| Scan methods (QR, NFC, code) | 38 | `/scan/methods` |
| NFC tap | 39 | `/scan/nfc` |
| Station: bays and best unit (heart, "i") | 03 | `/station` |
| Station info (hours, return bays, directions) | 84 | `/station/info` |
| Confirm unlock (low-balance sheet) | 04, 05 | `/confirm` |
| Verifying checks | 40 | `/verifying` |
| Unlocking stages (bay-stuck state) | 06, 29 | `/unlocking` |
| Bay open, take the unit | 07 | `/release` |
| Active rental timer (hour-warning sheet) | Board 10, 08 | `/rental` |
| The unit in hand (tag, charge, temperature) | 41 | `/rental/unit` |
| Report a problem | 09 | `/report` |
| How to return (station-full state) | 10, 30 | `/return` |
| Returned | 11 | `/return/done` |
| Receipt (rate sheet at 3 stars or less) | 12, 64 | `/receipt` |
| Stations map / list (loading skeleton) | 13, 14, 32 | `/stations` |
| Trip history, رحلاتي tab (skeleton, empty state) | 15, 32, 33 | `/history` |
| Top-up amount and method | 16 | `/topup` |
| Transfer details and receipt photo | 17 | `/topup/transfer` |
| Top-up under review (declined state) | 18, 31 | `/topup/pending` |
| Top-up done | 19 | `/topup/done` |
| Wallet | Board 12 | `/wallet` |
| Profile | — | `/profile` |
| Notifications | 20 | `/notifications` |
| Settings | 21 | `/settings` |
| Edit profile | 22 | `/profile/edit` |
| Help | 23 | `/help` |
| Plans | 24 | `/plans` |
| Referral | 25 | `/referral` |
| No internet | 26 | `/offline` |
| Offline unlock code | 27 | `/offline-code` |
| Favorite stations (empty state) | 48, 65 | `/favorites` |
| Discount code | 49 | `/promo` |
| «إلحقني»: ask a friend, friend's side, paid | 50, 51, 52 | `/sos`, `/sos/help`, `/sos/got` |
| Exam-week home, study night | 55, 56 | `/exam`, `/exam/night` |

The bottom nav switches Home / رحلاتي / Wallet / Profile.

## Demo path

Run a debug build (`flutter run`): the "تجربة: …" links and the
"محاكاة مسح (ديباج)" button only exist in debug, never in release.

**Full loop** (the mock wallet starts with enough balance):

1. Home: tap **امسح وخد بونو** → /scan.
2. /scan: tap **محاكاة مسح (ديباج)** (or point at a QR containing `BUN-01`,
   or "مش راضي يمسح؟ اكتب الكود" and type `BUN-01`) → /station.
3. /station: tap **خد الـ …%** (best unit) → /confirm.
4. /confirm: tap **تمام، افتح الخانة** → /unlocking runs its four stages by
   itself → /release.
5. /release: tap **خدتها** → /rental (timer running).
6. /rental: tap **رجّعه** → /return.
7. /return: tap **تجربة: حطيته في الخانة** → /return/done.
8. /return/done: tap **شوف الإيصال** → /receipt.
9. /receipt: tap **تمام** → back to Home. The trip now shows in رحلاتي.

**Hard states:**

| State | How to show it |
|---|---|
| Scan failed (28) | On /scan, show the camera any QR without a `BUN-xx` code. |
| Bay didn't open (29) | On /unlocking, tap **تجربة: الخانة علقت** (step 4 above). |
| Station full (30) | On /return, tap **تجربة: المحطة مليانة** (step 7 above). |
| Top-up declined (31) | Wallet → **اشحن** → **كمّل** → type any reference number (رقم العملية) → **ابعت للمراجعة**; on /topup/pending tap **تجربة: التحويل اترفض**. |
| No internet (26) → offline code (27) | Profile → Settings → turn on **تجربة: من غير نت**, then tap Home's scan button (or **تمام، افتح الخانة** on /confirm). On /offline tap **افتح بكود من غير نت**. Turn the switch off afterwards. |
| Loading skeleton (32) | Open /stations (Home → **وريني كل المحطات القريبة**) or the رحلاتي tab; it shows for 600 ms. |
| No history (33) | Pumped in tests with an empty session; the mock always has seed trips, so use `flutter test test/stations_history_test.dart` or a screenshot. |
| Hour warning (08) | On /rental, tap **تجربة: تنبيه الساعة**. |

```bash
flutter pub get
flutter run                    # Home
flutter run --route /login     # any route above (web: open /#/login)
flutter test                   # overflow + RTL at 6 phone sizes (and text scale 1.3), labels, interactions
```

## Layout

```
lib/
  main.dart                         MaterialApp, Arabic locale (RTL), dark theme
  app_routes.dart                   route table, tab navigation
  data/mock_auth.dart               mocked sign-in / sign-up / code check
  data/phone_battery.dart           live phone battery (battery_plus)
  theme/buno_tokens.dart            supplied Flutter tokens (verbatim)
  theme/buno_tokens_ext.dart        size / stroke / motion / type tokens from tokens.css + typography.md
  widgets/                          reusable pieces
    buno_icon.dart                  supplied SVG icons, sizes locked to 18 / 22 / 28
    buno_logo.dart                  supplied logo SVG
    buno_text.dart                  Arabic text with numbers in Sora, isolated LTR
    buno_buttons.dart               primary CTA + secondary button
    buno_search_field.dart
    buno_chip.dart
    buno_station_card.dart          station info card
    buno_charge_ring.dart           charge ring (12 o'clock, clockwise, glow)
    buno_charge_bar.dart            8pt power-bank charge bar
    buno_status_pill.dart           outlined status pill
    buno_page_dots.dart             page indicator (RTL reading order)
    buno_text_field.dart            input, checkbox, text link, "or" divider, OTP cells
    buno_back_button.dart           41pt outlined back button (44pt target)
    buno_tab_header.dart            tab-screen header + section title
    buno_dashed_button.dart         dashed "add" button
    buno_bottom_nav.dart
    map_markers.dart                station / selected station / user markers
  screens/home/
    home_screen.dart                composition + bottom sheet
    home_top_bar.dart               logo, battery pill, profile button
    mock_map.dart                   local mock map (no maps SDK)
  screens/onboarding/
    onboarding_screen.dart          3-slide PageView, skip, CTA, "have an account"
    onboarding_illustrations.dart   the three disc illustrations, drawn in code
  screens/auth/                     login, sign-up, code verification, shared frame,
                                    Sign in with Apple button
  screens/wallet/                   balance card, payment methods, transactions
  screens/profile/                  user card, account/help menus, logout
  screens/rental/
    active_rental_screen.dart       timer ring, cost rows, nearest station, actions
assets/app_icon/                    supplied app-icon PNGs (source for the launcher icons)
assets/                             supplied SVGs + Sora / Readex Pro TTFs;
                                    assets/brand/apple-logo.svg is Simple Icons (CC0)
docs/                               screenshots
```

## Accessibility

- **Contrast:** secondary text (`#8B918C`) is 6.2:1 on the background and
  5.2:1 on the lightest card, above WCAG AA (4.5:1).
- **Haptics:** a light tap on the primary button (including **خدتها** on
  /release) and on a bay tile in /station.
- **Motion:** the rental flow (/scan through /receipt) shares one page
  transition, a fade with a slight rise; tabs switch instantly. With the
  system's reduce-motion setting on, the transition is skipped and
  animations show their last frame.
- **Screen readers:** every tappable control, icon-only ones included, has
  an Arabic label.
- **Large text:** every screen fits at text scale 1.3 on all six test sizes;
  button labels shrink rather than overflow.

`test/accessibility_test.dart` opens every route at the 6 phone sizes with
text scale 1.3 and fails on any overflow or unlabelled tap target.

## App icon

Generated from the supplied `buno-design-system/app-icon` files with
`dart run flutter_launcher_icons` (config in `pubspec.yaml`):

- **iOS** — the supplied 1024 icon flattened onto its own `#0A0A0B`
  background (`assets/app_icon/buno-app-icon-1024-square.png`), because the
  App Store rejects transparency and iOS applies its own rounded mask.
- **Android** — adaptive icon: supplied foreground on `#0A0A0B`, no extra
  inset (the art already sits in the safe zone); the supplied rounded icon
  for legacy launchers.
- **Web** — the supplied 192/512 PNGs, maskable icons from the square
  version, and the supplied green favicon.

Preview: `docs/app_icon_preview.png`. After regenerating, revert the
`ios/Runner.xcodeproj/project.pbxproj` edit the tool makes
(it sets `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
to `AppIcon`, which is a bug).

## Phone battery (Home header)

The battery pill on Home shows the phone's real charge, read with
[`battery_plus`](https://pub.dev/packages/battery_plus) in
`lib/data/phone_battery.dart`:

- updates immediately when the phone is plugged in or unplugged, every 30 s
  while the app is open, and whenever the app returns to the foreground;
- orange with the low-battery icon at 20% or less, mint otherwise; the full
  icon at 80%+; the charging bolt while charging;
- shows `--%` when the battery can't be read: the **iOS Simulator has no
  battery** (use a real iPhone), and Safari/Firefox don't expose the
  browser Battery API.

No permissions are needed on Android or iOS. States: `docs/battery_states.png`.
