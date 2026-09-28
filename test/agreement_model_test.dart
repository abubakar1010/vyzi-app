import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/features/profile/agreements/agreements_controller.dart';

/// The agreement detail screen used to invent three of the values it displayed:
/// it scraped the promo code out of the free-text description with a regex, cut
/// the description's first sentence down for the big discount figure, and
/// hardcoded the "how to use" steps. All three are now admin-authored columns,
/// and these tests pin both the new path and the fallback that keeps rows
/// created before those columns existed working.
Map<String, dynamic> _json(Map<String, dynamic> overrides) => {
  'id': 'a1',
  'title': 'Sconto Test',
  'partnerName': 'Partner Test',
  'description': 'Descrizione',
  'discountDescription': '20% di sconto sul menu. Codice: EASY20',
  'partnerLogoUrl': 'https://example.com/logo.png',
  'termsUrl': 'https://example.com/terms',
  'address': 'Viale Bligny 39, 20136 Milano MI, Italia',
  'validFrom': '2026-01-01',
  'validUntil': '2026-12-31',
  ...overrides,
};

void main() {
  group('AgreementModel.fromJson', () {
    test('prefers the admin-set code, headline and steps', () {
      final m = AgreementModel.fromJson(
        _json({
          'discountCode': 'EASYBIZCAR',
          'discountHeadline': '20%',
          'howToUse': ['Primo passo', 'Secondo passo'],
        }),
      );

      expect(m.discountCode, 'EASYBIZCAR');
      expect(m.discount, '20%');
      expect(m.howToUse, ['Primo passo', 'Secondo passo']);
    });

    test('keeps a code that the old regex could never have matched', () {
      // `CRACCO4BIZ` ends in letters, so the scan of the description misses it.
      final m = AgreementModel.fromJson(
        _json({
          'discountCode': 'CRACCO4BIZ',
          'discountDescription': 'Bottiglia inclusa. Codice: CRACCO4BIZ',
        }),
      );

      expect(m.discountCode, 'CRACCO4BIZ');
    });

    test('falls back to scanning the description when no code is set', () {
      final m = AgreementModel.fromJson(_json({'discountCode': null}));

      expect(m.discountCode, 'EASY20');
    });

    test('falls back to the first sentence when no headline is set', () {
      final m = AgreementModel.fromJson(_json({'discountHeadline': null}));

      expect(m.discount, '20% di sconto sul menu');
    });

    test('ignores blank and whitespace-only steps', () {
      final m = AgreementModel.fromJson(
        _json({
          'howToUse': ['  Primo passo  ', '', '   '],
        }),
      );

      expect(m.howToUse, ['Primo passo']);
    });

    test('falls back to generic steps when none are set', () {
      final m = AgreementModel.fromJson(_json({'howToUse': null}));

      // Translations are not loaded in a unit test, so `.tr` echoes the keys —
      // enough to prove the fallback list was built rather than left empty.
      expect(m.howToUse, isNotEmpty);
      expect(m.howToUse.first, contains('agreements.how_to_'));
    });

    test('derives the town from the partner address', () {
      expect(AgreementModel.fromJson(_json({})).city, 'Milano');

      expect(
        AgreementModel.fromJson(
          _json({
            'address': 'Via Liguria 1, 35030 Sarmeola di Rubano PD, Italia',
          }),
        ).city,
        'Sarmeola di Rubano',
      );

      expect(
        AgreementModel.fromJson(
          _json({'address': 'Piazza San Marco 57, 30124 Venezia VE, Italia'}),
        ).city,
        'Venezia',
      );
    });

    test(
      'leaves the town empty when the address is missing or unparseable',
      () {
        expect(AgreementModel.fromJson(_json({'address': ''})).city, '');
        expect(AgreementModel.fromJson(_json({'address': null})).city, '');
        expect(
          AgreementModel.fromJson(
            _json({'address': 'dietro la stazione'}),
          ).city,
          '',
        );
      },
    );

    test('formats the offer date with and without an end date', () {
      expect(
        AgreementModel.fromJson(_json({})).offerDate,
        '2026-01-01 – 2026-12-31',
      );
      expect(
        AgreementModel.fromJson(_json({'validUntil': null})).offerDate,
        'Dal 2026-01-01',
      );
    });
  });
}
