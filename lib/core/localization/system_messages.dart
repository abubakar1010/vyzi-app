import 'package:get/get.dart';
import 'en_us.dart';
import 'it_it.dart';

/// Converts technical API messages into customer copy without exposing diagnostics.
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

  static String resolve(
    dynamic message, {
    String? errorCode,
    String? language,
  }) {
    final catalog = (language ?? Get.locale?.languageCode ?? 'it') == 'en'
        ? enUS
        : itIT;
    String translated(String key) =>
        catalog[key] ?? catalog['system.unexpected']!;
    final codeKey = _codes[errorCode];
    if (codeKey != null) return translated(codeKey);
    if (message is List) {
      return message
          .map((item) => resolve(item, language: language))
          .toSet()
          .join('\n');
    }
    final raw = message?.toString().trim() ?? '';
    final key = _legacy[raw];
    if (key != null) return translated(key);
    if (catalog.containsKey(raw)) return translated(raw);
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
    if (raw.contains('must be an email'))
      return translated('auth.forgot_password.email_error');
    if (RegExp(
      r'must |should not |is required|invalid input',
      caseSensitive: false,
    ).hasMatch(raw)) {
      return translated('system.validation');
    }
    return translated('system.unexpected');
  }
}
