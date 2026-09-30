import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/core/utils/number_format.dart';
import 'package:vyzi/features/request/models/api_offer_model.dart';

/// The energy price row on the offer list card used to read the same way for
/// every offer — `Prezzo Energia : €0,140/kWh` — so a customer could not tell
/// a locked price from one that follows the market. The spec now words it by
/// offer type and drops trailing zeros, and these tests pin both halves.
void main() {
  setUp(() {
    Get.addTranslations(AppTranslations().keys);
    Get.locale = const Locale('it', 'IT');
  });

  tearDown(Get.reset);

  group('formatUnitPriceCompactValue', () {
    test('drops trailing zeros down to two decimals', () {
      expect(formatUnitPriceCompactValue(0.140), '0,14');
      expect(formatUnitPriceCompactValue(0.100), '0,10');
      expect(formatUnitPriceCompactValue('0.140000'), '0,14');
    });

    test('keeps a meaningful third decimal', () {
      expect(formatUnitPriceCompactValue(0.134), '0,134');
      expect(formatUnitPriceCompactValue(0.025), '0,025');
    });

    test('still rounds to the unit-price scale', () {
      expect(formatUnitPriceCompactValue(0.12849), '0,128');
    });

    test('shows a dash for a missing price', () {
      expect(formatUnitPriceCompactValue(null), kMissingValue);
    });
  });

  group('energyPriceRow', () {
    test('a fixed offer says so and shows the flat rate', () {
      expect(
        _offer(marketType: 'fixed', pricePerKwh: 0.140).energyPriceRow,
        'Prezzo Energia (Fisso): €0,14/kWh',
      );
    });

    test('a fixed gas offer quotes per Sm³', () {
      expect(
        _offer(marketType: 'fixed', energyType: 'gas', pricePerSmc: 0.52)
            .energyPriceRow,
        'Prezzo Energia (Fisso): €0,52/Sm³',
      );
    });

    test('a variable offer shows the index plus its spread', () {
      expect(
        _offer(marketType: 'variable', spread: 0.025).energyPriceRow,
        'Prezzo Energia: PUN + 0,025 €/kWh',
      );
      expect(
        _offer(marketType: 'indexed', spread: 0.010).energyPriceRow,
        'Prezzo Energia: PUN + 0,01 €/kWh',
      );
    });

    test('a variable offer with no spread on record names the term', () {
      expect(
        _offer(marketType: 'variable').energyPriceRow,
        'Prezzo Energia: PUN + Spread',
      );
    });

    test('a variable gas offer follows PSV', () {
      expect(
        _offer(marketType: 'variable', energyType: 'gas', spread: 0.04)
            .energyPriceRow,
        'Prezzo Energia: PSV + 0,04 €/Sm³',
      );
    });

    test('reads in English when the customer picked it', () {
      Get.locale = const Locale('en', 'US');

      expect(
        _offer(marketType: 'fixed', pricePerKwh: 0.140).energyPriceRow,
        'Energy Price (Fixed): €0.14/kWh',
      );
      expect(
        _offer(marketType: 'variable', spread: 0.025).energyPriceRow,
        'Energy Price: PUN + 0.025 €/kWh',
      );
    });
  });
}

ApiOfferModel _offer({
  required String marketType,
  String energyType = 'electricity',
  double? pricePerKwh,
  double? pricePerSmc,
  double? spread,
}) =>
    ApiOfferModel(
      id: 'offer-1',
      name: 'FIX PROVA',
      energyType: energyType,
      marketType: marketType,
      pricePerKwh: pricePerKwh,
      pricePerSmc: pricePerSmc,
      spread: spread,
    );
