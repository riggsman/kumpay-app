# KumPay Mobile — UI/UX Kit

A standalone Flutter UI kit for the KumPay **client** mobile app. It covers the
31 POC artboards plus registration, KYC and the supporting money-move flows.
The admin/backoffice remains out of scope.

## Run it

Flutter is not installed in the original workspace. Once the SDK is on `PATH`:

```powershell
flutter create --platforms=web,android,ios .
flutter pub get
flutter run -d chrome   # or: flutter run -d windows / an attached device
```

`flutter create .` only adds the missing platform shells; it leaves `lib/` and
`pubspec.yaml` in place.

## What is inside

| Folder | Purpose |
| --- | --- |
| `lib/app.dart`, `lib/main.dart` | Gallery entry point (`KumPayUiKitApp`) |
| `lib/gallery/gallery.dart` | Browsable index of every artboard |
| `lib/preview/preview_page.dart` | 390×844 phone frame + `kpOpen` route |
| `lib/theme/kp_theme.dart` | KumPay colours, type, radii, shadows |
| `lib/data/demo.dart` | Demo user, transactions, billers, formatting |
| `lib/widgets/` | Shared shell, brand, controls, finance, nav, visuals |
| `lib/screens/auth/` | Login, OTP, device verification, help, error states |
| `lib/screens/kyc/` | Identity verification states |
| `lib/screens/home/` | Home dashboard |
| `lib/screens/wallet/` | Wallet, top-up/withdraw, transfer, history |
| `lib/screens/bills/` | Biller hub, payment, receipt |
| `lib/screens/cards/` | USD virtual card, freeze/reveal/limits |
| `lib/screens/profile/` | Profile, notifications, language, PIN change |

### Artboards

1. Login · 2. Change phone · 3. OTP sent · 4. Verify OTP · 5. OTP keypad ·
6. Incorrect OTP · 7. Code expired · 8. Too many attempts · 9. OTP resent ·
10. Confirm device · 11. Device details · 12. Device changed · 13. Signed out
elsewhere · 14. Help · 15. Security tips · 16. Device failed · 17. Sending OTP ·
18. Verifying OTP · 19. Resend ready · 20. Secure account · 21. Invalid number ·
22. Network error · 23. Home · 24. Wallet · 25. Send money · 26. Transfer sent ·
27. Pay bills · 28. Bill payment · 29. Transactions · 30. Virtual card ·
31. Profile.

Added: create account, KYC intro/form/submitted/rejected/approved, notifications,
language, change PIN, add money/withdraw and card funding.

## Brand

- Forest green `#1F4438`, deep `#123026`, cream `#F8F5EC`, gold `#E9B63C`
- Manrope for UI text, Bricolage Grotesque for display headings
- 390 × 844 iPhone-class frame, 22 px page gutters, 18–24 px card radii
- Cameroon content: XAF/FCFA, ENEO, CAMWATER, Canal+, DStv, MTN MoMo, Orange Money

## Design decisions

- **Phone-first auth.** No passwords. The six-digit OTP is the only credential;
  the UI mirrors the AUTH-1…10 contract.
- **KYC is a client state, not a formality.** Unverified users can explore the
  home screen but banners and locked actions route to KYC.
- **One card per currency.** The USD card is shown; the XAF upsell demonstrates
  the 600 FCFA fee and “one free creation” allowance (CARD-2…5).
- **Read-only client alerts.** The notification detail sheet never edits content.
  Staff escalation lives in the backoffice app.
- **PIN change is three steps.** Current PIN → OTP → new PIN, matching PIN-1.
- **Demo-only interactions.** Upload tiles, freeze, reveal, filters and receipts
  are local state. No network calls, secrets or real money.

## Wiring to the backend

`lib/data/demo.dart` is the only source of sample data. Replace it with API
clients for:

- `/api/auth/otp/request`, `/api/auth/otp/verify`, `/api/auth/me`
- `/api/kyc/requests` and document upload
- `/api/cards` and `/api/admin/cards/:id/credit`
- wallet/transactions/billers endpoints (not yet present in the backend spec)

Keep every rule server-side: OTP delivery order, 6-month phone cooldown, KYC
decisions, card limits, refund four-eyes and role permissions must never be
decided in this client.

## Platform feature flags

Send, top up, withdrawal, billers (school fees, ENEO, CAMWATER, Canal+, DStv
and the rest), biometrics and the extra sign-in check are hidden the moment
the platform turns them off, and shown again when it turns them on. Every
money movement is also checked for verification, limits and permission before
it is submitted.

The methods the backend has to expose are written in [FEATURE_FLAGS.md](FEATURE_FLAGS.md).

## Notes

- `google_fonts` fetches Manrope/Bricolage at runtime. For offline builds, add
  the font files under `assets/fonts` and switch to `fontFamily`.
- Some controls use Flutter 3.27+ APIs (`Color.withValues`). On an older SDK,
  replace them with `withOpacity`.
- No generated platform folders are committed, so `flutter create .` is required
  before running.
