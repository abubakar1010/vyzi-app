# VYZI

Mobile app for **VYZI**, the Italian energy bill comparison and switching
platform. Personal and business users upload their electricity and gas bills,
see how much they could save, compare supplier offers, switch provider, and
refer friends.

Built with Flutter and GetX. App ID: `com.vyzi` (Android and iOS).

## Getting started

```bash
flutter pub get
flutter run
```

The app calls the VYZI backend. Point it at a server with `BASE_URL`:

```bash
flutter run --dart-define=BASE_URL=https://api.vyzi.it
```

## Commands

| Command | What it does |
|---|---|
| `flutter analyze` | Static analysis |
| `flutter test` | Unit and widget tests |
| `flutter clean && flutter pub get` | Clean rebuild |
| `cd ios && pod install` | Refresh iOS pods after dependency changes |

Release builds: see `BUILD_APK_GUIDE.md`. Google and Apple sign-in setup: see
`SOCIAL_LOGIN_SETUP.md`.

## Architecture

```
lib/
├── main.dart, app.dart   # Startup, theme, GetMaterialApp
├── routes/               # Named routes
├── core/                 # API client (Dio), cache (Hive), storage, services, shared widgets
└── features/             # auth, home, bills, my_utility, profile, support, …
```

- **State and navigation:** GetX controllers and named routes.
- **HTTP:** a Dio singleton that adds the access token and refreshes it on 401.
- **Offline-first:** responses are cached in Hive.
- **Language:** Italian by default; English is a translation. Strings live in
  `lib/core/localization/`.
