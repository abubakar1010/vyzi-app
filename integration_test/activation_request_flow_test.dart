// End-to-end check of "Attiva una nuova utenza" on a device, against a running
// backend with the seed data (marco.rossi@email.it / Password123!).
//
//   flutter test integration_test/activation_request_flow_test.dart \
//     -d <simulator> \
//     --dart-define=BASE_URL=http://127.0.0.1:3000 \
//     --dart-define=E2E_ADMIN_EMAIL=<admin email> \
//     --dart-define=E2E_ADMIN_PASSWORD=<admin password>
//
// The admin steps (taking the request to "in activation") go straight to the
// API, standing in for the operator in the dashboard.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:integration_test/integration_test.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/features/activation_request/activation_request_detail_screen.dart';
import 'package:vyzi/features/activation_request/activation_request_screen.dart';
import 'package:vyzi/features/home/sign_contract/sign_contract.dart';
import 'package:vyzi/features/my_utility/utility_details_screen.dart';
import 'package:vyzi/features/request/document_viewer_screen.dart';
import 'package:vyzi/app.dart';
import 'package:vyzi/core/controllers/language_controller.dart';
import 'package:vyzi/core/services/cache_service.dart';
import 'package:vyzi/core/services/deep_link_service.dart';
import 'package:vyzi/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

const _customerEmail = 'marco.rossi@email.it';
const _customerPassword = 'Password123!';
const _adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

final _api = Dio(BaseOptions(
  baseUrl: '${ApiConstants.baseUrl}/api/v1',
  validateStatus: (_) => true,
));

Future<Map<String, dynamic>> _login(String email, String password) async {
  final res = await _api.post('/auth/login', data: {'email': email, 'password': password});
  expect(res.statusCode, anyOf(200, 201), reason: 'login $email: ${res.data}');
  return res.data['data'] as Map<String, dynamic>;
}

String _token(Map<String, dynamic> session, String key) =>
    (session[key] ?? (session['tokens'] as Map?)?[key]) as String;

Options _auth(String token) => Options(headers: {'Authorization': 'Bearer $token'});

/// Pumps until [finder] shows up, for screens that load over the network.
Future<void> _waitFor(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 30)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = find
      .byType(Text)
      .evaluate()
      .map((e) => (e.widget as Text).data)
      .whereType<String>()
      .take(40)
      .join(' | ');
  throw TestFailure('Timed out waiting for $finder. On screen: $visible');
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// `main.dart` without the push permission request: on a simulator nobody can
/// answer the native dialog, and `main` waits on it before `runApp`. Every
/// other service starts exactly as it does there.
Future<void> _bootApp() async {
  final deepLinks = DeepLinkService();
  await deepLinks.init();
  Get.put<DeepLinkService>(deepLinks, permanent: true);
  Get.put<NotificationService>(NotificationService(), permanent: true);
  Get.put(LanguageController(), permanent: true);
  timeago.setLocaleMessages('it', timeago.ItMessages());
  await initializeDateFormatting('it');
  await initializeDateFormatting('en');
  runApp(const MyApp());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a subentro requested in the app becomes a utility', (tester) async {
    expect(_adminEmail, isNotEmpty, reason: 'pass --dart-define=E2E_ADMIN_EMAIL');
    expect(_adminPassword, isNotEmpty, reason: 'pass --dart-define=E2E_ADMIN_PASSWORD');

    // Signed in as the customer before the app starts, so the splash screen
    // goes straight to Home.
    final session = await _login(_customerEmail, _customerPassword);

    // A fresh database asks for the legal documents first; that gate has its
    // own flow and is not what this test is about.
    final customerAuth = _auth(_token(session, 'accessToken'));
    final pending = await _api.get('/legal/pending', options: customerAuth);
    final legal = (pending.data['data']['documents'] as List).cast<Map<String, dynamic>>();
    if (legal.isNotEmpty) {
      final accepted = await _api.post(
        '/legal/accept',
        data: {
          'acceptances': [
            for (final doc in legal)
              {'slug': doc['slug'], 'version': doc['version'], 'locale': doc['locale']},
          ],
        },
        options: customerAuth,
      );
      expect(accepted.statusCode, anyOf(200, 201), reason: '${accepted.data}');
    }
    await Firebase.initializeApp();
    await CacheService().init();
    final storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);
    await storage.setString(StorageKeys.authToken, _token(session, 'accessToken'));
    await storage.setString(StorageKeys.refreshToken, _token(session, 'refreshToken'));
    await storage.setString(StorageKeys.userId, (session['user'] as Map)['id'] as String);
    await storage.setBool(StorageKeys.isLoggedIn, true);

    await _bootApp();
    // Home is up once the tab bar is; the card sits further down the page.
    await _waitFor(tester, find.text('Utenze'), timeout: const Duration(seconds: 60));
    await tester.pumpAndSettle();
    final card = find.text('Attiva una nuova utenza');
    await tester.scrollUntilVisible(card, 300,
        scrollable: find.byType(Scrollable).first);

    // ── Home card → the form ──
    await _tapVisible(tester, card);
    expect(find.byType(ActivationRequestScreen), findsOneWidget);

    await tester.tap(find.text('LUCE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SÌ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NO').last);
    await tester.pumpAndSettle();
    expect(find.text('SUBENTRO / LUCE'), findsOneWidget);

    // Prefilled from the profile.
    await _waitFor(tester, find.widgetWithText(TextField, 'Marco'));

    final street = 'Via Integrazione ${DateTime.now().millisecondsSinceEpoch}';
    final fields = find.byType(TextField);
    // Order on screen: first name, last name, phone, street, number, city,
    // CAP, province.
    await tester.enterText(fields.at(3), street);
    await tester.enterText(fields.at(4), '7');
    await tester.enterText(fields.at(5), 'Cagliari');
    await tester.enterText(fields.at(6), '09100');
    await tester.enterText(fields.at(7), 'CA');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byType(Checkbox));
    await _tapVisible(tester, find.byKey(const ValueKey('activation_request.submit')));
    await _waitFor(tester, find.text('Richiesta inviata!'));

    // ── The request is in "Le tue richieste" ──
    await tester.tap(find.text('Vai alle mie richieste'));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Le tue richieste'));
    await _waitFor(tester, find.text('Richieste di attivazione'));
    final card2 = find.ancestor(
      of: find.text('$street 7, 09100 Cagliari (CA)'),
      matching: find.byType(GestureDetector),
    );
    expect(card2, findsWidgets);
    expect(
      find.descendant(of: card2.first, matching: find.text('In attesa di chiamata')),
      findsOneWidget,
    );

    // ── The operator completes it (stands in for the dashboard) ──
    final admin = _token(await _login(_adminEmail, _adminPassword), 'accessToken');
    final list = await _api.get(
      '/cases?caseType=new_activation,takeover&limit=50',
      options: _auth(_token(session, 'accessToken')),
    );
    final cases = (list.data['data']['data'] as List)
        .where((c) => c['supplyStreet'] == street)
        .toList();
    expect(cases, hasLength(1));
    final caseId = cases.single['id'] as String;
    expect(cases.single['caseType'], 'takeover');

    final offers = await _api.get('/offers/admin?energyType=electricity&isActive=true&limit=1',
        options: _auth(admin));
    final offer = offers.data['data']['data'][0] as Map<String, dynamic>;
    final offerId = offer['id'] as String;
    final supplierName = (offer['supplier'] as Map)['name'] as String;
    Future<void> operator(Map<String, Object> body) async {
      final res = await _api.patch('/cases/$caseId', data: body, options: _auth(admin));
      expect(res.statusCode, 200, reason: '${res.data}');
    }

    await operator({'status': 'in_progress', 'internalNotes': 'Staff only'});
    await operator({'selectedOfferId': offerId, 'podPdrNumber': 'IT001E55443322'});

    // ── The contract goes out, with its file ──
    final pdf = '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
        '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
        '3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n'
        'trailer<</Root 1 0 R>>\n%%EOF\n';
    final upload = await _api.post(
      '/upload',
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(pdf.codeUnits,
            filename: 'contratto.pdf', contentType: DioMediaType('application', 'pdf')),
      }),
      options: _auth(admin),
    );
    expect(upload.statusCode, anyOf(200, 201), reason: '${upload.data}');
    final contract = await _api.post(
      '/cases/$caseId/documents',
      data: {
        'documentType': 'contract',
        'fileUrl': upload.data['data']['url'],
        'fileName': 'contratto.pdf',
      },
      options: _auth(admin),
    );
    expect(contract.statusCode, 201, reason: '${contract.data}');
    await operator({'status': 'contract_sent'});

    // ── The customer sees four steps and the agreed contract, never offers ──
    await _tapVisible(tester, find.text('Le tue offerte'));
    await _tapVisible(tester, find.text('Le tue richieste'));
    await _waitFor(tester, find.text('Contratto da firmare'));
    await _tapVisible(tester, find.text('$street 7, 09100 Cagliari (CA)'));
    await _waitFor(tester, find.byType(ActivationRequestDetailScreen));
    await _waitFor(tester, find.text('Caricamento e analisi'));
    expect(find.text('Offerte'), findsNothing);
    await _tapVisible(tester, find.byKey(const ValueKey('activation_request.view_contract')));
    await _waitFor(tester, find.byType(SignContractScreen));
    await _waitFor(tester, find.text(offer['name'] as String));
    await _tapVisible(tester, find.text('Apri il contratto'));
    await _waitFor(tester, find.byType(DocumentViewerScreen));
    Navigator.of(tester.element(find.byType(DocumentViewerScreen))).pop();
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.byIcon(Icons.chevron_left));
    expect(find.byType(BackButton), findsOneWidget, reason: 'the steps screen can be left');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await operator({
      'status': 'awaiting_activation',
      'activationDate': '2026-12-01',
      'expiryDate': '2027-12-01',
    });

    // ── Back in the app it leads on to the utility ──
    await _tapVisible(tester, find.text('Le tue offerte'));
    await _tapVisible(tester, find.text('Le tue richieste'));
    await _waitFor(tester, find.text('In attivazione'));
    await _tapVisible(tester, find.text('$street 7, 09100 Cagliari (CA)'));
    await _waitFor(tester, find.byType(ActivationRequestDetailScreen));
    await _tapVisible(tester, find.byKey(const ValueKey('activation_request.view_utility')));
    await _waitFor(tester, find.byType(UtilityDetailsScreen));
    await _waitFor(tester, find.text('IT001E55443322'));

    // ── And it is listed under Utenze ──
    final services = await _api.get('/meters/my-services',
        options: _auth(_token(session, 'accessToken')));
    final mine = (services.data['data'] as List)
        .where((s) => s['caseId'] == caseId)
        .toList();
    expect(mine, hasLength(1));
    expect(mine.single['billId'], isNull);
    expect(mine.single['podPdrNumber'], 'IT001E55443322');

    // ── Internal notes never reach the customer ──
    final own = await _api.get('/cases/$caseId', options: _auth(_token(session, 'accessToken')));
    expect((own.data['data'] as Map).containsKey('internalNotes'), isFalse);

    Navigator.of(tester.element(find.byType(UtilityDetailsScreen))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('Utenze').last);
    await _waitFor(tester, find.text(supplierName));

    // ── A supply that ends shows as closed, with no way on ──
    await operator({'status': 'activated'});
    await operator({'status': 'terminated'});
    NavHelper.push(ActivationRequestDetailScreen(caseId: caseId));
    await _waitFor(tester, find.text('Terminata'));
    expect(find.byKey(const ValueKey('activation_request.view_contract')), findsNothing);
  });
}
