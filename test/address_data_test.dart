import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/core/models/address_data.dart';

void main() {
  group('AddressData.parse', () {
    test('splits the common all-caps bill format', () {
      final a = AddressData.parse('VIA ROMA 10, 20100 MILANO (MI)');
      expect(a.street, 'Via Roma');
      expect(a.streetNumber, '10');
      expect(a.city, 'Milano');
      expect(a.postalCode, '20100');
      expect(a.province, 'MI');
    });

    test('handles a comma before the civic number and a dash separator', () {
      final a = AddressData.parse('Via Giuseppe Garibaldi, 25 - 00185 Roma RM');
      expect(a.street, 'Via Giuseppe Garibaldi');
      expect(a.streetNumber, '25');
      expect(a.city, 'Roma');
      expect(a.postalCode, '00185');
      expect(a.province, 'RM');
    });

    test('handles no punctuation at all', () {
      final a = AddressData.parse('Corso Vittorio Emanuele II 15 20122 Milano MI');
      expect(a.street, 'Corso Vittorio Emanuele II');
      expect(a.streetNumber, '15');
      expect(a.postalCode, '20122');
      expect(a.city, 'Milano');
      expect(a.province, 'MI');
    });

    test('keeps a suffixed civic number', () {
      final a = AddressData.parse('Via Dante 3/A, 10121 Torino (TO)');
      expect(a.street, 'Via Dante');
      expect(a.streetNumber, '3/A');
      expect(a.postalCode, '10121');
      expect(a.province, 'TO');
    });

    test('does not read a civic number as the city when no CAP is present', () {
      final a = AddressData.parse('Via Roma, 10');
      expect(a.street, 'Via Roma');
      expect(a.streetNumber, '10');
      expect(a.city, isEmpty);
    });

    test('takes the city after the last comma when there is no CAP', () {
      final a = AddressData.parse('Via Roma 10, Milano');
      expect(a.street, 'Via Roma');
      expect(a.streetNumber, '10');
      expect(a.city, 'Milano');
    });

    test('ignores a trailing two-letter token that is not a province', () {
      // XX is not a sigla, so it is left in the city for the user to correct
      // rather than being stored as a province.
      final a = AddressData.parse('Via Roma 10, 20100 Milano XX');
      expect(a.province, isEmpty);
      expect(a.city, 'Milano XX');
    });

    test('leaves mixed-case input untouched', () {
      final a = AddressData.parse('Via Roma 10, 20100 Reggio Emilia (RE)');
      expect(a.street, 'Via Roma');
      expect(a.city, 'Reggio Emilia');
      expect(a.province, 'RE');
    });

    test('returns empty for null and blank input', () {
      expect(AddressData.parse(null), AddressData.empty);
      expect(AddressData.parse('   '), AddressData.empty);
    });
  });

  group('AddressData formatting', () {
    test('formats a full address', () {
      const a = AddressData(
        street: 'Via Roma',
        streetNumber: '10',
        city: 'Milano',
        postalCode: '20100',
        province: 'MI',
      );
      expect(a.streetLine, 'Via Roma 10');
      expect(a.cityLine, '20100 Milano (MI)');
      expect(a.formatted, 'Via Roma 10, 20100 Milano (MI)');
    });

    test('omits missing parts without leaving stray separators', () {
      const a = AddressData(street: 'Via Roma', city: 'Milano');
      expect(a.formatted, 'Via Roma, Milano');
    });
  });

  group('AddressData.toJson', () {
    test('prefixes every key and keeps the province as typed', () {
      const a = AddressData(
        street: ' Via Roma ',
        streetNumber: '10',
        city: 'Milano',
        postalCode: '20100',
        province: ' Milano ',
      );
      expect(a.toJson('supply'), {
        'supplyStreet': 'Via Roma',
        'supplyStreetNumber': '10',
        'supplyCity': 'Milano',
        'supplyPostalCode': '20100',
        'supplyProvince': 'Milano',
      });
    });

    test('round-trips through fromJson', () {
      const a = AddressData(
        street: 'Via Roma',
        streetNumber: '10',
        city: 'Milano',
        postalCode: '20100',
        province: 'MI',
      );
      expect(AddressData.fromJson(a.toJson('shipping'), 'shipping'), a);
    });
  });
}
