import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/core/navbar/navbar_controller.dart';
import 'package:vyzi/core/services/notification_router.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/activation_request/activation_request_detail_screen.dart';
import 'package:vyzi/features/bills/models/bill_model.dart';
import 'package:vyzi/features/bills/screen/bill_detail_screen.dart';
import 'package:vyzi/features/home/sign_contract/sign_contract.dart';
import 'package:vyzi/features/my_utility/service_details_screen.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';
import 'package:vyzi/features/request/request_controller.dart';
import 'package:vyzi/features/request/request_offers_focus.dart';
import 'package:vyzi/routes/app_routes.dart';

/// "New offers recommended for you" used to open the request detail — a page
/// that reports the offers were sent without showing one of them. It now opens
/// Request → Your Offers, narrowed to the request the notification named.
///
/// Two halves are covered here: the parked intent that carries a bill id from
/// a tap to whenever the tab is next mounted, and the scoping the tab applies
/// once it has one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // StorageService.init() preloads the auth tokens from secure storage.
  setUp(() => _setSecureStorageMock(enabled: true));

  tearDown(() {
    _setSecureStorageMock(enabled: false);
    RequestOffersFocus.clear();
    Get.reset();
  });

  group('RequestOffersFocus', () {
    Future<StorageService> signIn(String userId) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_id': userId,
      });
      final storage = StorageService();
      await storage.init();
      Get.put<StorageService>(storage, permanent: true);
      return storage;
    }

    test('a parked bill is handed over exactly once', () async {
      await signIn('user-a');

      RequestOffersFocus.requestBill('bill-1');

      expect(RequestOffersFocus.take(), 'bill-1');
      expect(RequestOffersFocus.take(), isNull,
          reason: 'an acted-on intent must not re-apply on the next tab switch');
    });

    test('an empty bill id raises nothing', () async {
      await signIn('user-a');

      RequestOffersFocus.requestBill('');

      expect(RequestOffersFocus.take(), isNull);
    });

    test('fires again for the same bill', () async {
      await signIn('user-a');

      // Tapping the same notification twice has to scope the list twice; a
      // value-based notifier would swallow the repeat.
      final seen = <String>[];
      final sub = RequestOffersFocus.stream.listen(seen.add);

      RequestOffersFocus.requestBill('bill-1');
      RequestOffersFocus.requestBill('bill-1');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen, <String>['bill-1', 'bill-1']);
    });

    test('the next account does not inherit it', () async {
      final storage = await signIn('user-a');
      RequestOffersFocus.requestBill('bill-1');

      // A forced sign-out from the Dio interceptor swaps the stored id without
      // going anywhere near this class.
      await storage.setString('user_id', 'user-b');

      expect(RequestOffersFocus.take(), isNull,
          reason: 'user-b does not own bill-1, and would see an empty list');
    });
  });

  group('NotificationRouter', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'user_id': 'user-a',
      });
      final storage = StorageService();
      await storage.init();
      Get.put<StorageService>(storage, permanent: true);
      Get.put(NavbarController());
    });

    /// The route table the router addresses, behind stub pages, and a shell
    /// that keeps one navigator per tab as the real one does. What is under
    /// test is which destination each notification type resolves to.
    Future<void> pumpShell(WidgetTester tester) async {
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(392, 876),
        builder: (context, child) => GetMaterialApp(
          initialRoute: AppRoutes.navbarScreen,
          getPages: <GetPage<dynamic>>[
            GetPage<dynamic>(
              name: AppRoutes.navbarScreen,
              page: () => const _StubShell(),
            ),
            for (final name in <String>[
              AppRoutes.billDetailScreen,
              AppRoutes.signContractScreen,
              AppRoutes.ticketDetailScreen,
              AppRoutes.inviteFriendsScreen,
              AppRoutes.notificationsScreen,
            ])
              GetPage<dynamic>(name: name, page: () => const SizedBox.shrink()),
          ],
        ),
      ));
      await tester.pumpAndSettle();
    }

    /// The real screen a notification opened, which lands inside the Request
    /// tab rather than on a route pushed over the whole shell.
    void expectOpenedInRequestTab(Type screen) {
      expect(Get.currentRoute, AppRoutes.navbarScreen,
          reason: 'it opens inside the shell, not over it');
      expect(Get.find<NavbarController>().selectedIndex, NavTabs.request);
      expect(find.byType(screen), findsOneWidget);
    }

    testWidgets('a tapped push asks the Request tab for that bill',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromPush(<String, dynamic>{
        'type': 'offer_available',
        'billId': 'bill-1',
        'entityType': 'bill',
        'entityId': 'bill-1',
      });
      await tester.pumpAndSettle();

      expect(RequestOffersFocus.take(), 'bill-1');
      expect(Get.currentRoute, AppRoutes.navbarScreen,
          reason: 'the offers live in the Request tab, not on a pushed route');
    });

    testWidgets('a row in the Notifications section asks for the same thing',
        (tester) async {
      // The three entry points share one destination table; this is the one
      // that used to carry its own copy.
      await pumpShell(tester);

      NotificationRouter.openFromList(
        type: 'offer_available',
        data: <String, dynamic>{'billId': 'bill-1'},
      );
      await tester.pumpAndSettle();

      expect(RequestOffersFocus.take(), 'bill-1');
      expect(Get.currentRoute, AppRoutes.navbarScreen);
    });

    testWidgets('comes back to the shell from a pushed route', (tester) async {
      await pumpShell(tester);
      Get.toNamed(AppRoutes.billDetailScreen, arguments: 'bill-9');
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.billDetailScreen);

      NotificationRouter.openFromPush(<String, dynamic>{
        'type': 'offer_available',
        'billId': 'bill-1',
      });
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.navbarScreen,
          reason: 'switching tabs behind a full-screen route shows nothing');
    });

    testWidgets('an offer notification with no bill scopes nothing',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromList(
        type: 'offer_available',
        data: const <String, dynamic>{},
      );
      await tester.pumpAndSettle();

      // Still the Request tab — just the whole list, rather than an empty one
      // scoped to a request the payload never named.
      expect(RequestOffersFocus.take(), isNull);
      expect(Get.currentRoute, AppRoutes.navbarScreen);
    });

    testWidgets('a contract notification still opens the signing screen',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromList(
        type: 'contract_status',
        data: <String, dynamic>{'billId': 'bill-1'},
      );
      await tester.pumpAndSettle();

      expectOpenedInRequestTab(SignContractScreen);
      expect(RequestOffersFocus.take(), isNull);
    });

    testWidgets('a verification notification still opens the request detail',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromPush(<String, dynamic>{
        'type': 'bill_verification',
        'billId': 'bill-1',
      });
      await tester.pumpAndSettle();

      expectOpenedInRequestTab(BillDetailScreen);
    });

    // An activation request ("Attiva una nuova utenza") has no bill; its
    // milestones carry only the case.
    testWidgets('a contract milestone with no bill opens the contract by case',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromPush(<String, dynamic>{
        'type': 'contract_status',
        'caseId': 'case-1',
        'entityType': 'case',
        'entityId': 'case-1',
      });
      await tester.pumpAndSettle();

      expectOpenedInRequestTab(SignContractScreen);
      final screen =
          tester.widget<SignContractScreen>(find.byType(SignContractScreen));
      expect(screen.caseId, 'case-1');
      expect(screen.billId, isNull);
    });

    testWidgets('an activated activation request opens its utility',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromList(
        type: 'activation_complete',
        data: <String, dynamic>{'caseId': 'case-1'},
      );
      await tester.pumpAndSettle();

      expectOpenedInRequestTab(ServiceDetailsScreen);
    });

    testWidgets('a closed activation request opens on its steps',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromPush(<String, dynamic>{
        'type': 'case_update',
        'caseId': 'case-1',
      });
      await tester.pumpAndSettle();

      expectOpenedInRequestTab(ActivationRequestDetailScreen);
    });

    testWidgets('a case notification that also names its bill still opens by bill',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromPush(<String, dynamic>{
        'type': 'case_update',
        'billId': 'bill-1',
        'caseId': 'case-1',
      });
      await tester.pumpAndSettle();

      expectOpenedInRequestTab(BillDetailScreen);
    });

    testWidgets('a push of an unknown type falls back to the centre',
        (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromPush(<String, dynamic>{'billId': 'bill-1'});
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.notificationsScreen);
    });

    testWidgets('an unknown type in the list stays put', (tester) async {
      await pumpShell(tester);

      NotificationRouter.openFromList(type: 'general');
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.navbarScreen,
          reason: 'the list is the centre; it must not push a second copy');
    });
  });

  group('RequestController bill scope', () {
    late RequestController controller;

    setUp(() {
      controller = RequestController()
        ..offers = <ApiOfferModel>[
          _offer(
              id: 'o1',
              billId: 'bill-1',
              paymentMethod: OfferPaymentMethod.directDebit),
          _offer(
              id: 'o2',
              billId: 'bill-1',
              paymentMethod: OfferPaymentMethod.postalOrder),
          _offer(
              id: 'o3',
              billId: 'bill-2',
              paymentMethod: OfferPaymentMethod.postalOrder),
        ]
        // Pre-loaded so focusBill() does not reach for the network to fill in
        // the banner label.
        ..bills = <BillModel>[_bill('bill-1'), _bill('bill-2')];
    });

    tearDown(() => controller.dispose());

    test('shows every offer until a request is named', () {
      expect(controller.isBillFocused, isFalse);
      expect(controller.filteredOffers.map((o) => o.id),
          <String>['o1', 'o2', 'o3']);
    });

    test('narrows to the offers sent for the named request', () {
      controller.focusBill('bill-1');

      expect(controller.isBillFocused, isTrue);
      expect(controller.filteredOffers.map((o) => o.id), <String>['o1', 'o2']);
    });

    test('the payment chips narrow the scope, not the whole list', () {
      controller.focusBill('bill-1');
      controller.selectPaymentFilter(OfferPaymentMethod.postalOrder);

      // o3 also takes a postal order, but belongs to another request.
      expect(controller.filteredOffers.map((o) => o.id), <String>['o2']);
    });

    test('a leftover payment chip cannot empty the list on arrival', () {
      controller.selectPaymentFilter(OfferPaymentMethod.postalOrder);

      controller.focusBill('bill-1');

      expect(controller.paymentFilter, RequestController.paymentFilterAll);
      expect(controller.filteredOffers.map((o) => o.id), <String>['o1', 'o2']);
    });

    test('a request with no offers is empty rather than unfiltered', () {
      controller.focusBill('bill-3');

      // The screen tells the customer this request has nothing on it yet — it
      // must not quietly fall back to showing every other request's offers.
      expect(controller.scopedOffers, isEmpty);
      expect(controller.filteredOffers, isEmpty);
    });

    test('clearing the scope widens the list again', () {
      controller.focusBill('bill-1');
      controller.clearBillFocus();

      expect(controller.isBillFocused, isFalse);
      expect(controller.filteredOffers.map((o) => o.id),
          <String>['o1', 'o2', 'o3']);
    });

    test('names the request the banner is about', () {
      controller.focusBill('bill-1');

      expect(controller.focusedBill?.id, 'bill-1');
    });

    test('leaves the banner unnamed rather than wrong', () {
      controller.bills = <BillModel>[];

      controller.focusBill('bill-1');

      expect(controller.focusedBill, isNull);
      expect(controller.isBillFocused, isTrue,
          reason: 'the scope holds whether or not its label has loaded');
    });
  });
}

ApiOfferModel _offer({
  required String id,
  required String billId,
  String paymentMethod = OfferPaymentMethod.both,
}) =>
    ApiOfferModel(
      id: id,
      billId: billId,
      name: 'Offer $id',
      energyType: 'electricity',
      marketType: 'fixed',
      pricePerKwh: 0.12,
      paymentMethod: paymentMethod,
    );

BillModel _bill(String id) => BillModel.fromJson(<String, dynamic>{
      'id': id,
      'billType': 'electricity',
      'status': 'offer_sent',
      'userId': 'user-a',
      'createdAt': '2026-08-01T00:00:00.000Z',
      'updatedAt': '2026-08-01T00:00:00.000Z',
    });

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

/// The tab shell cut down to its navigators: one per tab, behind an
/// [IndexedStack], keyed as [NavbarController] expects.
class _StubShell extends StatelessWidget {
  const _StubShell();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavbarController>();
    return Obx(
      () => IndexedStack(
        index: controller.selectedIndex,
        children: [
          for (final key in controller.navigatorKeys)
            Navigator(
              key: key,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
