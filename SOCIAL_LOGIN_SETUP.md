# Social Login Setup Guide

Complete step-by-step guide to configure Google and Apple Sign-In for the VYZI mobile app.

**Prerequisites:** Accounts on [Firebase Console](https://console.firebase.google.com) and [Apple Developer](https://developer.apple.com).

---

## Part 1: Firebase Project Setup

### Step 1: Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **"Add project"**
3. Name it (e.g. `VYZI`)
4. Disable Google Analytics (optional, not needed for auth)
5. Click **Create project**

### Step 2: Register the Android App

1. In Firebase Console, click **"Add app"** → Android icon
2. Enter package name: **`com.vyzi`** (must match `android/app/build.gradle.kts` applicationId)
3. Enter app nickname: `VYZI Android`
4. Skip the SHA-1 for now (we'll add it next)
5. Click **Register app**
6. **Download `google-services.json`**
7. Place it at:

```
vyzi_app/android/app/google-services.json
```

### Step 3: Add SHA-1 Fingerprint (Required for Google Sign-In on Android)

Run this in the terminal to get your debug SHA-1:

```bash
cd vyzi_app/android && ./gradlew signingReport
```

Look for the **SHA1** line under `Variant: debug`. Then:

1. Go to Firebase Console → Project Settings → Your Android app
2. Click **"Add fingerprint"**
3. Paste the SHA-1 value
4. Save

> For release builds, also add the SHA-1 from your release keystore.

### Step 4: Register the iOS App

1. In Firebase Console, click **"Add app"** → iOS icon
2. Enter the bundle ID from your Xcode project
3. Enter app nickname: `VYZI iOS`
4. Click **Register app**
5. **Download `GoogleService-Info.plist`**
6. Place it at:

```
vyzi_app/ios/Runner/GoogleService-Info.plist
```

### Step 5: Enable Authentication Providers in Firebase

1. Go to Firebase Console → **Authentication** → **Sign-in method**
2. Enable these two providers:

**Google:**

- Click Google → Enable → Set a support email → Save

**Apple:**

- Click Apple → Enable → Save

---

## Part 2: iOS-Specific Setup

### Step 6: Set Google Sign-In URL Scheme

1. Open `ios/Runner/GoogleService-Info.plist`
2. Find the `REVERSED_CLIENT_ID` value (looks like `com.googleusercontent.apps.123456789-abcdef`)
3. Open `ios/Runner/Info.plist`
4. Replace `com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID` with the actual value from step 2

### Step 7: Add Apple Sign-In Capability in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **"+ Capability"**
5. Search for **"Sign in with Apple"** and add it
6. Make sure your **Team** is set and signing works

### Step 8: Install CocoaPods

```bash
cd ios && pod install && cd ..
```

---

## Part 3: Backend Configuration

### Step 9: Get Firebase Admin SDK Credentials

1. Go to Firebase Console → **Project Settings** → **Service accounts**
2. Click **"Generate new private key"** → Download the JSON file
3. Open the JSON file and extract these three values:
   - `project_id`
   - `client_email`
   - `private_key`

### Step 10: Update Backend `.env`

In `vyzi_backend/.env`, set:

```env
FIREBASE_PROJECT_ID=your-actual-project-id
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEv...your-key-here...\n-----END PRIVATE KEY-----\n"
```

Then restart the backend server:

```bash
cd vyzi_backend && npm run start:dev
```

---

## Part 4: Verify Everything

### Pre-Run Checklist

| Item | Location | Done |
|------|----------|------|
| `google-services.json` placed | `android/app/google-services.json` | |
| `GoogleService-Info.plist` placed | `ios/Runner/GoogleService-Info.plist` | |
| SHA-1 fingerprint added in Firebase | Firebase Console → Android app settings | |
| `REVERSED_CLIENT_ID` in `Info.plist` | `ios/Runner/Info.plist` (Google URL scheme) | |
| Apple Sign-In capability in Xcode | Xcode → Runner → Signing & Capabilities | |
| CocoaPods installed | `ios/Podfile.lock` exists | |
| Firebase Auth providers enabled | Firebase Console (Google, Apple) | |
| Backend `.env` Firebase credentials set | `vyzi_backend/.env` | |
| Backend server restarted | Running with new Firebase config | |

### Run the App

```bash
flutter clean && flutter pub get && flutter run
```

### Test Each Provider

1. **Google Sign-In:** Tap "Accedi con Google" → Google account picker → select account → should land on home screen
2. **Apple Sign-In (iOS only):** Tap "Accedi con Apple" → Face/Touch ID prompt → should land on home screen
3. **Session persistence:** After social login, kill and reopen the app → should stay logged in
4. **Logout:** Sign out → should clear social session and redirect to sign-in screen
5. **Account linking:** Register with email first, then sign in with social using the same email → should log into the same account

---

## Troubleshooting

### Google Sign-In fails on Android

- Verify SHA-1 fingerprint is added in Firebase Console
- Make sure `google-services.json` is at `android/app/google-services.json`
- Run `flutter clean && flutter pub get` and rebuild

### Apple Sign-In not appearing

- Only works on iOS 13+ and real devices (not simulator for some cases)
- Verify "Sign in with Apple" capability is added in Xcode
- Must have a valid Apple Developer Team selected

### Backend returns "Firebase is not configured"

- Check that `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, and `FIREBASE_PRIVATE_KEY` are set in `.env`
- The `FIREBASE_PRIVATE_KEY` must have `\n` for newlines and be wrapped in double quotes
- Restart the backend after changing `.env`

### Build fails with minSdk error

- The `minSdk` is set to 23 in `android/app/build.gradle.kts` — do not lower it below 23
