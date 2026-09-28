/// Italian tax identifiers — Codice Fiscale for a person, Partita IVA for a
/// company — as the request form and the API both read them.
///
/// The same rule lives on the server in
/// `src/common/validators/is-italian-tax-id.validator.ts` and in the admin
/// dashboard in `src/utils/italianTaxId.ts`. The three have to reach the same
/// verdict: a code this file accepts and the API refuses strands the customer
/// on the request form with no way forward, and one this file waves through is
/// a direct debit mandate the supplier bounces weeks later — after the customer
/// has already been told the switch was submitted.
///
/// Both forms carry a check character derived from the rest of the code, and
/// both are checked here rather than only the shape, because a shape check
/// passes exactly the values a typo produces.
library;

/// The value as it is stored and sent: no spaces, upper case.
///
/// A tax ID is usually written out in groups, and the case must not end up
/// holding "IT 0074 3110 157" and "IT00743110157" as two different accounts.
/// Dots and hyphens go too, because that is how a code pasted out of a PDF or
/// an email signature tends to arrive.
String normalizeTaxId(String value) =>
    value.replaceAll(RegExp(r'[\s.-]'), '').toUpperCase();

/// Eleven digits, optionally carrying the `IT` country prefix.
final RegExp _partitaIvaPattern = RegExp(r'^(IT)?\d{11}$');

/// Six name letters, two year characters, the month letter, two day
/// characters, the Belfiore letter, three Belfiore characters and the check
/// character.
///
/// The seven positions that hold a number accept a letter as well, because the
/// Agenzia delle Entrate substitutes one there whenever two people would
/// otherwise be issued the same code — see [_omocodiaDigits]. Those codes are
/// on real identity cards, so a pattern that insists on `\d` turns a valid
/// Codice Fiscale into a form error the customer has no way to clear.
///
/// The month is one of the twelve letters actually in use rather than any
/// letter, so a transposed month is caught here instead of being left to the
/// check character alone.
final RegExp _codiceFiscalePattern = RegExp(
  r'^[A-Z]{6}'
  r'[\dLMNPQRSTUV]{2}'
  r'[ABCDEHLMPRST]'
  r'[\dLMNPQRSTUV]{2}'
  r'[A-Z]'
  r'[\dLMNPQRSTUV]{3}'
  r'[A-Z]$',
);

/// The digit each substitution letter stands for in an omocodia code.
const Map<String, int> _omocodiaDigits = <String, int>{
  'L': 0, 'M': 1, 'N': 2, 'P': 3, 'Q': 4,
  'R': 5, 'S': 6, 'T': 7, 'U': 8, 'V': 9,
};

/// The value each character contributes from an odd position (1st, 3rd, …).
const Map<String, int> _oddValues = <String, int>{
  '0': 1, '1': 0, '2': 5, '3': 7, '4': 9,
  '5': 13, '6': 15, '7': 17, '8': 19, '9': 21,
  'A': 1, 'B': 0, 'C': 5, 'D': 7, 'E': 9,
  'F': 13, 'G': 15, 'H': 17, 'I': 19, 'J': 21,
  'K': 2, 'L': 4, 'M': 18, 'N': 20, 'O': 11,
  'P': 3, 'Q': 6, 'R': 8, 'S': 12, 'T': 14,
  'U': 16, 'V': 10, 'W': 22, 'X': 25, 'Y': 24, 'Z': 23,
};

/// The value each character contributes from an even position (2nd, 4th, …).
const Map<String, int> _evenValues = <String, int>{
  '0': 0, '1': 1, '2': 2, '3': 3, '4': 4,
  '5': 5, '6': 6, '7': 7, '8': 8, '9': 9,
  'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4,
  'F': 5, 'G': 6, 'H': 7, 'I': 8, 'J': 9,
  'K': 10, 'L': 11, 'M': 12, 'N': 13, 'O': 14,
  'P': 15, 'Q': 16, 'R': 17, 'S': 18, 'T': 19,
  'U': 20, 'V': 21, 'W': 22, 'X': 23, 'Y': 24, 'Z': 25,
};

/// The number a numeric position holds, reading a substitution letter as the
/// digit it replaced.
int _digitAt(String cleaned, int index) {
  final character = cleaned[index];
  return _omocodiaDigits[character] ?? (character.codeUnitAt(0) - 0x30);
}

/// Whether the day of birth the code encodes could exist.
///
/// 1–31 for a man and 41–71 for a woman: the forty is what tells the two
/// apart. Nothing outside those two ranges was ever issued, so a code carrying
/// one is a typo whatever its check character says.
bool _hasPlausibleBirthDay(String cleaned) {
  final day = _digitAt(cleaned, 9) * 10 + _digitAt(cleaned, 10);
  return (day >= 1 && day <= 31) || (day >= 41 && day <= 71);
}

/// The check character the first fifteen imply, or null when the value is not
/// shaped like a Codice Fiscale at all.
///
/// Exposed so the form can tell the customer *which* character is wrong rather
/// than only that something is — the check character is the one part of a code
/// nobody can proofread by eye, and "invalid" alone leaves them retyping a
/// value that was fifteen-sixteenths correct.
String? codiceFiscaleCheckCharacter(String value) {
  final cleaned = normalizeTaxId(value);
  if (!_codiceFiscalePattern.hasMatch(cleaned)) return null;

  var sum = 0;
  for (var i = 0; i < 15; i++) {
    final character = cleaned[i];
    final contribution =
        i.isEven ? _oddValues[character] : _evenValues[character];
    if (contribution == null) return null;
    sum += contribution;
  }
  return String.fromCharCode(65 + (sum % 26));
}

/// A VAT number, verified against its Luhn-style check digit.
bool isValidPartitaIva(String value) {
  final cleaned = normalizeTaxId(value);
  if (!_partitaIvaPattern.hasMatch(cleaned)) return false;

  final digits = cleaned.startsWith('IT') ? cleaned.substring(2) : cleaned;
  var sum = 0;
  for (var i = 0; i < 11; i++) {
    final digit = digits.codeUnitAt(i) - 0x30;
    if (i.isEven) {
      sum += digit;
    } else {
      final doubled = digit * 2;
      sum += doubled > 9 ? doubled - 9 : doubled;
    }
  }
  return sum % 10 == 0;
}

/// A personal tax code, verified against its check character (the CIN).
bool isValidCodiceFiscale(String value) {
  final cleaned = normalizeTaxId(value);
  final expected = codiceFiscaleCheckCharacter(cleaned);
  if (expected == null) return false;
  if (!_hasPlausibleBirthDay(cleaned)) return false;
  return cleaned[15] == expected;
}

/// Either form. The field that collects it takes both, because the holder of an
/// account may be a person or a company and the form cannot know which.
bool isValidItalianTaxId(String value) =>
    isValidPartitaIva(value) || isValidCodiceFiscale(value);

/// Why a value was refused by a field that asks for a Codice Fiscale and only
/// a Codice Fiscale.
///
/// Separate from [TaxIdProblem] because that one passes a Partita IVA. A direct
/// debit mandate is filed against the person who signs it, so the request form
/// takes their tax code whatever the account type — a company's VAT number
/// identifies the company instead, and is refused there.
enum CodiceFiscaleProblem {
  /// Not a sixteen-character Codice Fiscale — the wrong length, or a character
  /// where none of that kind belongs.
  shape,

  /// Shaped like one, but the last character does not follow from the other
  /// fifteen. Almost always a single mistyped character.
  checkCharacter,

  /// A VAT number, in a field that does not take one. Its own case because
  /// "invalid" reads as the app failing to recognise a number the customer
  /// knows is correct, when the real answer is that it wanted the other code.
  vatNumber,
}

/// What is wrong with [value] read as a Codice Fiscale, or null when nothing
/// is. As with [taxIdProblem], an empty value is nobody's error.
CodiceFiscaleProblem? codiceFiscaleProblem(String value) {
  final cleaned = normalizeTaxId(value);
  if (cleaned.isEmpty) return null;
  if (isValidCodiceFiscale(cleaned)) return null;

  // Any eleven digits, not only a VAT number whose check digit adds up: a
  // mistyped one is still a VAT number the customer meant to give, and telling
  // them to fix its last digit would send them further the wrong way.
  if (_partitaIvaPattern.hasMatch(cleaned)) return CodiceFiscaleProblem.vatNumber;

  if (codiceFiscaleCheckCharacter(cleaned) != null &&
      _hasPlausibleBirthDay(cleaned)) {
    return CodiceFiscaleProblem.checkCharacter;
  }
  return CodiceFiscaleProblem.shape;
}

/// Why a tax ID was refused, for a form that has something better to say than
/// "invalid".
enum TaxIdProblem {
  /// Neither a sixteen-character Codice Fiscale nor an eleven-digit Partita
  /// IVA — the wrong length, or a character where none of that kind belongs.
  shape,

  /// Shaped like a Codice Fiscale, but the last character does not follow from
  /// the other fifteen. Almost always a single mistyped character.
  checkCharacter,

  /// Shaped like a Partita IVA, but the eleventh digit does not follow from the
  /// other ten.
  checkDigit,
}

/// What is wrong with [value], or null when nothing is.
///
/// An empty value is nobody's error here — the form decides on its own whether
/// the field was required, and saying "invalid" to someone who has not typed
/// yet is noise.
TaxIdProblem? taxIdProblem(String value) {
  final cleaned = normalizeTaxId(value);
  if (cleaned.isEmpty) return null;
  if (isValidItalianTaxId(cleaned)) return null;

  if (_partitaIvaPattern.hasMatch(cleaned)) return TaxIdProblem.checkDigit;
  if (codiceFiscaleCheckCharacter(cleaned) != null &&
      _hasPlausibleBirthDay(cleaned)) {
    return TaxIdProblem.checkCharacter;
  }
  return TaxIdProblem.shape;
}

/// Why a value was refused by a field that asks for a Partita IVA and only a
/// Partita IVA.
///
/// The mirror of [CodiceFiscaleProblem]. One account carries one tax
/// identifier: a private customer is identified by their Codice Fiscale and a
/// company by its VAT number, so a business screen asks for the VAT number and
/// nothing else — and a customer who reaches for the other code deserves to be
/// told which one is wanted rather than "invalid".
enum PartitaIvaProblem {
  /// Not eleven digits — the wrong length, or something that is not a digit.
  shape,

  /// Eleven digits, but the last does not follow from the other ten. Almost
  /// always a single mistyped digit.
  checkDigit,

  /// A Codice Fiscale, in a field that does not take one. Its own case for the
  /// same reason [CodiceFiscaleProblem.vatNumber] is: the value is a real code,
  /// it is simply the other account kind's.
  codiceFiscale,
}

/// What is wrong with [value] read as a Partita IVA, or null when nothing is.
/// As with the others, an empty value is nobody's error.
PartitaIvaProblem? partitaIvaProblem(String value) {
  final cleaned = normalizeTaxId(value);
  if (cleaned.isEmpty) return null;
  if (isValidPartitaIva(cleaned)) return null;

  // Shaped like a personal code, whatever its check character says: a mistyped
  // Codice Fiscale is still the customer reaching for the wrong one of the two.
  if (_codiceFiscalePattern.hasMatch(cleaned)) {
    return PartitaIvaProblem.codiceFiscale;
  }
  if (_partitaIvaPattern.hasMatch(cleaned)) return PartitaIvaProblem.checkDigit;
  return PartitaIvaProblem.shape;
}
