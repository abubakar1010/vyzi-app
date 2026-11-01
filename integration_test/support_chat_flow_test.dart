// The support chat on a device, against a running backend with the seed data.
//
//   flutter test integration_test/support_chat_flow_test.dart \
//     -d <simulator> \
//     --dart-define=BASE_URL=http://127.0.0.1:3000 \
//     --dart-define=E2E_ADMIN_EMAIL=<admin email> \
//     --dart-define=E2E_ADMIN_PASSWORD=<admin password>
//
// The agent's side goes straight to the API, standing in for the admin desk.
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:vyzi/app.dart';
import 'package:vyzi/core/constants/api_constants.dart';
import 'package:vyzi/core/controllers/language_controller.dart';
import 'package:vyzi/core/navbar/nav_helper.dart';
import 'package:vyzi/core/services/cache_service.dart';
import 'package:vyzi/core/services/deep_link_service.dart';
import 'package:vyzi/core/services/notification_service.dart';
import 'package:vyzi/core/services/storage_service.dart';
import 'package:vyzi/features/support/my_tickets_screen.dart';
import 'package:vyzi/features/support/ticket_detail_screen.dart';
import 'package:vyzi/features/support/ticket_info_screen.dart';

const _customerEmail = 'marco.rossi@email.it';
const _customerPassword = 'Password123!';
const _adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
const _adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

final _api = Dio(BaseOptions(
  baseUrl: '${ApiConstants.baseUrl}/api/v1',
  validateStatus: (_) => true,
));

Options _auth(String token) => Options(headers: {'Authorization': 'Bearer $token'});

Future<Map<String, dynamic>> _login(String email, String password) async {
  final res = await _api.post('/auth/login', data: {'email': email, 'password': password});
  expect(res.statusCode, anyOf(200, 201), reason: 'login $email: ${res.data}');
  return res.data['data'] as Map<String, dynamic>;
}

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

  testWidgets('a customer and an agent talk on a ticket until it closes', (tester) async {
    expect(_adminEmail, isNotEmpty, reason: 'pass --dart-define=E2E_ADMIN_EMAIL');

    final session = await _login(_customerEmail, _customerPassword);
    final customer = session['accessToken'] as String;
    final customerId = (session['user'] as Map)['id'] as String;
    final adminSession = await _login(_adminEmail, _adminPassword);
    final admin = adminSession['accessToken'] as String;
    final adminId = (adminSession['user'] as Map)['id'] as String;

    final pending = await _api.get('/legal/pending', options: _auth(customer));
    final legal = (pending.data['data']['documents'] as List).cast<Map<String, dynamic>>();
    if (legal.isNotEmpty) {
      await _api.post(
        '/legal/accept',
        data: {
          'acceptances': [
            for (final doc in legal)
              {'slug': doc['slug'], 'version': doc['version'], 'locale': doc['locale']},
          ],
        },
        options: _auth(customer),
      );
    }

    // ── The customer writes, and an agent takes the ticket and answers ──
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final subject = 'Bolletta non chiara $stamp';
    final question = 'Non capisco la mia bolletta $stamp';
    final answer = 'Controllo subito $stamp';
    final topics = await _api.get('/support/topics', options: _auth(customer));
    final topicId = (topics.data['data'] as List).first['id'] as String;
    final created = await _api.post(
      '/support/tickets',
      data: {'topicId': topicId, 'subject': subject, 'message': question},
      options: _auth(customer),
    );
    expect(created.statusCode, 201, reason: '${created.data}');
    final ticketId = created.data['data']['id'] as String;
    expect('${created.data}', isNot(contains('firebaseUid')));

    final assigned = await _api.patch(
      '/support/tickets/$ticketId',
      data: {'assignedAgentId': adminId, 'status': 'in_progress'},
      options: _auth(admin),
    );
    expect(assigned.statusCode, 200, reason: '${assigned.data}');
    final replied = await _api.post(
      '/support/tickets/$ticketId/messages',
      data: {'message': answer},
      options: _auth(admin),
    );
    expect(replied.statusCode, 201, reason: '${replied.data}');

    await Firebase.initializeApp();
    await CacheService().init();
    final storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);
    await storage.setString(StorageKeys.authToken, customer);
    await storage.setString(StorageKeys.refreshToken, session['refreshToken'] as String);
    await storage.setString(StorageKeys.userId, customerId);
    await storage.setBool(StorageKeys.isLoggedIn, true);

    await _bootApp();
    await _waitFor(tester, find.text('Utenze'));

    // ── The ticket is on the list; its details lead on to the conversation ──
    NavHelper.push(const MyTicketsScreen());
    await _waitFor(tester, find.text(subject));
    await tester.tap(find.text(subject));
    await _waitFor(tester, find.byType(TicketInfoScreen));
    await _waitFor(tester, find.text(question));
    await _waitFor(tester, find.text('2 messaggi'));
    await tester.ensureVisible(find.text('Conversazione'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conversazione'));
    await _waitFor(tester, find.byType(TicketDetailScreen));
    await _waitFor(tester, find.text(question));
    await _waitFor(tester, find.text(answer));

    // ── The agent is shown by name, on the other side from the customer ──
    final agentRows = await _api.get(
      '/support/tickets/$ticketId/messages',
      options: _auth(customer),
    );
    final agent = (agentRows.data['data'] as List).last['sender'] as Map;
    expect(agent.keys.toSet(), {'id', 'firstName', 'lastName'});
    final agentName = '${agent['firstName']} ${agent['lastName']}'.trim();
    expect(find.text(agentName), findsWidgets);
    expect(
      tester.getCenter(find.text(question)).dx,
      greaterThan(tester.getCenter(find.text(answer)).dx),
      reason: 'own messages sit on the right, the agent on the left',
    );

    // ── Sending from the app works and lands on the agent's side ──
    final reply = 'Grazie, attendo $stamp';
    await tester.enterText(find.byType(TextField), reply);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await _waitFor(tester, find.text(reply));
    final desk = await _api.get('/support/tickets/$ticketId', options: _auth(admin));
    final deskMessages = (desk.data['data']['messages'] as List).cast<Map>();
    expect(deskMessages.map((m) => m['message']), contains(reply));
    expect(desk.data['data']['assignedAgent']['email'], _adminEmail);

    // ── Back on the details, the count has caught up ──
    Navigator.of(tester.element(find.byType(TicketDetailScreen))).pop();
    await _waitFor(tester, find.text('3 messaggi'));
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(TicketInfoScreen))).pop();
    await tester.pumpAndSettle();

    // ── A closed ticket reads as closed, with nowhere to type ──
    await _api.patch(
      '/support/tickets/$ticketId',
      data: {'status': 'closed'},
      options: _auth(admin),
    );
    NavHelper.push(TicketDetailScreen(ticketId: ticketId));
    await _waitFor(tester, find.text(reply));
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
