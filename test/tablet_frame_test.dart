import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/core/layout/tablet_frame.dart';

/// The app as MyApp builds it, cut down to what the frame touches: the
/// design-size scaling and a screen that reports what it was given.
Widget _app({required void Function(Size layout, double scaledWidth) onBuild}) {
  return ScreenUtilInit(
    designSize: const Size(392, 876),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TabletFrame(
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            onBuild(MediaQuery.sizeOf(context), 392.w);
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
}

Future<(Size, double)> _run(WidgetTester tester, Size screen) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = screen * 2;
  addTearDown(tester.view.reset);

  late Size layout;
  late double scaledWidth;
  await tester.pumpWidget(_app(onBuild: (s, w) {
    layout = s;
    scaledWidth = w;
  }));
  await tester.pump();
  return (layout, scaledWidth);
}

void main() {
  group('TabletFrame.appSizeFor', () {
    test('leaves phones alone', () {
      expect(TabletFrame.appSizeFor(const Size(393, 852)), const Size(393, 852));
      expect(TabletFrame.appSizeFor(const Size(430, 932)), const Size(430, 932));
    });

    test('gives an iPad a phone-width column, portrait and landscape', () {
      expect(TabletFrame.appSizeFor(const Size(1024, 1366)), const Size(480, 1366));
      expect(TabletFrame.appSizeFor(const Size(1366, 1024)), const Size(480, 1024));
    });

    test('leaves a narrow Split View pane alone', () {
      expect(TabletFrame.appSizeFor(const Size(320, 1024)), const Size(320, 1024));
    });
  });

  testWidgets('on a phone the screen and the scaling are untouched', (tester) async {
    final (layout, scaledWidth) = await _run(tester, const Size(393, 852));

    expect(layout, const Size(393, 852));
    expect(scaledWidth, closeTo(393, 0.01));
  });

  testWidgets('on an iPad the app is laid out for the column', (tester) async {
    final (layout, scaledWidth) = await _run(tester, const Size(1024, 1366));

    expect(layout, const Size(480, 1366));
    // The full design width fills the column, not the 1024-pt iPad.
    expect(scaledWidth, closeTo(480, 0.01));
    expect(tester.getSize(find.byType(MaterialApp)).width, 480);
  });
}
