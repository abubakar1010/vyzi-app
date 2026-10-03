# App Size Audit — VYZI

**Audited:** 26 August 2026 · **Flutter:** 3.44.9 stable · **applicationId:** `com.vyzi`
**Artifact:** `build/app/outputs/flutter-apk/app-release.apk` — 129,228,573 bytes, built 21 Aug 2026

> This document was analysis only. No code, configuration, or assets were changed in producing it.
> All sizes are binary megabytes (MiB).

> **Implemented 1 September 2026.** All five phases have landed. See
> [§9 Outcome](#9-outcome--what-actually-happened) for measured results, three
> places where this document's method or projections turned out to be wrong,
> and what is still open.

---

## 1. Summary

The release APK is **123.2 MB**. About **93 MB of that is removable**, bringing it to roughly **30 MB**.

Two facts explain almost the entire problem:

1. **The APK ships three CPU architectures.** Every device downloads all three and installs exactly one. Native libraries are 72% of the package, and the largest single slice — `x86_64`, at 34.4 MB — runs only on emulators.
2. **Roughly half the bundled artwork is never displayed.** 67 of 146 asset files (12.4 MB) are not referenced anywhere in `lib/`. The ones that *are* used are 2–3× larger than any phone screen needs, and all 146 are PNG.

Neither is Flutter being heavy. Both are configuration and hygiene, and each phase below is independently shippable and revertable.

| | Size | Notes |
|---|---:|---|
| Today | **123.2 MB** | Universal release APK |
| After phase 1 (config only) | **~65 MB** | No application code touched |
| After all five phases | **~30 MB** | Play Store download smaller again |
| Reduction | **~76%** | |

---

## 2. How this was measured

Every figure in this document comes from one of these commands. They are reproducible against any build.

```bash
cd bill_saving_app

# APK composition, grouped by area
unzip -l build/app/outputs/flutter-apk/app-release.apk \
  | awk '$1 ~ /^[0-9]+$/ && NF>=4 {
      p=$4
      if (p ~ /^lib\//) k="lib/"
      else if (p ~ /^assets\/flutter_assets\/assets\//) k="your assets"
      else if (p ~ /^assets\/flutter_assets\//) k="engine/package assets"
      else if (p ~ /\.dex$/) k="dex"
      else k="other"
      s[k]+=$1; c[k]++
    } END { for (x in s) printf "%12d  %5d files  %s\n", s[x], c[x], x }' \
  | sort -rn

# Native library weight per ABI
unzip -l build/app/outputs/flutter-apk/app-release.apk \
  | awk '/lib\// {split($4,a,"/"); s[a[2]]+=$1} END {for (k in s) print s[k], k}' \
  | sort -rn

# Largest entries of any kind
unzip -l build/app/outputs/flutter-apk/app-release.apk | sort -rn | head -40

# Assets present on disk but never named anywhere in lib/
while IFS= read -r -d '' f; do
  grep -rqF "$(basename "$f")" lib/ || printf '%9d  %s\n' "$(stat -c%s "$f")" "$f"
done < <(find assets -type f -print0) | sort -rn

# Byte-identical duplicate assets
find assets -type f -print0 | xargs -0 md5sum \
  | sed 's/^\([0-9a-f]*\) \*\?/\1|/' | sort \
  | awk -F'|' '{if($1==p) print prev" == "$2; p=$1; prev=$2}'

# Packages declared in pubspec.yaml but never imported
grep -rl "package:<name>/" lib/ | wc -l

# iOS pod weight
du -sh ios/Pods/*/ | sort -rh | head -20
```

For a per-symbol view of `libapp.so` once the easy phases are done, `flutter build apk --analyze-size` emits a JSON tree that Android Studio's APK Analyzer renders. That is the right tool only if the target drops below ~25 MB and Dart code becomes the binding constraint.

---

## 3. APK composition

Total uncompressed: 133,997,372 bytes. On disk: 129,228,573 bytes. The gap is small because `.so` files are stored uncompressed for direct memory-mapping, and PNGs do not deflate further.

| Area | Files | Bytes | Share |
|---|---:|---:|---:|
| `lib/` — native libraries, 3 ABIs | 36 | 96,729,328 | **72%** |
| `assets/flutter_assets/assets/` — your artwork | 146 | 26,437,969 | **20%** |
| `classes*.dex` — Dalvik bytecode | 2 | 7,061,120 | 5% |
| `assets/flutter_assets/` — engine + package data | 337 | 1,446,467 | 1% |
| `assets/` — ML Kit models, dexopt profiles | 5 | 882,771 | <1% |
| `res/` — Android resources | 455 | 402,907 | <1% |
| `META-INF/` — signatures | 87 | 12,766 | <1% |
| other | 50 | 1,024,044 | <1% |

### 3.1 The three architecture slices

| ABI | Ships to | Bytes | Needed? |
|---|---|---:|---|
| `arm64-v8a` | Every modern Android phone | 33,383,120 | **Keep** |
| `x86_64` | Emulators, a few Chromebooks | 36,095,432 | **Drop** |
| `armeabi-v7a` | 32-bit phones, pre-2019 | 27,250,776 | **Split out** |
| | **Total shipped** | **96,729,328** | *one is ever used* |

`x86_64` is the largest slice in the entire package and no real user ever executes it.

### 3.2 Inside one slice (`arm64-v8a`)

| Library | Source | Bytes | Removable |
|---|---|---:|---|
| `libflutter.so` | Flutter engine — fixed cost | 11,581,856 | No |
| `libapp.so` | Your compiled Dart (AOT) | 9,503,632 | Shrinks with dead code |
| `libbarhopper_v3.so` | ML Kit barcode, via `mobile_scanner` | 4,946,720 | **Yes — phase 3** |
| `libmodpdfium.so` | PDFium, via `flutter_pdfview` | 4,844,960 | Optional — phase 4 |
| `libc++_shared.so` | C++ runtime | 1,304,848 | No |
| `libmodft2.so` | FreeType — PDFium dependency | 752,992 | With PDFium |
| `libmodpng.so` | libpng — PDFium dependency | 249,344 | With PDFium |

**10.3 MB per slice — 28.6 MB across the APK — is barcode scanning and PDF rendering.**

---

## 4. Root causes

| # | Cause | Evidence | Costs |
|---|---|---|---:|
| 1 | **Universal APK** | No `splits` or `abiFilters` block in `android/app/build.gradle.kts`. `BUILD_APK_GUIDE.md` instructs `flutter build apk --release`, which produces a fat APK. | ~60 MB |
| 2 | **Unshrunk artwork** | 146 PNGs, zero WebP, 25.21 MB on disk. Hero images at 2308×1732 and 2000×2000. 14 byte-identical duplicate pairs. | ~23 MB |
| 3 | **Dead feature folder** | `lib/features/dumb/` — 17 files, 380 KB, entirely unreachable, and the only importer of `mobile_scanner`. | ~5 MB |
| 4 | **No code shrinking** | No `isMinifyEnabled`, no `isShrinkResources`, no `proguard-rules.pro`. Dex is 6.7 MB. | ~3 MB |

---

## 5. Findings in detail

### 5.1 `lib/features/dumb/` is fully dead

The highest-leverage finding, because it unblocks a native library removal.

The folder holds 17 Dart files. Exactly one line anywhere in the app reaches into it:

```
lib/routes/app_routes.dart:16
import 'package:vyzi/features/dumb/warmup_onboarding.dart';
```

**That import resolves to nothing.** Every class in `dumb/warmup_onboarding.dart` is commented out — the file declares no symbols at all. The `WarmupOnboarding` widget actually used on line 131 comes from `lib/features/onboarding/warmup.dart`, imported one line earlier. The `dumb/` import is pure residue.

The live implementations all live elsewhere. `dumb/complete_request.dart` is superseded by `lib/features/request/complete_request/`, and the eleven files under `dumb/new/` duplicate screens already shipping from their real feature folders.

**The consequence:** `dumb/complete_request.dart` is the *only* file in the codebase that imports `mobile_scanner`. Because the plugin is declared in `pubspec.yaml`, the build links ML Kit's `libbarhopper_v3.so` into all three ABI slices — **14,100,440 bytes** — plus **880,888 bytes** of TensorFlow Lite models bundled as assets:

```
assets/mlkit_barcode_models/barcode_ssd_mobilenet_v1_dmp25_quant.tflite   390,456
assets/mlkit_barcode_models/oned_feature_extractor_mobile.tflite          276,552
assets/mlkit_barcode_models/oned_auto_regressor_mobile.tflite             213,880
```

All of it supports a screen no user can navigate to.

### 5.2 Half the bundled artwork is never shown

`pubspec.yaml` registers whole directories:

```yaml
assets:
  - assets/icons/
  - assets/images/
```

Every file in them ships whether or not any code references it. Assets are resolved through a single constants file, `lib/core/utils/app_assets.dart`, and there is **no dynamic asset path construction anywhere in `lib/`** — which makes usage unusually easy to verify with confidence.

| | Files | Bytes |
|---|---:|---:|
| Referenced in code | 79 | 13,393,545 |
| **Never referenced** | **67** | **13,044,424** |
| Total | 146 | 26,437,969 |

Largest dead files:

| File | Dimensions | Bytes | Note |
|---|---:|---:|---|
| `images/f_02.png` | 2308×1732 | 2,909,860 | Only `f_01`, `f_04`, `f_05` are wired up |
| `images/f_03.png` | 2312×1728 | 1,908,663 | Same set |
| `images/faq_2.png` | 1380×1036 | 1,246,715 | Superseded by the dynamic FAQ screen |
| `images/faq_1.png` | 1380×1160 | 1,085,542 | Superseded |
| `images/faq_3.png` | 1380×1040 | 974,838 | Superseded |
| `images/home_back.png` | 1568×648 | 866,946 | Byte-identical to `home_bg.png` |
| `images/uploadBill.png` | 1568×2202 | 829,162 | — |
| `images/003.png` | 1568×1872 | 693,324 | — |
| `images/vyzi_main.png` | 1254×1254 | 586,135 | — |
| `images/VYZ.png` | 1536×1024 | 573,435 | Distinct from the live `VYZI.png` |
| `images/bill_received.png` | 1108×1044 | 449,745 | — |
| `icons/Success Hero Section.png` | 1108×1044 | 449,745 | Duplicate of the above; filename contains spaces |

Full list in [Appendix A](#appendix-a--all-67-unreferenced-assets).

### 5.3 The surviving artwork is oversized

The app is portrait-only with a ScreenUtil design base of **392×876**. A full-bleed image needs roughly 1080 px on the widest phones. Nothing needs to exceed that, yet the largest live assets are more than twice it — and all 146 files are PNG, which stores photographic and gradient artwork far less efficiently than WebP.

| Live asset | Dimensions | Now | At 1080px, WebP q82 | Saved |
|---|---:|---:|---:|---:|
| `images/f_05.png` | 2308×1732 | 2,808,970 | ~180 KB | ~93% |
| `images/f_04.png` | 2396×1596 | 1,971,585 | ~150 KB | ~92% |
| `images/f_01.png` | 2000×2000 | 1,941,833 | ~160 KB | ~91% |
| `images/001.png` | 1568×2224 | 991,112 | ~110 KB | ~88% |
| `images/on1.png` | 1568×2224 | 972,205 | ~105 KB | ~89% |
| `images/home_bg.png` | 1568×648 | 866,946 | ~70 KB | ~92% |
| `images/on3.png` | 1448×1540 | 816,966 | ~95 KB | ~88% |
| `images/priceType.png` | 1360×512 | 680,845 | ~60 KB | ~91% |
| **All 79 live assets** | | **13,393,545** | **~2.0 MB** | **~85%** |

> Per-file conversion figures are projections from typical WebP ratios at these dimensions, **not measured conversions**.

### 5.4 Twenty-one declared packages are never imported

Dart tree-shaking removes unreached Dart from `libapp.so`, so these cost less than their raw size suggests. But a Flutter plugin is not just Dart — each merges an Android manifest, resources, and often Java/Kotlin and native code into the build, none of which tree-shaking touches. On iOS, each installs a CocoaPod (see §5.5).

`cached_network_image` · `dotted_border` · `easy_stepper` · `flutter_keyboard_visibility` · `flutter_spinkit` · `flutter_typeahead` · `fluttertoast` · `geocoding` · `geolocator` · `google_maps_flutter` · `grouped_list` · `hive` · `http` · `internet_connection_checker` · `mime_type` · `photo_view` · `provider` · `shimmer` · `syncfusion_flutter_calendar` · `table_calendar` · `webview_flutter`

The project declares **56 direct dependencies** resolving to **230 transitive packages**.

Six of them are compiled into the Android build as full library modules: `google_maps_flutter_android`, `geolocator_android`, `geocoding_android`, `webview_flutter_android`, `fluttertoast`, `flutter_keyboard_visibility`.

**Safety checks backing the "safe to remove" claim:**

- **Zero injected permissions.** Each candidate's merged release manifest was checked — none contributes a `uses-permission` entry. The app's `AndroidManifest.xml` is hand-maintained and already minimal, so removal changes nothing on the Play Store listing or in any runtime prompt.
- **`provider` is genuinely unused.** The only matching import is `path_provider` — a different, genuinely-used package. There is no `ChangeNotifierProvider`, `Consumer`, `context.watch`, or `Provider.of` anywhere in `lib/`; live controllers are GetX, and the `ChangeNotifier` subclasses take it from `flutter/foundation`.
- **`hive` is the one caveat.** No direct import, but `hive_flutter` (which *is* used) depends on it. Removing the direct `hive:` entry is safe only if no file needs Hive's own types by name — verify with a build, not a grep.

**Bonus:** `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` shows every pubspec plugin is instantiated at engine startup. Today that includes `GoogleMapsPlugin`, `GeolocatorPlugin`, `GeocodingPlugin`, `WebViewFlutterPlugin`, `FlutterToastPlugin`, `FlutterKeyboardVisibilityPlugin`, and `MobileScannerPlugin` — all constructed on every cold start, all unused. Removing them trims startup work as well as bytes.

### 5.5 Engine and package data

Small but worth knowing:

| Entry | Bytes | Source | Note |
|---|---:|---|---|
| `packages/timezone/data/latest_all.tzf` | 444,520 | `flutter_local_notifications` | Required for scheduled notifications |
| `NOTICES.Z` | 128,789 | Flutter | Licence text; mandatory |
| `packages/country_code_picker/src/i18n/*.json` | **509,118** (69 files) | `country_code_picker` | **The app ships only English and Italian** |
| `shaders/*.frag` | 39,480 | Flutter engine | Fixed |
| `fonts/MaterialIcons-Regular.otf` | 16,656 | Flutter | Already tree-shaken |

The 69 bundled locale files for `country_code_picker` are the only actionable item here — roughly 480 KB of it is for languages the app does not support. There is no supported configuration flag for this; trimming it means forking the package or post-processing the bundle, which is likely not worth the maintenance cost. **Recorded for completeness, not recommended.**

### 5.6 iOS

Never examined before this audit, and proportionally worse than Android.

`ios/Pods` totals **224 MB** of installed source. Largest pods:

| Pod | Size | Pulled in by | Used? |
|---|---:|---|---|
| `GoogleMaps` | 89 MB | `google_maps_flutter` | **No** |
| `SDWebImage` | 1.5 MB | `file_picker` → `DKImagePickerController` | Yes (transitive) |
| `Google-Maps-iOS-Utils` | 529 KB | `google_maps_flutter` | **No** |

`GoogleMaps` contains a **29,142,576-byte arm64 device binary**, plus a resource bundle carrying 745 KB of fonts (`DroidSansMerged-Regular.ttf`, `Tharlon-Regular.ttf`) and a 239 KB Metal shader library. Resource bundles are **not** dead-stripped — they ship whole.

Unused pods currently installed, all removable by pruning the packages in §5.4:
`google_maps_flutter_ios` · `geocoding_ios` · `geolocator_apple` · `webview_flutter_wkwebview` · `fluttertoast` · `flutter_keyboard_visibility` · `mobile_scanner`

> **Confidence:** pod source size is not IPA size. The linker dead-strips unreferenced code from static frameworks, so the real IPA delta will be smaller than 29 MB. It cannot be measured from this Windows host — no iOS build is possible here. What *is* certain is that removing `google_maps_flutter` eliminates the pod from `Podfile.lock` entirely, along with its non-strippable resource bundle. Verify with an actual archive on a Mac.

### 5.7 Two notes that are not size issues

- **`google_fonts` fetches Open Sans over the network at runtime.** No font file is bundled and `pubspec.yaml` has no `fonts:` section. This saves bytes, but means first launch depends on reaching `fonts.gstatic.com` to render correct typography, and that request is worth reviewing for GDPR purposes in an Italian consumer app. Bundling a subset would cost ~200–300 KB and remove both concerns. **A deliberate trade-off, not a defect.**
- **`public/` holds 2.9 MB of FontAwesome web fonts** (`.eot`, `.svg`, `.ttf`, `.woff`, `.woff2`). It is not listed in `pubspec.yaml`, so **none of it ships**. Repo hygiene only.

---

## 6. Reduction strategy

Ordered by risk. Everything that changes zero application code comes first, so most of the win lands before anything can break.

| # | Phase | Saving | Risk | Effort |
|---|---|---:|---|---|
| 1 | Ship one architecture per device | **−58 MB** | None | ~30 min |
| 2 | Enable R8 + resource shrinking | −3 MB | **Runtime** | ~2 hrs |
| 3 | Delete dead code and its native cargo | −5 MB | None | ~1 hr |
| 4 | Prune the dependency list | −4 MB | None | ~2 hrs |
| 5 | Rebuild the asset pipeline | **−23 MB** | Visual | ~1 day |

### Phase 1 — Ship one architecture per device

Over half the problem, solved by build configuration alone. No application code is touched.

- **For the Play Store:** switch to `flutter build appbundle`. Play generates and serves a per-device APK containing exactly one ABI. This is also mandatory for new Play submissions.
- **For direct distribution** (the current client-testing workflow): `flutter build apk --split-per-abi`, then send `app-arm64-v8a-release.apk`.
- **Drop `x86_64`** from release builds via `abiFilters`. It is the largest single slice and exists only for emulators. Debug builds are unaffected.
- **Update `BUILD_APK_GUIDE.md`**, which currently documents the command that produces the fat APK — otherwise the next person rebuilds the problem.

**123.2 MB → ~65 MB.** Verify by diffing `unzip -l` output before and after.

### Phase 2 — Enable R8 and resource shrinking

The `release` block in `android/app/build.gradle.kts` sets a signing config and nothing else.

```kotlin
buildTypes {
    release {
        signingConfig = ...
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro",
        )
    }
}
```

R8 strips code by reachability, and reflection is invisible to it. Create `proguard-rules.pro` with keep rules for this app's reflective consumers: Firebase Auth and Messaging model classes, `flutter_local_notifications`, and the Google / Apple sign-in SDKs.

Getting this wrong produces a build that compiles and then crashes at runtime, so this phase **must be exercised on a real device**. See §7 for the exact test list.

### Phase 3 — Delete dead code and its native cargo

- Remove the unused import at `lib/routes/app_routes.dart:16`, then delete `lib/features/dumb/` entirely — 17 files, 380 KB of source.
- Drop `mobile_scanner` from `pubspec.yaml`. Its last consumer just went with the folder. This removes `libbarhopper_v3.so` (4.9 MB from the shipped slice) *and* 880 KB of `.tflite` models.
- Confirm with `flutter analyze`. The folder is self-contained, so nothing should reference it.

Land this as its own commit — easy to review, trivially revertable.

### Phase 4 — Prune the dependency list

Remove the 21 never-imported packages from §5.4. Do it in two or three commits grouped by risk, with plugins carrying native code first, since they carry the measurable weight and any breakage surfaces immediately at build time. Run `cd ios && pod install` afterwards so `Podfile.lock` drops the corresponding pods.

**The judgment call is `flutter_pdfview`.** Unlike `mobile_scanner`, it is genuinely used — by `lib/features/request/document_viewer_screen.dart`. It costs 5.6 MB per slice (PDFium plus its FreeType and libpng dependencies) to render contract PDFs in-app. Three options:

- **Keep it.** In-app PDF viewing is a real part of the contract-signing flow, and 5.6 MB may be the right price.
- **Hand off to the system viewer** via `url_launcher` or `share_plus`, both already dependencies. Saves 5.6 MB; costs an app-switch in a sensitive flow.
- **Render server-side.** The backend already handles document processing — returning page images would remove the client-side renderer entirely.

This is a product decision, not a technical one. **The projection in §8 assumes keeping it.**

### Phase 5 — Rebuild the asset pipeline

The largest remaining win, and the one needing the most human attention because it changes what users see.

- **Delete the 67 unreferenced files** — 12.4 MB, and the single highest-value hour in this plan. List in [Appendix A](#appendix-a--all-67-unreferenced-assets).
- **Resolve the 14 duplicate pairs.** Keep one of each, repoint `app_assets.dart`. List in [Appendix B](#appendix-b--byte-identical-duplicate-pairs).
- **Downscale to a 1080 px ceiling.** Nothing rendered on a 392pt-wide portrait canvas needs 2308 px of source.
- **Convert to WebP** at q82 for photographic and gradient art. Flutter renders WebP natively on both platforms — no code change beyond the file extensions in `app_assets.dart`.
- **Stop registering whole directories.** Replace the `assets/icons/` and `assets/images/` wildcards in `pubspec.yaml` with explicit file entries, so an unused file can never silently ship again.
- **Rename `assets/icons/Success Hero Section.png`** if it survives — spaces in asset paths are a persistent source of tooling breakage.

**One item needs a human, not a grep:** 30 constants in `app_assets.dart` are declared but never used by any widget — including `splashBg` and `homeBg` (both pointing at the same 866,946-byte file) and `homeRegularBg` (592,844 bytes). That is roughly 1.5 MB more, but these are background images on the splash and home screens — exactly the kind of thing that looks dead to static analysis and is obvious the moment you open the app. **Confirm against a running build before deleting.**

---

## 7. What actually changes for users

Three of the five phases are provably invisible. One can break a working app. One deliberately changes what people see.

| Phase | User-visible? | What changes, concretely |
|---|---|---|
| 1 — ABI split | **None** | Identical machine code; the device stops downloading two architectures it cannot execute. |
| 2 — R8 | **Risk** | Intended: nothing. But R8 removes code by reachability, and reflection is invisible to it. |
| 3 — Delete `dumb/` | **None** | Verified unreachable — no route, no import that resolves, no widget. |
| 4 — Prune packages | **None** | Zero imports, zero injected permissions. |
| 4b — Drop `flutter_pdfview` | **Yes** | Contract PDFs open externally instead of in-app. This is why it is optional. |
| 5 — Assets | **Yes** | Deleting the 67 dead files changes nothing; downscaling and WebP change rendered pixels. |

### Why phases 1, 3 and 4 are safe

**Phase 1** does not recompile anything differently. An arm64 phone running today's universal APK already executes `lib/arm64-v8a/*` and ignores the other two directories entirely. Splitting removes only the directories that device never opened.

**Phase 3** was verified three ways: no `GetPage` route points into `dumb/`; the one import that reaches it resolves to a file whose every class is commented out; and the widget on that route line comes from a different file imported one line earlier.

**Phase 4** rests on the two checks in §5.4 — no injected permissions, and no API usage under a different import name.

### Where the real risk sits: R8

The blast radius is narrower than it sounds.

**R8 cannot touch your Dart code.** It operates on JVM bytecode. All 33 model classes with `fromJson` are Dart, compiled ahead-of-time into `libapp.so` — a native library R8 never opens. No amount of shrinking can break API parsing, controllers, or widgets. That is the majority of this codebase, and it is categorically safe.

**Your own Android code is a non-issue too.** `MainActivity.kt` is four lines and declares no platform channels, so there is nothing app-specific for R8 to strip incorrectly.

The exposure is confined to third-party Java/Kotlin SDKs that resolve classes reflectively at runtime — where the class is never mentioned by name in code R8 can see, so it looks unreachable and gets deleted. Here that means Firebase Auth and Messaging, `flutter_local_notifications`, and the Google and Apple sign-in libraries. A missing keep rule produces a build that compiles cleanly and then throws `ClassNotFoundException` at runtime.

**Required test pass after phase 2, on a physical device:**

1. Sign in with Google and Apple — each separately.
2. Receive a push notification and tap through it to the correct screen.
3. Open a referral deep link (`https://api.vyzi.app/r/...`).
4. Open a contract PDF (if `flutter_pdfview` is retained).

Those four paths cover essentially the whole reflective surface. Note also that `isShrinkResources` can drop resources referenced only by name at runtime — the `notification_sound` raw resource, named only from Dart and FCM payloads, is the one to watch (kept by `res/raw/keep.xml`).

### Two workflow changes worth planning for

- **Release builds stop running on emulators.** Standard Android emulators are `x86_64`, so once that ABI is excluded from release, `flutter run --release` on an emulator will fail to launch. Debug builds and physical devices are unaffected. If release-mode emulator testing matters, exclude `x86_64` in the App Bundle rather than in `abiFilters`.
- **The client-testing handoff changes shape.** `--split-per-abi` produces several files instead of one, and sending the wrong one gives the client an app that will not install. `BUILD_APK_GUIDE.md` documents the single-file flow — if it is not updated, this phase quietly gets reverted the next time someone follows the guide.

---

## 8. Projection

| After | Change | Saved | APK size | Effort |
|---|---|---:|---:|---|
| — | Today, universal APK | — | **123.2 MB** | — |
| Phase 1 | arm64-only delivery | −58 MB | ~65 MB | 30 min |
| Phase 2 | R8 + resource shrinking | −3 MB | ~62 MB | 2 hrs |
| Phase 3 | Delete `dumb/` + `mobile_scanner` | −5 MB | ~57 MB | 1 hr |
| Phase 4 | Prune 21 unused packages | −4 MB | ~53 MB | 2 hrs |
| Phase 5 | Asset cleanup + WebP | −23 MB | **~30 MB** | 1 day |
| *optional* | Drop `flutter_pdfview` too | −5.6 MB | ~24 MB | — |

### Confidence

| Figure | Basis |
|---|---|
| APK composition, ABI slices, per-library sizes | **Measured** — `unzip -l` on the actual release APK |
| Asset counts, dead-file list, duplicates, dimensions | **Measured** — filesystem scan + PNG IHDR headers |
| Phase 1 saving (−58 MB) | **Measured** — sum of the two dropped ABI slices |
| Phase 5 saving (−23 MB) | Dead files measured; WebP ratios **estimated** from typical q82 results |
| Phase 2 saving (−3 MB) | **Estimated** — typical R8 behaviour on a dex this size, ±2 MB |
| Phase 4 saving (−4 MB) | **Estimated** — plugin manifest/resource merge weight, ±2 MB |
| iOS savings | **Reasoned, not measured** — from pod binary sizes. No iOS build possible on this Windows host; dead-stripping means the real IPA delta is smaller. Verify with an archive on a Mac. |

**The landing zone is 28–32 MB**, and the Play Store download will be smaller still, since Play additionally splits by screen density and language.

### Two things worth *not* doing

- **Do not drop `armeabi-v7a` outright.** Split it out of the default artifact, but keep publishing it in the App Bundle. It costs nothing under per-device delivery, and 32-bit devices still exist in the Italian market.
- **Do not reach for deferred components or dynamic feature modules.** They add real architectural complexity, and after the five phases above there is no remaining 10 MB chunk for them to defer. Revisit only if the app grows substantially.

---

## Appendix A — All 67 unreferenced assets

Total: **13,044,424 bytes**. No file below is named anywhere in `lib/`.

| Bytes | Path |
|---:|---|
| 2,909,860 | `assets/images/f_02.png` |
| 1,908,663 | `assets/images/f_03.png` |
| 1,246,715 | `assets/images/faq_2.png` |
| 1,085,542 | `assets/images/faq_1.png` |
| 974,838 | `assets/images/faq_3.png` |
| 866,946 | `assets/images/home_back.png` |
| 829,162 | `assets/images/uploadBill.png` |
| 693,324 | `assets/images/003.png` |
| 586,135 | `assets/images/vyzi_main.png` |
| 573,435 | `assets/images/VYZ.png` |
| 449,745 | `assets/images/bill_received.png` |
| 449,745 | `assets/icons/Success Hero Section.png` |
| 91,634 | `assets/images/policy.png` |
| 86,403 | `assets/images/FaQ.png` |
| 32,649 | `assets/images/aze.png` |
| 24,890 | `assets/images/Illustration.png` |
| 16,116 | `assets/icons/succsess.png` |
| 11,308 | `assets/images/reverse.png` |
| 11,308 | `assets/icons/analyze.png` |
| 9,615 | `assets/images/cont.png` |
| 9,610 | `assets/icons/contract.png` |
| 8,863 | `assets/images/thik.png` |
| 8,859 | `assets/icons/submitted.png` |
| 6,867 | `assets/images/fiti_act.png` |
| 6,747 | `assets/images/private.png` |
| 6,556 | `assets/icons/33.png` |
| 6,413 | `assets/images/applogo.png` |
| 6,228 | `assets/icons/34.png` |
| 5,780 | `assets/icons/35.png` |
| 5,503 | `assets/icons/14.png` |
| 5,431 | `assets/icons/mailto.png` |
| 5,431 | `assets/icons/mail2.png` |
| 5,196 | `assets/images/spark.png` |
| 4,800 | `assets/icons/37.png` |
| 4,612 | `assets/icons/bill_check.png` |
| 4,503 | `assets/icons/transfer.png` |
| 4,386 | `assets/icons/12.png` |
| 4,232 | `assets/icons/support.png` |
| 4,091 | `assets/icons/11.png` |
| 3,802 | `assets/icons/31.png` |
| 3,692 | `assets/images/request_energy.png` |
| 3,692 | `assets/images/request.png` |
| 3,671 | `assets/icons/36.png` |
| 3,669 | `assets/icons/activate.png` |
| 3,594 | `assets/icons/cart.png` |
| 3,550 | `assets/icons/38.png` |
| 3,353 | `assets/images/pro.png` |
| 3,352 | `assets/icons/utility.png` |
| 3,327 | `assets/icons/personal.png` |
| 3,207 | `assets/icons/39.png` |
| 3,155 | `assets/icons/13.png` |
| 3,065 | `assets/icons/practice.png` |
| 2,933 | `assets/icons/agreements.png` |
| 2,874 | `assets/images/utila.png` |
| 2,821 | `assets/icons/requests.png` |
| 2,611 | `assets/icons/32.png` |
| 2,339 | `assets/images/uploadIcon.png` |
| 2,288 | `assets/images/process.png` |
| 2,163 | `assets/icons/contracts.png` |
| 1,522 | `assets/icons/qr1.png` |
| 1,421 | `assets/icons/luce_bright.png` |
| 1,406 | `assets/icons/qr.png` |
| 1,350 | `assets/images/doc.png` |
| 967 | `assets/images/pay.png` |
| 967 | `assets/icons/payment.png` |
| 930 | `assets/icons/file.png` |
| 562 | `assets/images/down_arrow.png` |

---

## Appendix B — Byte-identical duplicate pairs

Fourteen pairs, verified by MD5. Keep one of each and repoint `app_assets.dart`.

| File A | File B |
|---|---|
| `assets/icons/activate.png` | `assets/images/h_3.png` |
| `assets/icons/switch.png` | `assets/images/h_1.png` |
| `assets/icons/Success Hero Section.png` | `assets/images/bill_received.png` |
| `assets/icons/mail2.png` | `assets/icons/mailto.png` |
| `assets/icons/succsess.png` | `assets/images/success.png` |
| `assets/icons/8.png` | `assets/icons/support.png` |
| `assets/icons/payment.png` | `assets/images/pay.png` |
| `assets/icons/business.png` | `assets/images/pro.png` |
| `assets/images/home_back.png` | `assets/images/home_bg.png` |
| `assets/icons/transfer.png` | `assets/images/h_2.png` |
| `assets/icons/scan.png` | `assets/icons/scannn.png` |
| `assets/images/request.png` | `assets/images/request_energy.png` |
| `assets/icons/bill_check.png` | `assets/images/h_4.png` |
| `assets/images/circle.png` | `assets/images/flash.png` |

---

## Appendix C — Never-imported packages

Verified: `grep -rl "package:<name>/" lib/` returns zero files for each.

| Package | Android module built? | iOS pod installed? | Notes |
|---|---|---|---|
| `google_maps_flutter` | Yes | Yes — **89 MB** | Largest single win on iOS |
| `geolocator` | Yes | Yes | No permissions injected |
| `geocoding` | Yes | Yes | No permissions injected |
| `webview_flutter` | Yes | Yes | AndroidX WebKit |
| `fluttertoast` | Yes | Yes | Android resources/layouts |
| `flutter_keyboard_visibility` | Yes | Yes | — |
| `syncfusion_flutter_calendar` | No | No | Pure Dart; large source, mostly tree-shaken |
| `cached_network_image` | No | No | Transitive cache manager |
| `table_calendar` | No | No | Pure Dart |
| `photo_view` | No | No | Pure Dart |
| `shimmer` | No | No | Pure Dart |
| `flutter_spinkit` | No | No | Pure Dart |
| `flutter_typeahead` | No | No | Pure Dart |
| `dotted_border` | No | No | Pure Dart |
| `easy_stepper` | No | No | Pure Dart |
| `grouped_list` | No | No | Pure Dart |
| `provider` | No | No | Redundant — GetX is the state layer |
| `http` | No | No | Redundant — Dio is the HTTP layer |
| `internet_connection_checker` | No | No | Redundant — `ConnectivityService` |
| `mime_type` | No | No | Redundant |
| `hive` | No | No | **Verify** — `hive_flutter` depends on it |

---

## 9. Outcome — what actually happened

Implemented 1 September 2026 across eight commits, one per phase or risk group.
Every figure below is measured on `app-arm64-v8a-release.apk` from a **clean**
`flutter build apk --release --split-per-abi`.

| After | Projected | **Measured** |
|---|---:|---:|
| Baseline, universal APK | 123.2 MB | **123.2 MB** |
| Phases 1 + 3 + 4 (ABI split, dead code, deps) | ~53 MB | **56.5 MB** |
| Phase 5 (assets) | ~30 MB | **39.8 MB** |
| Phase 2 (R8 + resource shrinking) | ~27 MB | **34.9 MB** |
| Replacing `flutter_pdfview` with `pdfx` | ~24 MB (listed optional) | **28.0 MB** |
| **Reduction** | | **−77%** |

Final composition of the 34.9 MB arm64 APK:

| Area | In-APK bytes |
|---|---:|
| `lib/` native — one ABI | 27,120,000 |
| `classes*.dex` | ~6,700,000 |
| our assets | 1,076,750 |
| engine + package data | 561,872 |
| `res/` | 314,977 |

Native code is now **78%** of the package and is the only remaining lever of
any size. Assets, the original second-largest slice at 20%, are down to 3%.

### Where this document was wrong

Three things worth recording, because each one cost real time.

**1. `--target-platform android-arm64` does not produce a single-ABI APK.**
§6 phase 1 implies ABI selection can be done with build flags generally. The
flag only controls Flutter's own artifacts — `libflutter.so` and `libapp.so`.
Native libraries belonging to *plugins* are packaged by the Android Gradle
plugin and ignore it. A measured `--target-platform android-arm64` build still
shipped `lib/x86_64/libmodpdfium.so`, `lib/armeabi-v7a/libmodpdfium.so` and
both other-ABI copies of `libc++_shared.so` and `libmodft2.so` — about 13 MB
of architectures the target device cannot execute. Only `--split-per-abi` and
App Bundle delivery genuinely separate them. `BUILD_APK_GUIDE.md` now says so.

**2. The dead-asset scan used a substring match.** The command in §2 tests
`grep -qF "$(basename "$f")"`, so `001.png` counted as referenced because
`profile_001.png` appears in `lib/`. The error is in the safe direction — it
over-keeps and never over-deletes — but it hid two dead files, and the "67
unreferenced assets" figure was really 72. A correct check resolves each
reference to a path and compares both directions: every filename named in
`lib/` must exist on disk, and every file on disk must be listed in
`pubspec.yaml`.

Related: §5.2 states assets are resolved through `app_assets.dart` alone. They
are not — 15 files carry hardcoded `'assets/...'` literals inline. That does
not change the dead-file analysis, but it does mean any asset rename has to
sweep all of `lib/`, not one constants file.

**3. The WebP projection was pessimistic.** §5.3 estimated ~2.0 MB for the
live assets from typical q82 ratios. Measured: **1,135,320 bytes** across 74
files, a 91% reduction rather than 85%. Downscaling to the 1080 px ceiling
does most of the work; the format change compounds it.

### A measurement trap worth knowing

Flipping `isMinifyEnabled` and rebuilding **without** `flutter clean` reports a
dex far smaller than the build actually contains. That reading — 5,881,012
bytes against a clean R8 build's 14,356,756 — made R8 look like it was
inflating the APK by 8 MB, and it was turned off on that basis before a
clean-versus-clean comparison showed the opposite:

|  | APK bytes | dex bytes | dex classes |
|---|---:|---:|---:|
| R8 on | 36,629,945 | 14,356,756 | 14,643 |
| R8 off | 41,757,362 | 28,328,692 | 25,985 |

R8 halves the class count and saves 5.1 MB. Never compare an incremental build
against a clean one when the dex pipeline itself has changed.

### Still open

- **The R8 device test pass in §7 has not been run.** R8 removes code by
  reachability and reflection is invisible to it. `proguard-rules.pro` names
  the reflective consumers, but a missing keep rule does not fail the build —
  it throws at runtime. Before any release: Google and Apple sign-in
  each separately, a push notification tapped through to its screen, a
  referral deep link, and a contract PDF.
- **`flutter_pdfview` was replaced, not kept** — see §10. The product trade-off
  §6 phase 4 poses turned out not to be a trade-off at all.
- **The ~30 unused-looking constants in `app_assets.dart`** — including
  `splashBg`, `homeBg` and `homeRegularBg` — were deliberately left. They name
  real files, so they fall outside a "nothing references it" test, and they are
  exactly the kind of background image that looks dead to a search and is
  obvious on a running screen. Roughly 1.5 MB before conversion, far less now.
- **iOS is unverified.** Removing `google_maps_flutter` drops the `GoogleMaps`
  pod and its non-strippable resource bundle from `Podfile.lock`, along with
  `geocoding_ios`, `geolocator_apple`, `webview_flutter_wkwebview`,
  `fluttertoast`, `flutter_keyboard_visibility` and `mobile_scanner`. None of
  it can be measured on this Windows host. Run `pod install` and archive on a
  Mac.


---

## 10. Postscript — the PDF renderer did not need a trade-off

§6 phase 4 framed `flutter_pdfview` as a product decision: keep in-app PDF
viewing at 5.6 MB, hand off to the system viewer, or render server-side. All
three options accept that in-app rendering costs PDFium.

It does not. `flutter_pdfview` wraps AndroidPdfViewer, which **bundles**
PDFium. `pdfx` renders through the operating system instead —
`android.graphics.pdf.PdfRenderer` on Android, `CGPDFPage` on iOS — so nothing
native ships with it. Same in-app UX, no app-switch, no backend work, MIT
licence either way.

| | `flutter_pdfview` | `pdfx` |
|---|---|---|
| Android backend | bundled PDFium | OS `PdfRenderer` |
| iOS backend | bundled PDFium | OS `CGPDFPage` |
| Native bytes per slice | 5,876,784 | 0 |
| Latest release | 1.4.4 | 2.11.0 |

**34.9 MB → 28.0 MB**, a further 7,228,139 bytes — more than the 5.6 MB the
libraries themselves weigh, because R8 then had less to keep. `libmodpdfium`,
`libmodft2`, `libmodpng`, `libjniPdfium` and `libc++_shared` are all gone;
native code is now only `libflutter.so` and `libapp.so`.

The project had already worked this out once. `pubspec.yaml` still carried
`# pdfx: removed — PDF rendering no longer needed on-device` on the line above
`flutter_pdfview`. When in-app viewing came back, it came back heavy.

**The one real cost:** `PdfRenderer` refuses password-protected PDFs, where
PDFium opens them. If the backend ever serves an encrypted contract, that now
lands in the viewer's existing error state with its retry and "open elsewhere"
escape hatch. Worth confirming against a production contract file.

### Final position

| | |
|---|---:|
| Baseline universal APK | 123.2 MB |
| Final, arm64 `--split-per-abi` | **28.0 MB** |
| Reduction | **77%** |

Remaining composition: 21.2 MB native (`libflutter.so` 11.6 MB + `libapp.so`
9.5 MB, both irreducible), ~5.6 MB dex, 1.03 MB assets. There is no further
lever of consequence short of shrinking the Dart tree itself, which
`flutter build apk --analyze-size` would guide if it ever became worth doing.
