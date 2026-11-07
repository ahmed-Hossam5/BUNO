# Remaining screens (round 2)

Same rules as CLAUDE.md. Reference = docs/reference/<file>.png.

## Before Week 10 (they appear in the literature review, sections 5 and 8)
| Route | Reference | What it does |
|---|---|---|
| `/splash` | 35 | buno_logo_intro plays once (~1.5 s), then onboarding or home. |
| `/permissions` | 36 | Location, notifications, camera toggles with one-line reasons; continue / later. |
| `/verify-uni` | 37 | Optional university email, "not a student? skip". |
| `/scan/methods` | 38 | Choose QR (tagged fastest), NFC, or code. |
| `/scan/nfc` | 39 | "Hold your phone near the NFC mark" with nfc animation (loop). Mock: debug "simulate tap". |
| `/verifying` | 40 | Four server checks before unlocking (code is Buno's, station online, code still valid, account and balance), shown as a list that completes; then /unlocking. |
| `/rental/unit` | 41 | The unit in hand: ID read from its RFID tag (PB-0417), charge, temperature, from station and bay, status. |
| state | 42 | QR not from Buno: warning, "report the code", "scan another". Replaces the plain scan-failed state when the QR looks like a URL that isn't Buno's. |
| `/reserve` | 43 | Reserve a unit at a station (shown when the phone is below 20%); then the existing reserved countdown (ref 34). |
| late return | 44–47 | Four stages: reminder, warning, last chance with the fee, after 24 h the unit is yours. Shown as notifications plus a banner on /rental. |
| home states | 57, 58 | Check the existing home matches: below 20% and charging from Buno. |

## After Week 10 (student features)
| `/favorites` | 48 | Saved stations with live bays. |
| `/promo` | 49 | Promo code as a ticket. |
| `/sos`, `/sos/help`, `/sos/got` | 50–52 | «إلحقني»: ask a friend to pay the first hour; the friend's view; got it. send and sos animations. |
| `/exam`, `/exam/night` | 55, 56 | Exam weeks: next exam countdown, study-night pack (fixed price placeholder), moon animation. |
