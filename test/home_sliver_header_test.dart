import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/features/home/widgets/home_header.dart';

/// The collapsing home banner used to overflow part-way through the collapse:
/// its extents were hard-coded while its content kept its intrinsic height, so
/// there was a band of scroll offsets where the flexible space was smaller than
/// the column inside it. These tests scroll through *every* intermediate state
/// and fail on any overflow, across screen sizes and system text scales.
void main() {
  setUpAll(() {
    // Never hit the network for fonts in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(Get.reset);

  const sizes = <Size>[
    Size(392, 876), // ScreenUtil design size
    Size(360, 640), // short/small Android
    Size(320, 568), // smallest phone still supported
    Size(430, 932), // large iPhone
  ];
  const textScales = <double>[1.0, 1.3, 2.0];

  for (final size in sizes) {
    for (final textScale in textScales) {
      testWidgets(
        'HomeSliverHeader never overflows while collapsing '
        '(${size.width.toInt()}x${size.height.toInt()}, textScale $textScale)',
        (tester) async {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1.0
            ..padding = const FakeViewPadding(top: 47); // status bar
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final scrollController = ScrollController();
          addTearDown(scrollController.dispose);

          await tester.pumpWidget(_harness(scrollController));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'initial layout');

          // Walk the whole collapse range in small steps — the original bug
          // only showed up in a narrow band near the end of the collapse.
          for (double offset = 0; offset <= 300; offset += 2) {
            scrollController.jumpTo(offset);
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: 'overflow at scroll offset $offset',
            );
          }
        },
      );
    }
  }

  testWidgets('header collapses to the logo row and stays pinned',
      (tester) async {
    tester.view
      ..physicalSize = const Size(392, 876)
      ..devicePixelRatio = 1.0
      ..padding = const FakeViewPadding(top: 47);
    addTearDown(tester.view.reset);

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(_harness(scrollController));
    await tester.pumpAndSettle();

    double headerExtent() => tester
        .renderObject<RenderSliver>(find.byType(SliverAppBar))
        .geometry!
        .paintExtent;

    final expandedHeight = headerExtent();

    scrollController.jumpTo(300);
    await tester.pumpAndSettle();
    final collapsedHeight = headerExtent();

    expect(collapsedHeight, lessThan(expandedHeight));
    // Pinned: the logo row plus its padding and the status bar stay on screen.
    expect(collapsedHeight, greaterThan(47 + 48));
    // The greeting is fully faded out once collapsed.
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(SliverAppBar),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.0);
  });

  group('banner matches the design', () {
    // Design geometry, in the 392pt base width the mock was drawn at.
    const statusBar = 47.0;
    const circleDiameter = 156.0;
    const circleCentreFromRight = 42.0;
    const circleCentreFromTop = 39.0; // below the status bar
    const padH = 16.0;
    const tile = 48.0;

    Future<void> pumpBanner(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(392, 876)
        ..devicePixelRatio = 1.0
        ..padding = const FakeViewPadding(top: statusBar);
      addTearDown(tester.view.reset);

      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(_harness(scrollController));
      await tester.pumpAndSettle();
    }

    final circleFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    );
    final tileFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color ==
              AppColors.headerIconTile,
    );

    testWidgets('the notification tile is not the same fill as the disc '
        'behind it', (tester) async {
      await pumpBanner(tester);

      // The tile sits entirely inside the disc, so an equal (or darker) fill
      // makes the button vanish into it — which is exactly what regressed.
      expect(AppColors.headerIconTile, isNot(AppColors.headerCircle));
      expect(tileFinder, findsOneWidget);
    });

    testWidgets('the decorative disc sits where the design puts it',
        (tester) async {
      await pumpBanner(tester);

      final circle = tester.getRect(circleFinder);
      expect(circle.width, closeTo(circleDiameter, 0.5));
      expect(circle.height, closeTo(circleDiameter, 0.5));
      expect(392 - circle.center.dx, closeTo(circleCentreFromRight, 0.5));
      // Measured from below the status bar: the arc is cut off by the top
      // edge and stops short of the banner's bottom.
      expect(
        circle.center.dy - statusBar,
        closeTo(circleCentreFromTop, 0.5),
      );
      expect(circle.top, lessThan(statusBar));
    });

    testWidgets('the notification tile is inside the disc and on the 16pt '
        'margin', (tester) async {
      await pumpBanner(tester);

      final circle = tester.getRect(circleFinder);
      final tileRect = tester.getRect(tileFinder);

      expect(tileRect.width, closeTo(tile, 0.5));
      expect(392 - tileRect.right, closeTo(padH, 0.5));

      final radius = circle.width / 2;
      for (final corner in <Offset>[
        tileRect.topLeft,
        tileRect.topRight,
        tileRect.bottomLeft,
        tileRect.bottomRight,
      ]) {
        expect(
          (corner - circle.center).distance,
          lessThan(radius),
          reason: '$corner escapes the disc, so the tile would be clipped by '
              'a colour it no longer contrasts with',
        );
      }
    });
  });
}

Widget _harness(ScrollController scrollController) {
  return DefaultAssetBundle(
    bundle: _FakeAssetBundle(),
    child: ScreenUtilInit(
      designSize: const Size(392, 876),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('it', 'IT'),
        fallbackLocale: const Locale('it', 'IT'),
        home: Scaffold(
          body: CustomScrollView(
            controller: scrollController,
            slivers: [
              const HomeSliverHeader(),
              SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Serves a 1x1 transparent PNG for every asset so `Image.asset` resolves
/// without the real asset bundle, and an empty asset manifest so no resolution
/// variants are looked up.
class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(Uint8List.fromList(_kTransparentPng).buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) async {
    return parser(const StandardMessageCodec().encodeMessage(<String, Object>{})!);
  }
}

const List<int> _kTransparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
