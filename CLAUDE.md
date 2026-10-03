# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**VYZI** — A Flutter bill-saving / utility management app. Users can manage bills, compare supplier offers, track agreements, and refer friends. The app uses an offline-first architecture with GetX for state management and navigation.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d android

# Static analysis
flutter analyze

# Run tests
flutter test

# Clean rebuild
flutter clean && flutter pub get && flutter run

# iOS pod install (after dependency changes)
cd ios && pod install && cd ..
```

## Commit Guideline

- never use `Co-Authored-By: Claude` or something like this.
- always commit and push after your work
- commit message should be in the format: `feat: add new feature` or `fix: fix bug` etc.
- use conventional commits.
- never commit everything at once, do commit for each feature, module or fix. always follow conventional commits, principles and standards. always make sure your changes are tested before committing.

## Architecture

**Clean Architecture + Repository Pattern + GetX**

```
lib/
├── main.dart              # Entry: init CacheService, StorageService, fonts, orientation
├── app.dart               # GetMaterialApp, theme (Open Sans), ScreenUtil (392x876)
├── routes/app_routes.dart # All route constants + GetPage list
├── core/                  # Shared infrastructure
│   ├── constants/api_constants.dart  # Base URL, endpoints, cache keys
│   ├── services/          # ApiService (Dio singleton), CacheService (Hive),
│   │                      # ConnectivityService, StorageService (SharedPreferences), AuthService
│   ├── di/                # DependencyInjection (currently commented out, DI done in main)
│   ├── exceptions/        # Typed AppException hierarchy
│   ├── helpers/           # SharedPrefHelper
│   ├── widgets/           # Reusable UI: buttons, text fields, dropdowns, pin code
│   ├── navbar/            # Bottom navigation bar (NavbarController + screen)
│   └── utils/             # AppColors
└── features/              # Feature modules
    ├── auth/              # Sign in, register, OTP, forgot/reset password
    ├── home/              # Home screen with controllers, models, widgets
    ├── profile/           # Profile, settings, agreements, invite friends
    ├── onboarding/        # Onboarding + warmup screens
    ├── splash/            # Splash screen
    ├── utility/           # Utility management
    ├── my_utility/        # User's utilities
    ├── request/           # Request handling
    └── support/           # Support features
```

## Key Patterns

- **State Management**: GetX (`GetxController`, `Rx` observables, `Obx` widgets)
- **Navigation**: GetX named routing via `AppRoutes.page` list in `routes/app_routes.dart`
- **HTTP**: Dio singleton with auto-token injection and 401 refresh interceptor (`core/services/api_service.dart`)
- **Local Storage**: Hive for cache (`CacheService`), SharedPreferences for tokens/settings (`StorageService` with `StorageKeys`)
- **Responsive Sizing**: `flutter_screenutil` with design size 392x876 — use `.w`, `.h`, `.sp`, `.r` extensions
- **Font**: Google Fonts Open Sans (configured in theme)

## API

- Base URL: `ApiConstants.baseUrl` in `lib/core/constants/api_constants.dart`
- Auth token stored via `StorageKeys.authToken` in StorageService
- Token auto-injected by ApiService interceptor on every request
- 401 responses trigger automatic token refresh via `/api/v1/auth/refresh-token`

## Adding a New Feature

1. Create feature directory under `lib/features/<feature_name>/`
2. Add model classes with `fromJson()` / `toJson()` and safe getters
3. Create controller extending `GetxController`
4. Add route constant to `AppRoutes` and `GetPage` entry to `AppRoutes.page`
5. Register dependencies (either in route binding or via `Get.lazyPut`)

## Social Sign-In (Google / Apple)

`core/services/social_auth_service.dart` runs the provider flow, then exchanges
the Firebase ID token at `POST /api/v1/auth/social-login`.

- `GoogleSignIn.initialize()` must run **exactly once per process** — the guard
  is the static `_googleInit` future, not per-instance state (`SocialAuthService`
  is constructed per `AuthController`, and controllers are recreated on route
  changes).
- **Google identifies the app by package name + the SHA-1 of the signing
  certificate.** Every build machine's debug SHA-1 and the release SHA-1 must be
  registered for `com.vyzi` in the Firebase console, and `google-services.json`
  re-downloaded afterwards. Get the fingerprints with
  `cd android && ./gradlew :app:signingReport`. An unregistered SHA-1 is the
  usual cause of Google sign-in failing, and Credential Manager often reports it
  as a *user cancellation* — read the `SocialAuthService` logs before believing
  that. See `../FIREBASE_SETUP_GUIDE.md` section 7.
- Release builds read their keystore from `android/key.properties` (git-ignored);
  without it they fall back to the local debug key and Google sign-in breaks.
- Cancellation is `SocialAuthCancelledException`, a real failure is
  `SocialAuthException` — never match on message text.

## Notes

- The `DependencyInjection` class in `core/di/` is fully commented out — services are currently initialized directly in `main.dart`
- Many routes in `app_routes.dart` are commented out (features in progress)
- App is portrait-only
- Design base for ScreenUtil is 392x876 (not the standard 375x812)
