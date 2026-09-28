import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/features/home/model/user_service_model.dart';

/// The utility details hero used to ask every supply for a `pricePerKwh` and
/// print the app's missing-value dash when there wasn't one. On a variable or
/// indexed supply there never is: that contract is priced as a spread over the
/// market index, and the per-unit column is legitimately null. The customer was
/// shown a lone dash under the heading "PREZZO MATERIA" — at 32sp in the hero's
/// green it reads as a status dot, and either way it says their contract has no
/// price.
///
/// These pin down which figure a supply answers with, and that the dash is kept
/// for the one case it is honest about — an offer carrying no price at all.
UserServiceModel service(Map<String, dynamic> json) =>
    UserServiceModel.fromJson({'id': 'svc-1', ...json});

void main() {
  tearDown(Get.reset);

  group('fixed supply', () {
    test('answers with its per-unit price', () {
      final fixed = service({
        'energyType': 'electricity',
        'marketType': 'fixed',
        'pricePerKwh': '0.085000',
      });

      expect(fixed.isIndexedPrice, isFalse);
      expect(fixed.unitPriceValueDisplay, '0,085');
      expect(fixed.unitPriceUnitDisplay, '€/kWh');
    });

    test('reads the gas price and unit off a gas supply', () {
      final gas = service({
        'energyType': 'gas',
        'marketType': 'fixed',
        'pricePerSmc': '0.450000',
      });

      expect(gas.unitPriceValueDisplay, '0,450');
      expect(gas.unitPriceUnitDisplay, '€/Smc');
    });
  });

  group('indexed supply', () {
    test('answers with its spread rather than a missing per-unit price', () {
      final indexed = service({
        'energyType': 'electricity',
        'marketType': 'indexed',
        'pricePerKwh': null,
        'spread': '0.012000',
      });

      expect(indexed.isIndexedPrice, isTrue);
      expect(indexed.priceIndexLabel, 'PUN');
      expect(indexed.unitPriceValueDisplay, '0,012');
    });

    test('treats a variable supply the same way as an indexed one', () {
      final variable = service({
        'energyType': 'electricity',
        'marketType': 'variable',
        'spread': '0.009000',
      });

      expect(variable.isIndexedPrice, isTrue);
      expect(variable.unitPriceValueDisplay, '0,009');
    });

    test('names the gas index, which is not the electricity one', () {
      final gas = service({'energyType': 'gas', 'marketType': 'indexed'});

      expect(gas.priceIndexLabel, 'PSV');
    });

    test('shows a zero spread rather than calling it missing', () {
      final passthrough = service({
        'energyType': 'electricity',
        'marketType': 'indexed',
        'spread': '0',
      });

      expect(passthrough.unitPriceValueDisplay, '0,000');
    });

    test('ignores a per-unit price left on an indexed offer', () {
      // A stale `pricePerKwh` from before the offer was switched to indexed is
      // not what the customer pays, so quoting it would be worse than the dash.
      final indexed = service({
        'energyType': 'electricity',
        'marketType': 'indexed',
        'pricePerKwh': '0.085000',
        'spread': '0.012000',
      });

      expect(indexed.unitPriceValueDisplay, '0,012');
    });
  });

  group('no price on file', () {
    test('has nothing to show for a fixed offer without a price', () {
      final unpriced = service({
        'energyType': 'electricity',
        'marketType': 'fixed',
      });

      expect(unpriced.unitPriceValueDisplay, isNull);
    });

    test('has nothing to show for an indexed offer without a spread', () {
      final unpriced = service({
        'energyType': 'electricity',
        'marketType': 'indexed',
      });

      expect(unpriced.unitPriceValueDisplay, isNull);
    });

    test('falls back to the per-unit price when the API sends no market type', () {
      // Older payloads carry no `marketType`. Reading it as "not indexed" keeps
      // those supplies showing the price they always showed.
      final legacy = service({
        'energyType': 'electricity',
        'pricePerKwh': '0.085000',
      });

      expect(legacy.isIndexedPrice, isFalse);
      expect(legacy.unitPriceValueDisplay, '0,085');
    });
  });
}
