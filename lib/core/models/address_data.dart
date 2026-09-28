import 'package:get/get.dart';

import '../constants/italian_provinces.dart';

/// The five fields that make up an address anywhere in the app.
///
/// Supply, residential and shipping addresses all use this shape, so a case
/// always reaches the backend with its addresses in one predictable form
/// instead of three ad-hoc sets of text controllers.
class AddressData {
  /// Street name only — the civic number lives in [streetNumber].
  final String street;

  /// Civic number, e.g. `10`, `10/A`, `10 bis`.
  final String streetNumber;

  final String city;

  /// CAP — always five digits.
  final String postalCode;

  /// Province as the user typed it — free text, e.g. `MI` or `Milano`.
  final String province;

  const AddressData({
    this.street = '',
    this.streetNumber = '',
    this.city = '',
    this.postalCode = '',
    this.province = '',
  });

  static const AddressData empty = AddressData();

  static final RegExp _capPattern = RegExp(r'^\d{5}$');

  AddressData copyWith({
    String? street,
    String? streetNumber,
    String? city,
    String? postalCode,
    String? province,
  }) {
    return AddressData(
      street: street ?? this.street,
      streetNumber: streetNumber ?? this.streetNumber,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      province: province ?? this.province,
    );
  }

  bool get isEmpty =>
      street.trim().isEmpty &&
      streetNumber.trim().isEmpty &&
      city.trim().isEmpty &&
      postalCode.trim().isEmpty &&
      province.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// True when every field is present and well formed — the gate the screen
  /// uses before letting a request be submitted.
  bool get isComplete => !validate().hasErrors;

  /// `Via Roma 10`
  String get streetLine =>
      [street.trim(), streetNumber.trim()].where((p) => p.isNotEmpty).join(' ');

  /// `20100 Milano (MI)`
  String get cityLine {
    final base = [postalCode.trim(), city.trim()]
        .where((p) => p.isNotEmpty)
        .join(' ');
    final sigla = province.trim();
    if (sigla.isEmpty) return base;
    return base.isEmpty ? '($sigla)' : '$base ($sigla)';
  }

  /// `Via Roma 10, 20100 Milano (MI)`
  String get formatted =>
      [streetLine, cityLine].where((p) => p.isNotEmpty).join(', ');

  /// Province is free text: it only has to be filled in, never matched against
  /// the official sigle.
  AddressErrors validate() {
    final cap = postalCode.trim();
    return AddressErrors(
      street: street.trim().isEmpty ? 'request.form.street_required'.tr : null,
      streetNumber: streetNumber.trim().isEmpty
          ? 'request.form.street_number_required'.tr
          : null,
      city: city.trim().isEmpty ? 'request.form.city_required'.tr : null,
      postalCode: cap.isEmpty
          ? 'request.form.postal_code_required'.tr
          : (!_capPattern.hasMatch(cap)
              ? 'request.form.postal_code_invalid'.tr
              : null),
      province:
          province.trim().isEmpty ? 'request.form.province_required'.tr : null,
    );
  }

  /// Serialises under a prefix so the same object can be sent as
  /// `supply*`, `residential*` or `shipping*` without duplicating key lists.
  Map<String, dynamic> toJson(String prefix) => {
        '${prefix}Street': street.trim(),
        '${prefix}StreetNumber': streetNumber.trim(),
        '${prefix}City': city.trim(),
        '${prefix}PostalCode': postalCode.trim(),
        '${prefix}Province': province.trim(),
      };

  factory AddressData.fromJson(Map<String, dynamic> json, String prefix) {
    return AddressData(
      street: json['${prefix}Street'] as String? ?? '',
      streetNumber: json['${prefix}StreetNumber'] as String? ?? '',
      city: json['${prefix}City'] as String? ?? '',
      postalCode: json['${prefix}PostalCode'] as String? ?? '',
      province: json['${prefix}Province'] as String? ?? '',
    );
  }

  // ── OCR pre-fill ──────────────────────────────────────────────────────────

  /// Best-effort split of the single address line OCR reads off a bill
  /// (`VIA ROMA 10, 20100 MILANO (MI)`) into the five fields.
  ///
  /// This only pre-fills the form — the parsed result is always shown back in
  /// editable fields, so an imperfect split costs the user a correction rather
  /// than producing bad data.
  static AddressData parse(String? raw) {
    if (raw == null) return empty;
    var text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return empty;

    // Province — `(MI)` anywhere, otherwise a trailing two-letter token.
    var province = '';
    final paren = RegExp(r'\(\s*([A-Za-z]{2})\s*\)').firstMatch(text);
    if (paren != null && ItalianProvinces.isValid(paren.group(1))) {
      province = paren.group(1)!.toUpperCase();
      text = text.replaceRange(paren.start, paren.end, ' ');
    } else {
      final trailing = RegExp(r'[\s,\-]([A-Za-z]{2})\s*$').firstMatch(text);
      if (trailing != null && ItalianProvinces.isValid(trailing.group(1))) {
        province = trailing.group(1)!.toUpperCase();
        text = text.substring(0, trailing.start);
      }
    }

    // CAP — the first standalone five-digit group splits street from city.
    var postalCode = '';
    var streetPart = text;
    var cityPart = '';
    final cap = RegExp(r'(?<!\d)(\d{5})(?!\d)').firstMatch(text);
    if (cap != null) {
      postalCode = cap.group(1)!;
      streetPart = text.substring(0, cap.start);
      cityPart = text.substring(cap.end);
    } else {
      // No CAP: only trust a trailing comma-separated chunk as the city when
      // it holds no digits, so `Via Roma, 10` is not read as city "10".
      final comma = text.lastIndexOf(',');
      if (comma > 0) {
        final tail = text.substring(comma + 1);
        if (tail.trim().isNotEmpty && !tail.contains(RegExp(r'\d'))) {
          streetPart = text.substring(0, comma);
          cityPart = tail;
        }
      }
    }

    // Civic number — a trailing number token on the street part.
    var street = _trimSeparators(streetPart);
    var streetNumber = '';
    final number = RegExp(
      r'[,\s]+(\d+\s*[\/-]?\s*[A-Za-z]?(?:\s?(?:bis|ter))?)\s*$',
      caseSensitive: false,
    ).firstMatch(street);
    if (number != null) {
      streetNumber = number.group(1)!.replaceAll(RegExp(r'\s+'), '').trim();
      street = _trimSeparators(street.substring(0, number.start));
    }

    final city = _trimSeparators(cityPart.replaceAll(RegExp(r'[()]'), ' '));

    return AddressData(
      street: _normalizeCase(street),
      streetNumber: streetNumber.toUpperCase(),
      city: _normalizeCase(city),
      postalCode: postalCode,
      province: province,
    );
  }

  static String _trimSeparators(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,\-–]+'), '')
      .replaceAll(RegExp(r'[\s,\-–]+$'), '')
      .trim();

  /// Bills are usually printed in caps; title-case them back so the pre-filled
  /// form does not shout. Mixed-case input is left exactly as the user sees it.
  static String _normalizeCase(String value) {
    if (value.isEmpty) return value;
    if (value != value.toUpperCase()) return value;
    return value
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  String toString() => formatted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressData &&
          other.street == street &&
          other.streetNumber == streetNumber &&
          other.city == city &&
          other.postalCode == postalCode &&
          other.province == province;

  @override
  int get hashCode =>
      Object.hash(street, streetNumber, city, postalCode, province);
}

/// Per-field validation messages for one address block. All null means valid.
class AddressErrors {
  final String? street;
  final String? streetNumber;
  final String? city;
  final String? postalCode;
  final String? province;

  const AddressErrors({
    this.street,
    this.streetNumber,
    this.city,
    this.postalCode,
    this.province,
  });

  static const AddressErrors none = AddressErrors();

  bool get hasErrors =>
      street != null ||
      streetNumber != null ||
      city != null ||
      postalCode != null ||
      province != null;
}
