import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/utils/number_format.dart';

/// Every price and figure the app shows used to be formatted at the call site,
/// and the numbers drifted apart: a unit price carried four decimals in one
/// model and six on the admin side, a referral balance printed `€23` on the
/// invite screen and `€23,00` a tap away, and a monthly estimate reached the
/// screen straight from JSON at whatever width the API sent.
///
/// These tests pin the two things that fixed it — a fixed number of decimals
/// per kind of value, and a separator that follows the language the customer
/// picked rather than a hardcoded one.
void main() {
  tearDown(Get.reset);

  group('formatMoney', () {
    test('always shows two decimals, never fewer', () {
      expect(formatMoney(23), '€23,00');
      expect(formatMoney(10.5), '€10,50');
    });

    test('rounds a longer figure down to the money scale', () {
      expect(formatMoney(128.4059), '€128,41');
    });

    test('reads a decimal column that arrives as a string', () {
      expect(formatMoney('45.9'), '€45,90');
    });

    test('shows a dash rather than a zero for a missing amount', () {
      expect(formatMoney(null), kMissingValue);
      expect(formatMoney(''), kMissingValue);
    });
  });

  group('formatUnitPrice', () {
    test('holds an energy price at three decimals', () {
      expect(formatUnitPrice(0.1285, unit: 'kWh'), '€0,129/kWh');
    });

    test('keeps the trailing zeros that used to be trimmed away', () {
      expect(formatUnitPrice(0.01, unit: 'kWh'), '€0,010/kWh');
    });

    test('leaves the unit off when the layout already carries it', () {
      expect(formatUnitPrice(0.1285), '€0,129');
    });

    test('renders the bare figure for split-styled layouts', () {
      expect(formatUnitPriceValue('0.128500'), '0,129');
      expect(formatUnitPriceValue(null), kMissingValue);
    });
  });

  group('formatQuantity', () {
    test('groups thousands the way a bill quotes a reading', () {
      expect(formatQuantity(2800, unit: 'kWh'), '2.800,00 kWh');
    });

    test('holds a consumption figure at two decimals', () {
      expect(formatQuantity(1234.5, unit: 'Smc'), '1.234,50 Smc');
    });
  });

  group('formatPercent', () {
    test('holds a rate at two decimals', () {
      expect(formatPercent(39.5348), '39,53%');
    });
  });

  group('locale', () {
    test('follows the language the customer picked', () {
      Get.locale = const Locale('en', 'US');

      expect(formatMoney(1234.5), '€1234.50');
      expect(formatUnitPrice(0.1285, unit: 'kWh'), '€0.129/kWh');
      expect(formatQuantity(2800, unit: 'kWh'), '2,800.00 kWh');
    });

    test('falls back to Italian when no locale is set', () {
      Get.locale = null;

      expect(formatMoney(1234.5), '€1234,50');
    });
  });
}
