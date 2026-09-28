import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/core/services/api_service.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';
import 'package:vyzi/features/request/offer_details.dart';
import 'package:vyzi/features/request/price_calculation_dialog.dart';
import 'package:vyzi/features/request/price_type_sheet.dart';

/// Offer Details used to explain every offer the same way: one popup about the
/// indexed price and one showing a hardcoded `PUN GME + 0,01 €/KWh`, opened by
/// matching the tapped link against a translated string. A customer looking at
/// a fixed-price offer was told their price follows the wholesale market and
/// shown a formula that contradicted the flat rate printed one row above it.
///
/// What the popups say now comes from the offer's own market type, so these
/// tests pin both branches: an indexed offer gets the index popup *and* the
/// formula popup carrying its real index and spread, a fixed offer gets the
/// fixed-price popup alone and nothing on the screen mentions PUN, indexation
/// or a spread.
void main() {
  setUpAll(() {
    // Never hit the network for fonts in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiService().dio.httpClientAdapter = HttpClientAdapter();
    Get.reset();
  });

  // ── The field the whole thing hangs off ───────────────────────────────────

  group('market type', () {
    test('variable and indexed both count as index-tracking, fixed does not',
        () {
      expect(_offer(marketType: 'indexed').isIndexedPrice, isTrue);
      expect(_offer(marketType: 'variable').isIndexedPrice, isTrue);
      expect(_offer(marketType: 'fixed').isIndexedPrice, isFalse);
      // An offer whose market type never made it into the payload is not
      // silently explained as indexed.
      expect(_offer(marketType: '').isIndexedPrice, isFalse);
    });

    test('the index named is the one that fuel actually follows', () {
      expect(_offer(marketType: 'indexed').priceIndexLabel, 'PUN GME');
      expect(
        _offer(marketType: 'variable', energyType: 'gas').priceIndexLabel,
        'PSV',
      );
    });
  });

  // ── Popup 1: what the price type means ────────────────────────────────────

  group('price-type popup', () {
    testWidgets('an indexed offer is explained through its index',
        (tester) async {
      await _pumpDialog(
        tester,
        (offer) => PriceTypeSheet(offer: offer),
        offer: _offer(marketType: 'indexed', spread: 0.0125),
      );

      expect(find.text('Indexed price: how does it work?'), findsOneWidget);
      expect(find.text('Fixed price: what does it mean?'), findsNothing);
      expect(_screenText(tester), contains('PUN GME'));
    });

    testWidgets('a gas offer is explained through the PSV, not the PUN',
        (tester) async {
      await _pumpDialog(
        tester,
        (offer) => PriceTypeSheet(offer: offer),
        offer: _offer(
          marketType: 'variable',
          energyType: 'gas',
          spread: 0.043,
        ),
      );

      final text = _screenText(tester);
      expect(text, contains('PSV'));
      // The price row behind this popup reads "PSV + …"; naming the PUN here
      // would describe a different market from the one the offer tracks.
      expect(text, isNot(contains('PUN')));
    });

    testWidgets('a fixed offer gets its own copy, free of index language',
        (tester) async {
      await _pumpDialog(
        tester,
        (offer) => PriceTypeSheet(offer: offer),
        offer: _offer(marketType: 'fixed', pricePerKwh: 0.134),
      );

      expect(find.text('Fixed price: what does it mean?'), findsOneWidget);
      expect(find.text('Indexed price: how does it work?'), findsNothing);
      _expectNoIndexLanguage(tester);
    });
  });

  // ── Popup 2: how the price is calculated ──────────────────────────────────

  group('price-calculation popup', () {
    testWidgets('the formula carries the offer\'s own index and spread',
        (tester) async {
      await _pumpDialog(
        tester,
        (offer) => PriceCalculationDialog(offer: offer),
        offer: _offer(marketType: 'indexed', spread: 0.0125),
      );

      expect(find.text('PUN GME'), findsOneWidget);
      expect(find.text(formatUnitPrice(0.0125, unit: 'kWh')), findsOneWidget);
      // The figure the dialog shipped with, shown for every offer regardless
      // of what the supplier actually charges.
      expect(_screenText(tester), isNot(contains('0,01 €/KWh')));
    });

    testWidgets('a gas offer gets the PSV and a price per Sm³', (tester) async {
      await _pumpDialog(
        tester,
        (offer) => PriceCalculationDialog(offer: offer),
        offer: _offer(
          marketType: 'variable',
          energyType: 'gas',
          spread: 0.043,
        ),
      );

      expect(find.text('PSV'), findsOneWidget);
      expect(find.text(formatUnitPrice(0.043, unit: 'Sm³')), findsOneWidget);
    });
  });

  // ── The screen that decides which of them opens ───────────────────────────

  group('offer details screen', () {
    testWidgets('an indexed offer offers both explanations', (tester) async {
      await _pumpScreen(
        tester,
        _offerJson(marketType: 'indexed', spread: 0.0125),
      );

      expect(find.text('What does this mean?'), findsOneWidget);
      expect(find.text('How is it calculated?'), findsOneWidget);

      await tester.tap(find.text('What does this mean?'));
      await tester.pumpAndSettle();
      expect(find.text('Indexed price: how does it work?'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('How is it calculated?'));
      await tester.pumpAndSettle();
      expect(find.text('Price Calculation'), findsOneWidget);
      expect(find.text(formatUnitPrice(0.0125, unit: 'kWh')), findsOneWidget);
    });

    testWidgets('a fixed offer offers the fixed explanation alone',
        (tester) async {
      await _pumpScreen(
        tester,
        _offerJson(marketType: 'fixed', pricePerKwh: 0.134),
      );

      expect(find.text('What does this mean?'), findsOneWidget);
      // Nothing is worked out from a formula here, so the link that would open
      // one is not offered at all.
      expect(find.text('How is it calculated?'), findsNothing);
      expect(find.text(formatUnitPrice(0.134, unit: 'kWh')), findsOneWidget);
      _expectNoIndexLanguage(tester);

      await tester.tap(find.text('What does this mean?'));
      await tester.pumpAndSettle();

      expect(find.text('Fixed price: what does it mean?'), findsOneWidget);
      expect(find.text('Price Calculation'), findsNothing);
      _expectNoIndexLanguage(tester);
    });
  });
}

// ── Harness ─────────────────────────────────────────────────────────────────

/// Every word the fixed-price branch has to stay clear of, per the offer-type
/// popup rules: no index, no indexation, no spread.
const _indexLanguage = <String>['PUN', 'PSV', 'spread', 'indexed', 'indicizzat'];

ApiOfferModel _offer({
  required String marketType,
  String energyType = 'electricity',
  double? pricePerKwh,
  double? spread,
}) =>
    ApiOfferModel.fromJson(_offerJson(
      marketType: marketType,
      energyType: energyType,
      pricePerKwh: pricePerKwh,
      spread: spread,
    ));

Map<String, dynamic> _offerJson({
  required String marketType,
  String energyType = 'electricity',
  double? pricePerKwh,
  double? spread,
}) =>
    <String, dynamic>{
      'id': 'offer-1',
      'billId': 'bill-1',
      'name': 'Casa Sicura',
      'energyType': energyType,
      'marketType': marketType,
      'pricePerKwh': pricePerKwh,
      'spread': spread,
      'fixedMonthlyFee': 12.0,
      'contractDurationDays': 365,
      'paymentMethod': 'direct_debit',
      'estimatedSavings': 351.13,
      'supplier': <String, dynamic>{'id': 'sup-1', 'name': 'Duferco'},
    };

/// Text actually painted on screen, joined so assertions can look for a phrase
/// wherever it landed.
String _screenText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');

void _expectNoIndexLanguage(WidgetTester tester) {
  final text = _screenText(tester);
  for (final word in _indexLanguage) {
    expect(
      text.toLowerCase(),
      isNot(contains(word.toLowerCase())),
      reason: 'a fixed-price offer must not mention "$word"; screen read:\n'
          '$text',
    );
  }
}

Future<void> _pumpDialog(
  WidgetTester tester,
  Widget Function(ApiOfferModel offer) build, {
  required ApiOfferModel offer,
}) async {
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showDialog(context: context, builder: (_) => build(offer)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  // Guard the harness itself: assertions against a dialog that never opened
  // would all pass vacuously.
  expect(find.byType(Dialog), findsOneWidget);
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Map<String, dynamic> offerJson,
) async {
  tester.view
    ..physicalSize = const Size(392, 876)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  ApiService().dio.httpClientAdapter = _StubAdapter(<String, dynamic>{
    'success': true,
    'data': offerJson,
  });

  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: const OfferDetailsScreen(offerId: 'offer-1', billId: 'bill-1'),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Offer Details'), findsOneWidget);
}

/// Answers every request with one canned offer payload, so the screen can be
/// driven without a server.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body);

  final Map<String, dynamic> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
