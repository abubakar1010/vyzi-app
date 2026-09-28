import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/app.dart';
import 'package:vyzi/core/controllers/language_controller.dart';
import 'package:vyzi/core/services/deep_link_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/onboarding/warmup.dart';
import 'package:vyzi/features/splash/spalsh_screen.dart';
import 'package:vyzi/routes/app_routes.dart';

/// Boot smoke test.
///
/// This file used to hold the unmodified Flutter template test, asserting a
/// counter and a `+` button that this app has never had, so it failed on every
/// run and told nobody anything. It now covers what the template was gesturing
/// at: that the app actually boots.
///
/// The route-table checks exist because `app_routes.dart` is the one file where
/// a dead import can hide indefinitely. A `GetPage` whose `page` builder throws,
/// or a duplicate route name, produces no analyzer warning and no build failure
/// — it fails at navigation time, in front of a user.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Never reach for fonts.gstatic.com in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _setSecureStorageMock(enabled: true);

    // MyApp reads the locale from LanguageController, which reads
    // StorageService, and SplashScreen resolves both StorageService and
    // DeepLinkService when its timer fires. Register the same graph main.dart
    // builds, minus anything that needs a network or a platform view.
    final storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);
    Get.put<DeepLinkService>(DeepLinkService(), permanent: true);
    Get.put<LanguageController>(LanguageController(), permanent: true);
  });

  tearDown(() {
    _setSecureStorageMock(enabled: false);
    Get.reset();
  });

  testWidgets('boots to the splash screen without throwing', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let the splash timer resolve so no timer outlives the test.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
  });

  testWidgets('with no stored session, splash lands on warm onboarding',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // SplashScreen waits 3s before deciding where to go.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(Get.currentRoute, AppRoutes.warmOnboardScreen);
    expect(find.byType(WarmupOnboarding), findsOneWidget);
  });

  group('route table', () {
    test('every route has a unique, well-formed name', () {
      final names = AppRoutes.page.map((p) => p.name).toList();

      for (final name in names) {
        expect(name, isNotEmpty, reason: 'a GetPage has an empty name');
        expect(name.startsWith('/'), isTrue,
            reason: '"$name" should start with "/"');
      }

      final duplicates = <String>{};
      final seen = <String>{};
      for (final name in names) {
        if (!seen.add(name)) duplicates.add(name);
      }
      expect(duplicates, isEmpty, reason: 'duplicate route names: $duplicates');
    });

    test('initial route is registered', () {
      final names = AppRoutes.page.map((p) => p.name).toSet();
      expect(names, contains(AppRoutes.splashScreen));
      expect(names, contains(AppRoutes.warmOnboardScreen));
      expect(names, contains(AppRoutes.navbarScreen));
      expect(names, contains(AppRoutes.signUpScreen));
    });

    test('every page builder resolves to a widget', () {
      // Catches a route pointing at a file whose class no longer exists, or a
      // builder that throws before a Navigator ever gets involved.
      //
      // These two read Get.arguments in the builder itself, so they cannot be
      // constructed without navigating to them. Excluded deliberately, and the
      // next test asserts this list still matches app_routes.dart.
      final needsArguments = <String>{
        AppRoutes.billDetailScreen,
        AppRoutes.ticketDetailScreen,
      };

      for (final page in AppRoutes.page) {
        if (needsArguments.contains(page.name)) continue;
        expect(page.page(), isNotNull, reason: 'route "${page.name}" built null');
      }
    });

    test('the argument-dependent routes are still exactly those two', () {
      // If someone adds a third Get.arguments route, the test above would
      // silently stop covering it. This fails instead.
      final actual = <String>{};
      for (final page in AppRoutes.page) {
        try {
          page.page();
        } on TypeError {
          actual.add(page.name);
        }
      }

      expect(
        actual,
        <String>{AppRoutes.billDetailScreen, AppRoutes.ticketDetailScreen},
        reason: 'update the needsArguments set in the test above',
      );
    });
  });
}

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Answers as an empty keystore: no token is stored, every write succeeds.
void _setSecureStorageMock({required bool enabled}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    _secureStorageChannel,
    enabled
        ? (MethodCall call) async =>
            call.method == 'readAll' ? <String, String>{} : null
        : null,
  );
}
