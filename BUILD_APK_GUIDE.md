# Build Guide — VYZI Android

Which artifact you build matters more than anything else for download size. A
plain `flutter build apk --release` produces a **universal APK containing all
three CPU architectures**. Every device downloads all three and runs exactly
one. Use the commands below instead.

Measured on this app, same source, same commit:

| Command | Output | Size |
|---|---|---:|
| `flutter build apk --release` | `app-release.apk` | **68.2 MB** |
| `flutter build apk --release --split-per-abi` | `app-arm64-v8a-release.apk` | **28.0 MB** |

Identical machine code. The 40 MB difference is `x86_64` (22,794,408 bytes)
and `armeabi-v7a` (19,163,980 bytes) — architectures an arm64 phone installs
and can never execute.

See `APP_SIZE_AUDIT.md` for the full breakdown.

## Step 1 — Clean and fetch dependencies

```bash
cd vyzi-app
flutter clean
flutter pub get
```

## Step 2 — Build

### For the Play Store — App Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Play generates a per-device APK from the bundle containing exactly one
architecture, one screen density and one language, so the user's download is
far smaller than the `.aab` itself. **App Bundle is mandatory for new Play
submissions** — do not upload an APK.

Keep all architectures in the bundle. `armeabi-v7a` costs nothing under
per-device delivery and 32-bit devices still exist in the Italian market.

### For client testing — one APK per architecture

```bash
flutter build apk --release --split-per-abi
```

Output:

| File | Send to |
| --- | --- |
| `app-arm64-v8a-release.apk` | **Every modern Android phone — this is the one to send** |
| `app-armeabi-v7a-release.apk` | 32-bit devices, pre-2019 |
| `app-x86_64-release.apk` | Emulators only — never send this |

⚠️ Sending the wrong file gives the client an app that will not install.
Unless they have told you otherwise, send **`app-arm64-v8a-release.apk`**.

### For client testing — a single file

Use `--split-per-abi` above and send only `app-arm64-v8a-release.apk`. That
build already produces exactly the single file you want.

> ⚠️ **Do not use `--target-platform android-arm64` for this.** It looks like
> it should work and it does not. The flag only controls Flutter's own
> artifacts (`libflutter.so`, `libapp.so`); native libraries belonging to
> plugins are packaged by the Android Gradle plugin and ignore it entirely. A
> `--target-platform android-arm64` build measured here still shipped
> `lib/x86_64/libmodpdfium.so`, `lib/armeabi-v7a/libmodpdfium.so` and both
> other-ABI copies of `libc++_shared.so` and `libmodft2.so` — about 13 MB of
> architectures the target device cannot run. Only `--split-per-abi` (and App
> Bundle delivery) actually separates them.

### Debug builds

```bash
flutter build apk --debug
```

Unchanged — debug builds keep every architecture so emulators keep working.

## Step 3 — Send to the client

Send the `.apk` via email, Google Drive, WhatsApp, Telegram, etc.

The client then:

1. Opens the APK on their Android device
2. If prompted, goes to **Settings → Install unknown apps** and allows the
   browser/file manager
3. Taps **Install**

## Step 4 — Verify what you shipped

```bash
APK=build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Must print arm64-v8a and nothing else. More than one line means you are
# shipping architectures the device cannot run.
unzip -l "$APK" | grep -o 'lib/[^/]*' | sort -u

# Composition by area.
unzip -l "$APK" | awk '$1 ~ /^[0-9]+$/ && NF>=4 {
    p=$4
    if (p ~ /^lib\//) k="native"
    else if (p ~ /^assets\/flutter_assets\/assets\//) k="our assets"
    else if (p ~ /\.dex$/) k="dex"
    else k="other"
    s[k]+=$1
  } END {for (x in s) printf "%-12s %10.2f MiB\n", x, s[x]/1048576}'
```

After changing anything about minification or ABIs, run `flutter clean` first.
Flipping `isMinifyEnabled` changes the whole dex pipeline and AGP's incremental
state does not always invalidate correctly — an unclean build after that change
was measured here producing **2.4x the dex** it should have, by packaging an
unminified copy of the classes alongside the R8 output.

## Signing

Release builds are signed with the key described in `android/key.properties`
(git-ignored). See the comment block at the top of
`vyzi-app/android/app/build.gradle.kts` for its format.

Without that file the build **falls back to the debug key** and prints a
warning. That still installs, but Google Sign-In only works if the debug SHA-1
is registered in the Firebase console, and it can never be submitted to Play.

## Important notes

- Check that `ApiConstants.baseUrl` in
  `lib/core/constants/api_constants.dart` points at the production/staging
  server, not `localhost` — otherwise the app cannot connect from the client's
  device.
- Do not go back to a plain `flutter build apk --release`. It is the fat
  universal APK this guide exists to avoid.
