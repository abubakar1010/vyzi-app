import 'package:get/get.dart';
/// Combines a dial code and national number into E.164 format.
/// Example: toE164('+39', '333 123 4567') → '+393331234567'
String toE164(String dialCode, String nationalNumber) {
  final digits = nationalNumber.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.isEmpty) return '';
  return '$dialCode$digits';
}

/// Splits an E.164 string into (dialCode, nationalNumber).
/// Falls back to ('+39', value) if parsing fails.
(String dialCode, String nationalNumber) fromE164(String e164) {
  if (e164.isEmpty) return ('+39', '');

  // Common dial code lengths to try (longest first)
  final knownCodes = [
    '+39',
    '+44',
    '+49',
    '+33',
    '+34',
    '+1',
    '+61',
    '+91',
    '+86',
    '+81',
    '+82',
    '+7',
    '+971',
    '+966',
    '+965',
    '+974',
    '+973',
    '+972',
    '+970',
    '+968',
    '+964',
    '+962',
    '+961',
    '+380',
    '+375',
    '+374',
    '+373',
    '+372',
    '+371',
    '+370',
    '+358',
    '+357',
    '+356',
    '+355',
    '+354',
    '+353',
    '+352',
    '+351',
    '+421',
    '+420',
    '+423',
    '+386',
    '+385',
    '+382',
    '+381',
    '+389',
    '+387',
    '+377',
    '+376',
    '+994',
    '+995',
    '+998',
    '+993',
    '+992',
    '+880',
    '+234',
    '+254',
    '+233',
    '+221',
    '+251',
    '+218',
    '+216',
    '+213',
    '+212',
    '+20',
    '+27',
    '+507',
    '+506',
    '+505',
    '+504',
    '+503',
    '+502',
    '+501',
    '+598',
    '+595',
    '+593',
    '+592',
    '+591',
    '+590',
    '+58',
    '+57',
    '+56',
    '+55',
    '+54',
    '+53',
    '+52',
    '+51',
    '+48',
    '+47',
    '+46',
    '+45',
    '+43',
    '+41',
    '+40',
    '+36',
    '+32',
    '+31',
    '+30',
    '+90',
    '+98',
    '+92',
    '+65',
    '+64',
    '+63',
    '+62',
    '+60',
  ];

  for (final code in knownCodes) {
    if (e164.startsWith(code)) {
      return (code, e164.substring(code.length));
    }
  }

  // Fallback: assume +39 (Italy) if no match
  if (e164.startsWith('+')) {
    // Try 1-3 digit code
    for (int len = 4; len >= 2; len--) {
      if (e164.length > len) {
        return (e164.substring(0, len), e164.substring(len));
      }
    }
  }

  return ('+39', e164);
}

/// Maximum national phone number digits by ISO country code.
/// Common countries have exact maximums; others default to 15 (E.164 max).
const Map<String, int> _countryMaxDigits = {
  'IT': 10, 'US': 10, 'CA': 10, 'GB': 11, 'DE': 12, 'FR': 9,
  'ES': 9, 'PT': 9, 'NL': 9, 'BE': 9, 'AT': 13, 'CH': 12,
  'SE': 13, 'NO': 8, 'DK': 8, 'FI': 12, 'PL': 9, 'CZ': 9,
  'SK': 9, 'HU': 9, 'RO': 10, 'BG': 9, 'HR': 9, 'GR': 10,
  'TR': 10, 'RU': 10, 'UA': 9, 'IN': 10, 'CN': 11, 'JP': 11,
  'KR': 11, 'AU': 9, 'NZ': 10, 'BR': 11, 'MX': 10, 'AR': 10,
  'ZA': 9, 'NG': 10, 'AE': 9, 'SA': 9, 'EG': 10, 'SG': 8,
  'MY': 10, 'PH': 10, 'ID': 12, 'TH': 9, 'IE': 9, 'LU': 9,
  'IS': 7, 'MT': 8, 'CY': 8, 'LV': 8, 'LT': 8, 'EE': 8,
  'SI': 8, 'BA': 8, 'ME': 8, 'MK': 8, 'AL': 9, 'RS': 10,
  'XK': 8, 'MD': 8, 'BY': 10, 'GE': 9, 'AM': 8, 'AZ': 9,
  'KZ': 10, 'UZ': 9, 'PK': 10, 'BD': 10, 'LK': 9, 'MM': 9,
  'KH': 9, 'VN': 10, 'LA': 10, 'NP': 10, 'BT': 8, 'MV': 7,
  'QA': 8, 'BH': 8, 'KW': 8, 'OM': 8, 'JO': 9, 'LB': 8,
  'IQ': 10, 'IR': 10, 'AF': 9, 'YE': 9, 'SY': 9, 'PS': 9,
  'IL': 9, 'MA': 9, 'DZ': 9, 'TN': 8, 'LY': 9, 'SD': 9,
  'KE': 9, 'GH': 9, 'SN': 9, 'ET': 9, 'TZ': 9, 'UG': 9,
  'CM': 9, 'CI': 10, 'CD': 9, 'AO': 9, 'MZ': 9,
  'CL': 9, 'CO': 10, 'PE': 9, 'VE': 10, 'EC': 9, 'BO': 8,
  'PY': 9, 'UY': 8, 'PA': 8, 'CR': 8, 'GT': 8, 'HN': 8,
  'SV': 8, 'NI': 8, 'DO': 10, 'CU': 8, 'JM': 7, 'TT': 7,
  'PR': 10, 'HK': 8, 'MO': 8, 'TW': 10,
};

/// Returns the maximum allowed national number digits for [countryCode].
int maxPhoneDigits(String countryCode) =>
    _countryMaxDigits[countryCode.toUpperCase()] ?? 15;

/// Form validator for phone numbers (optional — allows empty).
/// Returns an error message if the value is invalid when provided.
String? validatePhone(String? value) {
  if (value == null || value.isEmpty) return null;
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length < 6) {
    return 'validation.phone_invalid'.tr;
  }
  return null;
}

/// Form validator for phone numbers (required — rejects empty values).
/// Use on screens where phone number is mandatory.
String? validatePhoneRequired(String? value) {
  if (value == null || value.isEmpty) {
    return 'request.form.phone_required'.tr;
  }
  final digits = value.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length < 6) {
    return 'validation.phone_invalid'.tr;
  }
  return null;
}
