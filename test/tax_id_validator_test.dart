import 'package:flutter_test/flutter_test.dart';
import 'package:vyzi/core/utils/tax_id_validator.dart';

/// These are the same cases the API is held to in
/// `moreno-server/src/common/validators/is-italian-tax-id.validator.spec.ts`.
/// They are duplicated deliberately: the two implementations only stay in step
/// if both are pinned to one table, and a divergence shows up here as a failing
/// test rather than as a customer stuck on the request form with a code the app
/// accepted and the server refused.
void main() {
  group('isValidCodiceFiscale', () {
    for (final value in ['RSSMRA85T10A562S', 'MRTMTT25D09F205Z']) {
      test('accepts $value', () {
        expect(isValidCodiceFiscale(value), isTrue);
      });
    }

    test('accepts one written in lower case and padded with spaces', () {
      expect(isValidCodiceFiscale('  mrtmtt25d09f205z  '), isTrue);
    });

    test('accepts a woman’s code, whose day of birth carries the forty', () {
      // 41–71 is the range that marks a female holder; 09 above is a male one.
      expect(isValidCodiceFiscale('RSSMRA85T50A562W'), isTrue);
    });

    // The Agenzia delle Entrate replaces numerals with letters — 0→L, 1→M, 2→N,
    // 3→P, 4→Q, 5→R, 6→S, 7→T, 8→U, 9→V — from the right whenever two people
    // would otherwise be issued the same code. These are on real identity
    // cards, and each substitution changes the check character too.
    group('omocodia', () {
      for (final value in [
        'MRTMTT25D09F20RU', // one substitution
        'MRTMTT25D09F2LRF', // two
        'MRTMTT25D09FNLRU', // three
      ]) {
        test('accepts $value', () {
          expect(isValidCodiceFiscale(value), isTrue);
        });
      }

      test('still refuses one whose check character is wrong', () {
        expect(isValidCodiceFiscale('MRTMTT25D09F20RA'), isFalse);
      });
    });

    test('refuses a well-shaped code whose check character is wrong', () {
      // Everything but the last character is a real Codice Fiscale, which is
      // exactly what a typo produces — the shape alone would wave it through.
      expect(isValidCodiceFiscale('MRTMTT25D09F205A'), isFalse);
    });

    test('refuses a month letter that was never issued', () {
      // I, N and O are not month letters; only ABCDEHLMPRST are.
      expect(isValidCodiceFiscale('MRTMTT25N09F205M'), isFalse);
    });

    test('refuses a day of birth that cannot exist', () {
      // 00, 32–40 and 72–99 fall outside both the male and the female range.
      expect(isValidCodiceFiscale('MRTMTT25D00F205F'), isFalse);
      expect(isValidCodiceFiscale('MRTMTT25D35F205U'), isFalse);
      expect(isValidCodiceFiscale('MRTMTT25D99F205I'), isFalse);
    });

    test('refuses sixteen characters of the wrong shape', () {
      expect(isValidCodiceFiscale('1234567890123456'), isFalse);
    });
  });

  group('isValidPartitaIva', () {
    test('accepts eleven digits with a valid check digit', () {
      expect(isValidPartitaIva('00743110157'), isTrue);
    });

    test('accepts the same number written with its IT country prefix', () {
      expect(isValidPartitaIva('IT00743110157'), isTrue);
    });

    test('refuses eleven digits whose check digit is wrong', () {
      expect(isValidPartitaIva('12345678901'), isFalse);
    });

    test('refuses ten and twelve digits', () {
      expect(isValidPartitaIva('0074311015'), isFalse);
      expect(isValidPartitaIva('007431101577'), isFalse);
    });
  });

  group('isValidItalianTaxId', () {
    test('takes either form, since the holder may be a person or a company', () {
      expect(isValidItalianTaxId('RSSMRA85T10A562S'), isTrue);
      expect(isValidItalianTaxId('IT00743110157'), isTrue);
    });

    test('refuses an empty string', () {
      expect(isValidItalianTaxId(''), isFalse);
    });

    test('refuses the placeholder values a test account tends to carry', () {
      expect(isValidItalianTaxId('MRRMRA42E48B888Z'), isFalse);
      expect(isValidItalianTaxId('IT45324567894'), isFalse);
    });
  });

  group('codiceFiscaleCheckCharacter', () {
    test('names the character a nearly-correct code should have ended in', () {
      // MRRMRA42E48B888Z is the code a customer reported as valid. It is not:
      // the first fifteen characters imply X, so the form can say so instead of
      // sending them back to retype all sixteen.
      expect(codiceFiscaleCheckCharacter('MRRMRA42E48B888Z'), 'X');
    });

    test('agrees with a code that is already right', () {
      expect(codiceFiscaleCheckCharacter('RSSMRA85T10A562S'), 'S');
    });

    test('says nothing about a value that is not shaped like one', () {
      expect(codiceFiscaleCheckCharacter('00743110157'), isNull);
    });
  });

  group('codiceFiscaleProblem', () {
    test('has nothing to say about an untouched field', () {
      expect(codiceFiscaleProblem(''), isNull);
      expect(codiceFiscaleProblem('   '), isNull);
    });

    test('accepts a valid Codice Fiscale', () {
      expect(codiceFiscaleProblem('RSSMRA85T10A562S'), isNull);
      expect(codiceFiscaleProblem('  mrtmtt25d09f205z  '), isNull);
    });

    test('refuses a Partita IVA as the wrong identifier, valid or not', () {
      expect(codiceFiscaleProblem('IT00743110157'), CodiceFiscaleProblem.vatNumber);
      expect(codiceFiscaleProblem('00743110157'), CodiceFiscaleProblem.vatNumber);
      expect(codiceFiscaleProblem('12345678901'), CodiceFiscaleProblem.vatNumber);
    });

    test('separates a mistyped check character from a malformed code', () {
      expect(codiceFiscaleProblem('MRRMRA42E48B888Z'),
          CodiceFiscaleProblem.checkCharacter);
      expect(codiceFiscaleProblem('NOT-A-TAX-ID'), CodiceFiscaleProblem.shape);
      expect(codiceFiscaleProblem('RSSMRA85T10A562'), CodiceFiscaleProblem.shape);
    });
  });

  group('taxIdProblem', () {
    test('has nothing to say about an untouched field', () {
      expect(taxIdProblem(''), isNull);
      expect(taxIdProblem('   '), isNull);
    });

    test('has nothing to say about a valid code of either form', () {
      expect(taxIdProblem('RSSMRA85T10A562S'), isNull);
      expect(taxIdProblem('IT00743110157'), isNull);
    });

    test('separates a mistyped check character from a malformed code', () {
      expect(taxIdProblem('MRRMRA42E48B888Z'), TaxIdProblem.checkCharacter);
      expect(taxIdProblem('12345678901'), TaxIdProblem.checkDigit);
      expect(taxIdProblem('NOT-A-TAX-ID'), TaxIdProblem.shape);
      expect(taxIdProblem('RSSMRA85T10A562'), TaxIdProblem.shape);
    });
  });

  /// The mirror of `codiceFiscaleProblem`, for the fields a business account
  /// sees. One account carries one tax identifier, so a company's form asks for
  /// its Partita IVA and names the personal code as the other account kind's
  /// rather than calling it invalid.
  group('partitaIvaProblem', () {
    test('has nothing to say about an untouched field', () {
      expect(partitaIvaProblem(''), isNull);
      expect(partitaIvaProblem('   '), isNull);
    });

    test('has nothing to say about a VAT number, prefixed or bare', () {
      expect(partitaIvaProblem('00743110157'), isNull);
      expect(partitaIvaProblem('IT 0074 3110 157'), isNull);
    });

    test('names a Codice Fiscale as the wrong one of the two', () {
      expect(partitaIvaProblem('RSSMRA85T10A562S'),
          PartitaIvaProblem.codiceFiscale);
      // A mistyped personal code is still the customer reaching for the
      // personal code — telling them to fix its check character would send
      // them further the wrong way.
      expect(partitaIvaProblem('MRRMRA42E48B888Z'),
          PartitaIvaProblem.codiceFiscale);
    });

    test('separates a mistyped check digit from a malformed number', () {
      expect(partitaIvaProblem('12345678901'), PartitaIvaProblem.checkDigit);
      expect(partitaIvaProblem('1234567890'), PartitaIvaProblem.shape);
      expect(partitaIvaProblem('NOT-A-VAT'), PartitaIvaProblem.shape);
    });
  });

  group('normalizeTaxId', () {
    test('strips the spaces a tax ID is printed with and upper-cases it', () {
      expect(normalizeTaxId(' it 0074 3110 157 '), 'IT00743110157');
    });

    test('strips the punctuation a pasted code arrives with', () {
      expect(normalizeTaxId('IT-00743.110.157'), 'IT00743110157');
    });

    test('leaves an already-canonical value alone', () {
      expect(normalizeTaxId('RSSMRA85T10A562S'), 'RSSMRA85T10A562S');
    });
  });
}
