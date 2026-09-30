import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/localization/api_errors.g.dart';
import 'package:vyzi/core/localization/system_messages.dart';

/// Every message the backend can throw has customer copy in both languages —
/// the app reuses the dashboard's catalogue (tool/generate_api_errors.mjs) —
/// so the generic "something went wrong" is left for messages nobody wrote.
void main() {
  const generic = 'Si è verificato un errore. Riprova tra poco.';

  test('a backend message gets its own copy, Italian first', () {
    const raw = 'This Partita IVA is already registered to another account';
    expect(
      SystemMessages.resolve(raw, language: 'it'),
      'Questa Partita IVA è già registrata su un altro account',
    );
    expect(
      SystemMessages.resolve(raw, language: 'en'),
      'This Partita IVA is already registered to another account',
    );
    expect(
      SystemMessages.resolve('A switch request already exists for this bill',
          language: 'it'),
      'Esiste già una richiesta di cambio fornitore per questa bolletta',
    );
  });

  test('values inside a message are translated too', () {
    expect(
      SystemMessages.resolve('Direct debit requires IBAN and holder\'s tax ID',
          language: 'it'),
      'L\'addebito diretto richiede l\'IBAN e il codice fiscale dell\'intestatario',
    );
    expect(
      SystemMessages.resolve('Bill is already in status "Offer Accepted"',
          language: 'it'),
      'La bolletta è già nello stato «Offerta accettata»',
    );
  });

  test('field messages name the field the way the form does', () {
    expect(
      SystemMessages.resolve('supply.podNumber should not be empty',
          language: 'it'),
      'Il campo «Codice POD» è obbligatorio',
    );
    expect(
      SystemMessages.resolve('phone should not be empty', language: 'en'),
      'The "Phone number" field is required',
    );
    // A property the customer has never seen is not named at all.
    expect(
      SystemMessages.resolve('internalFlag should not be empty',
          language: 'it'),
      'Controlla i dati inseriti e riprova.',
    );
    expect(
      SystemMessages.resolve(
          'paymentMethod must be one of the following values: rid, bollettino',
          language: 'it'),
      isNot(contains('rid')),
    );
  });

  test('an unrecognised message falls back on its status, not on "error"', () {
    ServerException error(int status) =>
        ServerException('some internal diagnostic', status);

    expect(error(404).message, isNot(generic));
    expect(error(404).message, 'I dati richiesti non sono disponibili.');
    expect(error(429).message, 'Troppe richieste. Attendi un momento e riprova.');
    expect(error(500).message, contains('server'));
    expect(error(500).message, isNot(contains('diagnostic')));
  });

  test('messages written by libraries are covered too', () {
    for (final raw in [
      'File too large',
      'Too many files',
      'Validation failed (uuid is expected)',
      'Cannot transition from pending to rewarded',
      'Cannot delete this offer: it has 2 active case(s) in progress. Cancel or complete them first.',
      'A fixed gas offer requires a per-unit price: pricePerSmc is missing.',
    ]) {
      final copy = SystemMessages.resolve(raw, language: 'it');
      expect(copy, isNot(generic), reason: raw);
      expect(copy, isNot(raw), reason: raw);
    }
    expect(
      SystemMessages.resolve('File too large', language: 'it'),
      'Il file è troppo grande. La dimensione massima è 10 MB.',
    );
    expect(ServerException('Payload Too Large', 413).message,
        contains('troppo grande'));
  });

  test('error codes win over the wording', () {
    expect(
      SystemMessages.resolve('whatever',
          errorCode: 'BILL_NOT_FOUND', language: 'it'),
      isNot(generic),
    );
  });

  test('every generated rule has copy in both languages', () {
    for (final rule in apiErrorRules) {
      expect(apiErrorsIt[rule.key], isNotNull, reason: rule.key);
      expect(apiErrorsEn[rule.key], isNotNull, reason: rule.key);
    }
    for (final key in apiErrorCodes.values) {
      expect(apiErrorsIt[key], isNotNull, reason: key);
    }
  });
}
