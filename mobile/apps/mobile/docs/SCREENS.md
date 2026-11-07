# Screens still to build

Reference image = `docs/reference/<file>.png`. Mock data only; nothing is sent anywhere.

## A. Rental loop (Week 10 demo — build first)
| Route | Reference | What it does |
|---|---|---|
| `/scan` | 01_scan | Camera QR scan (`mobile_scanner`). Torch button, "type the station code" link. In debug, a "simulate scan" button. |
| `/scan/code` | 02_scan_manual_code | 6 code cells (`BUN-01` style), Continue. |
| `/station` | 03_station | Station name, 8 bays with charge (green ≥50, amber 20–49, red <20, grey empty), price rows, "take the 92%" CTA. |
| `/confirm` | 04_confirm | Charge of the unit, first hour / per minute / daily cap / non-return fee rows, "unlock the bay". If balance too low → 05_low_balance_sheet as bottom sheet. |
| `/unlocking` | 06_unlocking | 4 stages animate in sequence (sent → station received → lock opening → take the unit), ~0.8 s each in the mock. Note: nothing is charged until the unit is out. |
| `/release` | 07_release | Huge bay number in a green square, "I took it" → starts the existing `/rental` timer. |
| `/rental` (exists) | — | Add: hour-warning sheet (08) at 50 min, "report a problem" (09). |
| `/return` | 10_return_how | Lit bay illustration, "take me to the nearest station", "station won't accept". |
| `/return/done` | 11_done | `success` animation, then receipt. |
| `/receipt` | 12_receipt | Paid, from/to, duration, rows, 5-star rating, PDF button. |

## B. Tabs
| Route | Reference | What it does |
|---|---|---|
| `/stations` (رحلاتي tab slot or map) | 13_map, 14_stations_list | Map with charge pins + list with filters. |
| `/history` (رحلاتي tab) | 15_history, 33_state_no_history | Past rentals; empty state. |

## C. Wallet
| `/topup` | 16_topup | Amount chips 50/100/200/500, method (Vodafone Cash, InstaPay, cash at venue). |
| `/topup/transfer` | 17_transfer | Number to transfer to, upload receipt, reference number. |
| `/topup/pending` → done | 18, 19 | Pending, then balance counts up with `success`. |

## D. Account
| `/notifications` | 20 | · | `/settings` | 21 (reduce motion, language) | · | `/profile/edit` | 22 | · | `/help` | 23 (`chat_typing`) | · | `/plans` | 24 | · | `/referral` | 25 (`copy`, `gift`) |

## E. Hard states (reusable `BunoEmptyState` widget)
26 no internet · 27 offline unlock code (rotates every 30 s) · 28 scan failed · 29 bay didn't open · 30 station full · 31 top-up declined · 32 loading skeleton · 33 no history · 34 reserved (countdown).
Every error says: what happened, what happened to the money, and one next step.
