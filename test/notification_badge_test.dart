import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/core/utils/app_colors.dart';
import 'package:vyzi/core/widgets/notification_icon_button.dart';
import 'package:vyzi/features/notifications/controller/notification_controller.dart';
import 'package:vyzi/features/notifications/models/notification_model.dart';

/// The unread badge stopped tracking the real count. `NotificationController`
/// was registered with a plain `Get.put()` from inside a widget, so under
/// GetX's default `SmartManagement.full` it was tied to the route that built
/// it: the bell and the notification screen could end up holding two different
/// instances, and the count was only ever fetched once, at creation.
void main() {
  // `NotificationController.onInit` registers a lifecycle observer, so the
  // binding has to exist even for the non-widget tests below.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // StorageService.init() preloads the auth tokens from secure storage.
    _setSecureStorageMock(enabled: true);
  });

  tearDown(() => _setSecureStorageMock(enabled: false));

  tearDown(() async {
    // `Get.reset()` drops the registry without disposing, which would leave
    // the controller registered as a lifecycle observer.
    if (Get.isRegistered<NotificationController>()) {
      await Get.delete<NotificationController>(force: true);
    }
    Get.reset();
  });

  group('controller identity', () {
    test('every caller gets the same instance', () {
      final first = NotificationController.to;
      final second = NotificationController.to;

      expect(identical(first, second), isTrue);
      expect(Get.find<NotificationController>(), same(first));
    });

    test('survives a route-scoped delete sweep', () async {
      final controller = NotificationController.to;
      await _settle(); // let the fetch that onInit starts finish first
      controller.unreadCount.value = 4;

      // What GetX does when the route that created a dependency is popped.
      await Get.delete<NotificationController>();

      expect(Get.isRegistered<NotificationController>(), isTrue,
          reason: 'a permanent instance must outlive the route that built it');
      expect(NotificationController.to, same(controller));
      expect(NotificationController.to.unreadCount.value, 4);
    });

    test('clear() wipes the signed-out user\'s state', () {
      final controller = NotificationController.to
        ..unreadCount.value = 7
        ..notifications.add(_notification(id: 'n1', isRead: false))
        ..currentPage.value = 3
        ..totalPages.value = 5;

      NotificationController.reset();

      expect(controller.unreadCount.value, 0);
      expect(controller.notifications, isEmpty);
      expect(controller.currentPage.value, 1);
      expect(controller.totalPages.value, 1);
    });
  });

  group('user scoping', () {
    Future<StorageService> registerStorage(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final storage = StorageService();
      await storage.init();
      Get.put<StorageService>(storage, permanent: true);
      return storage;
    }

    test('a different user does not inherit the previous badge', () async {
      final storage = await registerStorage(<String, Object>{
        'is_logged_in': false,
        'user_id': 'user-a',
      });

      final controller = NotificationController.to;
      // Binds the loaded state to user-a.
      await controller.refreshUnreadCount(force: true);

      controller.unreadCount.value = 6;
      controller.notifications.add(_notification(id: 'n1', isRead: false));

      // Force-logout (or a second account signing in) swaps the stored id.
      await storage.setString('user_id', 'user-b');
      await controller.refreshUnreadCount(force: true);

      expect(controller.unreadCount.value, 0);
      expect(controller.notifications, isEmpty,
          reason: 'the previous user\'s notifications must be dropped');
    });

    test('the same user keeps their loaded list', () async {
      await registerStorage(<String, Object>{
        'is_logged_in': false,
        'user_id': 'user-a',
      });

      final controller = NotificationController.to;
      await controller.refreshUnreadCount(force: true);

      controller.notifications.add(_notification(id: 'n1', isRead: false));
      await controller.refreshUnreadCount(force: true);

      expect(controller.notifications, hasLength(1));
    });
  });

  group('badge rendering', () {
    Future<NotificationController> pumpBell(
      WidgetTester tester, {
      double textScale = 1.0,
    }) async {
      tester.view
        ..physicalSize = const Size(392, 876)
        ..devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_harness());
      await tester.pump();
      return NotificationController.to;
    }

    testWidgets('no badge when nothing is unread', (tester) async {
      final controller = await pumpBell(tester);

      controller.unreadCount.value = 0;
      await tester.pump();

      expect(_badgeFinder, findsNothing);
    });

    testWidgets('the badge follows the shared controller', (tester) async {
      final controller = await pumpBell(tester);

      controller.unreadCount.value = 3;
      await tester.pump();
      expect(find.text('3'), findsOneWidget);

      // What the notification screen does on "mark all read" — the bell must
      // see it, because it is the same instance.
      NotificationController.to.unreadCount.value = 0;
      await tester.pump();
      expect(_badgeFinder, findsNothing);
    });

    testWidgets('caps at 99+', (tester) async {
      final controller = await pumpBell(tester);

      controller.unreadCount.value = 99;
      await tester.pump();
      expect(find.text('99'), findsOneWidget);

      controller.unreadCount.value = 100;
      await tester.pump();
      expect(find.text('99+'), findsOneWidget);
    });

    for (final textScale in <double>[1.0, 1.3, 2.0]) {
      testWidgets('the count stays inside the badge at textScale $textScale',
          (tester) async {
        final controller = await pumpBell(tester, textScale: textScale);

        for (final count in <int>[1, 9, 42, 100]) {
          controller.unreadCount.value = count;
          await tester.pump();

          expect(tester.takeException(), isNull,
              reason: 'count $count overflowed at textScale $textScale');

          final badge = tester.getRect(_badgeFinder);
          final label = tester.renderObject<RenderParagraph>(
            find.descendant(of: _badgeFinder, matching: find.byType(Text)),
          );

          // Intrinsics, not the laid-out rect: the pill is a fixed-size box,
          // so an oversized label is silently *clipped* rather than reported
          // as an overflow. What must hold is that the label's natural size
          // still fits the pill it is centred in.
          expect(
            label.getMaxIntrinsicHeight(double.infinity),
            lessThanOrEqualTo(badge.height + 0.5),
            reason: 'count $count is clipped vertically at '
                'textScale $textScale',
          );
          expect(
            label.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(badge.width + 0.5),
            reason: 'count $count is clipped horizontally at '
                'textScale $textScale',
          );
        }
      });
    }
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

final Finder _badgeFinder = find.byWidgetPredicate(
  (widget) =>
      widget is Container &&
      widget.decoration is BoxDecoration &&
      (widget.decoration! as BoxDecoration).color == AppColors.red100,
);

/// Drains the microtask queue so a fetch started by `onInit` cannot land in
/// the middle of an assertion.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

NotificationModel _notification({required String id, required bool isRead}) {
  return NotificationModel(
    id: id,
    userId: 'user-a',
    title: 'Bolletta analizzata',
    body: 'La tua bolletta è pronta',
    type: 'bill_analyzed',
    isRead: isRead,
    createdAt: DateTime(2026, 1, 1).toIso8601String(),
    updatedAt: DateTime(2026, 1, 1).toIso8601String(),
  );
}

Widget _harness() {
  return DefaultAssetBundle(
    bundle: _FakeAssetBundle(),
    child: ScreenUtilInit(
      designSize: const Size(392, 876),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: NotificationIconButton(iconSize: 26, onTap: () {}),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Serves a 1x1 transparent PNG for every asset so `Image.asset` resolves
/// without the real asset bundle.
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
    return parser(
        const StandardMessageCodec().encodeMessage(<String, Object>{})!);
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
