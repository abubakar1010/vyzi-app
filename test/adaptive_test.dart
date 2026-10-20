import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/core/layout/adaptive.dart';

/// The app as MyApp builds it, cut down to what the layout layer touches: the
/// design-size scaling and a screen that reports what it measured.
Widget _app(Widget Function(BuildContext context) screen) {
  return ScreenUtilInit(
    designSize: const Size(392, 876),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => AdaptiveScale(
      child: MaterialApp(home: Builder(builder: screen)),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Size window, Widget app) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = window * 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pump();
}

const _phone = Size(393, 852);
const _iPadPortrait = Size(1024, 1366);
const _iPadLandscape = Size(1366, 1024);
const _slideOver = Size(320, 1024);

void main() {
  group('Adaptive', () {
    test('a window is wide from the breakpoint on', () {
      expect(Adaptive.isWideWidth(_phone.width), isFalse);
      expect(Adaptive.isWideWidth(_slideOver.width), isFalse);
      expect(Adaptive.isWideWidth(599), isFalse);
      expect(Adaptive.isWideWidth(600), isTrue);
      expect(Adaptive.isWideWidth(_iPadPortrait.width), isTrue);
    });

    test('columns grow with the width, one on a phone', () {
      expect(Adaptive.columns(_phone.width), 1);
      expect(Adaptive.columns(680), 2);
      expect(Adaptive.columns(1072), 3);
      expect(Adaptive.columns(4000), 3);
      expect(Adaptive.columns(4000, max: 4), 4);
    });
  });

  group('AdaptiveScale', () {
    test('keeps the phone design size on narrow windows', () {
      expect(AdaptiveScale.designSizeFor(_phone), isNull);
      expect(AdaptiveScale.designSizeFor(_slideOver), isNull);
    });

    test('gives wide windows one fixed scale', () {
      for (final window in [_iPadPortrait, _iPadLandscape]) {
        final design = AdaptiveScale.designSizeFor(window)!;
        expect(window.width / design.width, closeTo(Adaptive.wideScale, 1e-9));
        expect(window.height / design.height, closeTo(Adaptive.wideScale, 1e-9));
      }
    });

    testWidgets('a phone still scales the design by its width', (tester) async {
      late double scaled;
      await _pump(tester, _phone, _app((context) {
        scaled = 392.w;
        return const SizedBox.expand();
      }));
      expect(scaled, closeTo(_phone.width, 0.01));
    });

    testWidgets('an iPad does not stretch the phone design', (tester) async {
      late double width;
      late double text;
      await _pump(tester, _iPadPortrait, _app((context) {
        width = 100.w;
        text = 16.sp;
        return const SizedBox.expand();
      }));
      expect(width, closeTo(100 * Adaptive.wideScale, 0.01));
      expect(text, closeTo(16 * Adaptive.wideScale, 0.01));
    });
  });

  group('Adaptive.page', () {
    Future<EdgeInsets> page(WidgetTester tester, Size window, EdgeInsets phone,
        {double maxWidth = Adaptive.readableWidth}) async {
      late EdgeInsets padding;
      await _pump(tester, window, _app((context) {
        padding = Adaptive.page(context, phone, maxWidth: maxWidth);
        return const SizedBox.expand();
      }));
      return padding;
    }

    const phonePadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

    testWidgets('leaves a phone padding alone', (tester) async {
      expect(await page(tester, _phone, phonePadding), phonePadding);
    });

    testWidgets('centres the content at the max width on an iPad',
        (tester) async {
      final padding = await page(tester, _iPadPortrait, phonePadding);
      expect(padding.left, (1024 - Adaptive.readableWidth) / 2);
      expect(padding.right, padding.left);
      expect(padding.top, 12);
      expect(padding.bottom, 24);
    });

    testWidgets('never goes below the phone padding', (tester) async {
      final padding = await page(tester, const Size(700, 1000), phonePadding);
      expect(padding.left, 16);
      expect(padding.right, 16);
    });
  });

  group('AdaptiveListView', () {
    Widget list() => _app(
          (context) => AdaptiveListView.builder(
            itemCount: 5,
            itemBuilder: (_, i) => SizedBox(
              key: ValueKey(i),
              // Uneven heights, as the app's cards are.
              height: i.isEven ? 100 : 60,
            ),
          ),
        );

    testWidgets('is a single column on a phone', (tester) async {
      await _pump(tester, _phone, list());
      final xs = {
        for (var i = 0; i < 5; i++)
          tester.getTopLeft(find.byKey(ValueKey(i))).dx,
      };
      expect(xs, hasLength(1));
    });

    testWidgets('deals the cards into columns on an iPad', (tester) async {
      await _pump(tester, _iPadLandscape, list());
      double x(int i) => tester.getTopLeft(find.byKey(ValueKey(i))).dx;
      double y(int i) => tester.getTopLeft(find.byKey(ValueKey(i))).dy;

      // Four columns' worth of room, three columns at most: cards go across
      // in order, then on down each column with no gap from the row beside.
      expect({x(0), x(1), x(2)}, hasLength(3));
      expect(x(3), x(0));
      expect(x(4), x(1));
      expect(y(3), y(0) + 100);
      expect(y(4), y(1) + 60);
    });
  });
}
