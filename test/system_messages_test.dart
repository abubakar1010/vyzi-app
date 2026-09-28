import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vyzi/core/exceptions/app_exceptions.dart';
import 'package:vyzi/core/localization/system_messages.dart';

void main() {
  tearDown(() => Get.reset());

  test('both password-reuse API variants have the requested Italian copy', () {
    for (final message in [
      'New password must be different from your current password',
      'New password must be different from current password',
    ]) {
      expect(
        SystemMessages.resolve(message, language: 'it'),
        'La nuova password deve essere diversa da quella attuale.',
      );
      expect(
        SystemMessages.resolve(message, language: 'en'),
        'Your new password must be different from your current password.',
      );
    }
  });

  test('codes take precedence and validation arrays remain localized', () {
    expect(
      SystemMessages.resolve(
        'internal diagnostic',
        errorCode: 'PASSWORD_REUSED',
        language: 'it',
      ),
      'La nuova password deve essere diversa da quella attuale.',
    );
    final result = SystemMessages.resolve([
      'email must be an email',
      'firstName should not be empty',
    ], language: 'it');
    expect(result, contains('email'));
    expect(result, contains('Controlla i dati inseriti'));
    expect(result, isNot(contains('must')));
    expect(result, isNot(contains('firstName')));
  });

  test('unknown diagnostics are hidden and metadata is preserved', () {
    Get.locale = const Locale('it');
    final data = <String, dynamic>{
      'message': ['database query failed'],
      'data': {'verificationToken': 'token'},
    };
    final error = ServerException(
      'database query failed',
      403,
      'diagnostic',
      data,
    );
    expect(error.message, 'Si è verificato un errore. Riprova tra poco.');
    expect(error.rawMessage, 'database query failed');
    expect(error.responseData, same(data));
    expect(error.statusCode, 403);
    expect(error.details, 'diagnostic');
  });

  test('exceptions follow the current locale and retain interpolated copy', () {
    Get.locale = const Locale('it');
    final error = NoInternetException();
    expect(error.message, 'Errore di rete. Controlla la connessione.');
    Get.locale = const Locale('en');
    expect(error.message, isNot(contains('Errore')));
    expect(
      SystemMessages.resolve(
        'Inoltra a vyzi.bollette@gmail.com',
        language: 'en',
      ),
      'Forward to vyzi.bollette@gmail.com',
    );
  });
}
