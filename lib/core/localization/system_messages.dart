import 'package:get/get.dart';
import 'api_errors.g.dart';
import 'en_us.dart';
import 'it_it.dart';

/// Converts technical API messages into customer copy without exposing diagnostics.
///
/// Lookup order: the API `errorCode`, the app's own wording for the messages
/// it cares most about ([_legacy]), then the backend catalogue shared with the
/// dashboard ([apiErrorRules]), then a message chosen by HTTP status. Only a
/// message none of those recognise gets the generic one.
/// The optional language makes the resolver independently testable.
class SystemMessages {
  static const _legacy = <String, String>{
    'New password must be different from your current password':
        'system.password_reused',
    'New password must be different from current password':
        'system.password_reused',
    'Current password is incorrect': 'system.current_password_incorrect',
    'New password and confirmation do not match':
        'auth.reset_password.mismatch',
    'Invalid email or password': 'auth.login.error.invalid_credentials',
    'Email already registered': 'system.email_registered',
    'Invalid or expired OTP code': 'system.code_expired',
    'Invalid or expired reset token': 'system.code_expired',
    'Your reset session has expired. Please request a new code.':
        'system.code_expired',
    'Invalid or expired verification token': 'system.code_expired',
    'Invalid verification token': 'system.code_expired',
    'Too many failed attempts. Please request a new code.':
        'system.code_attempts',
    'Your account has been suspended. Please contact support for assistance.':
        'auth.login.error.suspended',
    'Email not verified. Please verify your email first.':
        'auth.login.error.not_verified',
    'We could not send the email right now. Please try again in a moment.':
        'auth.forgot_password.send_failed_error',
    'No internet connection': 'upload_bill.error_network',
    'Request timeout': 'upload_bill.error_timeout',
    'Internal server error': 'upload_bill.error_server',
    'Server error': 'upload_bill.error_server',
    'Bad certificate': 'upload_bill.error_server',
    'Failed to parse data': 'system.unexpected',
    'Cache operation failed': 'system.unexpected',
    'Data not found': 'system.not_found',
    'User not found': 'system.not_found',
    'An unknown error occurred': 'system.unexpected',
    'Invalid referral code': 'system.referral_invalid',
    'Cannot use your own referral code': 'system.referral_self',
    'Unauthorized': 'auth.session_expired.message',
    'Forbidden': 'system.forbidden',
    'ThrottlerException: Too Many Requests': 'system.too_many_requests',
  };

  static const _codes = <String, String>{
    'PASSWORD_REUSED': 'system.password_reused',
    'INVALID_CREDENTIALS': 'auth.login.error.invalid_credentials',
    'EMAIL_NOT_VERIFIED': 'auth.login.error.not_verified',
    'VALIDATION_ERROR': 'system.validation',
  };

  /// Customer copy for an API message in the active language (Italian first).
  ///
  /// [statusCode] picks a message by HTTP status when the text itself is not
  /// recognised, so an unknown 404 still reads "not available" rather than a
  /// bare "something went wrong".
  static String resolve(
    dynamic message, {
    String? errorCode,
    int? statusCode,
    String? language,
  }) {
    final lang = (language ?? Get.locale?.languageCode ?? 'it') == 'en'
        ? 'en'
        : 'it';
    final catalog = lang == 'en' ? enUS : itIT;
    String translated(String key) =>
        catalog[key] ?? catalog['system.unexpected']!;

    final codeKey = _codes[errorCode];
    if (codeKey != null) return translated(codeKey);
    final apiCodeKey = apiErrorCodes[errorCode];
    if (apiCodeKey != null) return _apiCopy(apiCodeKey, lang, const {});

    if (message is List) {
      return message
          .map((item) =>
              resolve(item, statusCode: statusCode, language: language))
          .toSet()
          .join('\n');
    }
    final raw = message?.toString().trim() ?? '';
    final key = _legacy[raw];
    if (key != null) return translated(key);
    if (catalog.containsKey(raw)) return translated(raw);

    final fromApi = _fromApiCatalogue(raw, lang);
    if (fromApi != null) return fromApi;

    // Existing translated app exceptions remain readable in either locale.
    for (final source in [enUS, itIT]) {
      for (final entry in source.entries) {
        if (entry.value == raw) return translated(entry.key);
        if (entry.value.contains('@')) {
          final names = RegExp(
            r'@\w+',
          ).allMatches(entry.value).map((m) => m.group(0)!).toList();
          var pattern = RegExp.escape(entry.value);
          for (final name in names) {
            pattern = pattern.replaceFirst(name, '(.*?)');
          }
          final match = RegExp('^$pattern\$').firstMatch(raw);
          if (match != null) {
            var result = translated(entry.key);
            for (var i = 0; i < names.length; i++) {
              result = result.replaceAll(names[i], match.group(i + 1)!);
            }
            return result;
          }
        }
      }
    }

    if (statusCode != null && statusCode >= 500) {
      return _apiCopy('server', lang, const {});
    }
    if (statusCode == 413) return _apiCopy('file_too_large', lang, const {});
    final byStatus = _statusKey(statusCode);
    return translated(byStatus ?? 'system.unexpected');
  }

  /// The backend catalogue's copy for [raw], or null when no rule matches.
  static String? _fromApiCatalogue(String raw, String lang) {
    if (raw.isEmpty) return null;
    for (final rule in apiErrorRules) {
      if (rule.exact != null) {
        if (rule.exact == raw) return _apiCopy(rule.key, lang, const {});
        continue;
      }
      final match = rule.pattern!.firstMatch(raw);
      if (match == null) continue;

      final params = <String, String>{};
      for (final name in match.groupNames) {
        final value = match.namedGroup(name) ?? '';
        if (name == 'field') {
          // A field the customer cannot name is no help to them: the
          // form-level message says the same without the API's property name.
          final label = _fieldLabel(value, lang);
          if (label == null) return _validationCopy(lang);
          params[name] = label;
        } else {
          params[name] = _param(value, rule.params[name], lang);
        }
      }
      // Messages that list raw enum values or name a property the app should
      // never send are diagnostics, not something the customer can act on.
      if (rule.key == 'field_one_of') {
        return _apiCopy('field_invalid', lang, params);
      }
      if (rule.key == 'field_not_allowed') {
        return (lang == 'en' ? enUS : itIT)['system.unexpected']!;
      }
      return _apiCopy(rule.key, lang, params);
    }
    return null;
  }

  static String _apiCopy(String key, String lang, Map<String, String> params) {
    final copy = lang == 'en' ? apiErrorsEn : apiErrorsIt;
    var text = copy[key] ?? copy['generic']!;
    params.forEach((name, value) => text = text.replaceAll('@$name', value));
    return text;
  }

  static String _validationCopy(String lang) =>
      (lang == 'en' ? enUS : itIT)['system.validation']!;

  /// `supply.podNumber` is labelled by its last segment.
  static String? _fieldLabel(String field, String lang) =>
      (lang == 'en' ? enUS : itIT)['api_field.${field.split('.').last}'];

  static String _param(String value, String? kind, String lang) {
    final copy = lang == 'en' ? apiErrorsEn : apiErrorsIt;
    String translateValue(String v) => copy['values.${v.trim()}'] ?? v.trim();
    switch (kind) {
      case 'billStatus':
        final status = apiErrorBillStatus[value];
        final catalog = lang == 'en' ? enUS : itIT;
        return (status != null ? catalog['bills.status.$status'] : null) ??
            value;
      case 'list':
        final parts =
            value.split(RegExp(r'\s+and\s+|,\s*')).map(translateValue).toList();
        return parts.length > 1
            ? '${parts.sublist(0, parts.length - 1).join(', ')} ${copy['and']} ${parts.last}'
            : parts.first;
      case 'value':
        return translateValue(value);
      default:
        return value;
    }
  }

  /// The app's own copy for a status whose message was not recognised.
  static String? _statusKey(int? statusCode) {
    switch (statusCode) {
      case 400:
      case 409:
      case 422:
        return 'system.validation';
      case 401:
        return 'auth.session_expired.message';
      case 403:
        return 'system.forbidden';
      case 404:
        return 'system.not_found';
      case 429:
        return 'system.too_many_requests';
      default:
        return null;
    }
  }
}
