import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vyzi/core/localization/app_translations.dart';
import 'package:vyzi/core/localization/en_us.dart';
import 'package:vyzi/core/localization/it_it.dart';
import 'package:vyzi/core/utils/date_format.dart';
import 'package:vyzi/core/utils/duration_format.dart';

/// Italian is the product's language; English is a translation of it.
///
/// These are the mobile counterpart of the dashboard's `npm run i18n:check`:
/// a key used by the code but missing from the Italian catalogue shows the raw
/// key to the customer, and a key missing from one language falls back to the
/// other.
void main() {
  group('catalogues', () {
    test('every Italian key has an English translation and vice versa', () {
      final onlyItalian = itIT.keys.toSet().difference(enUS.keys.toSet());
      final onlyEnglish = enUS.keys.toSet().difference(itIT.keys.toSet());

      expect(onlyItalian, isEmpty, reason: 'missing in en_us.dart');
      expect(onlyEnglish, isEmpty, reason: 'missing in it_it.dart');
    });

    test('no translation is empty', () {
      for (final catalogue in [itIT, enUS]) {
        for (final entry in catalogue.entries) {
          expect(entry.value.trim(), isNotEmpty, reason: entry.key);
        }
      }
    });

    test('both languages take the same @parameters', () {
      Set<String> params(String value) =>
          RegExp(r'@\w+').allMatches(value).map((m) => m.group(0)!).toSet();

      for (final key in itIT.keys.where(enUS.containsKey)) {
        expect(params(enUS[key]!), params(itIT[key]!), reason: key);
      }
    });

    test('every key the code translates exists in Italian', () {
      final used = RegExp(r"'([a-z0-9_]+(?:\.[a-z0-9_]+)+)'\s*\.\s*tr(?:Params)?\b");
      final missing = <String>[];

      final sources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in sources) {
        for (final match in used.allMatches(file.readAsStringSync())) {
          final key = match.group(1)!;
          if (!itIT.containsKey(key)) missing.add('$key (${file.path})');
        }
      }

      expect(missing, isEmpty);
    });
  });

  group('formatting follows the app language', () {
    setUpAll(() async {
      await initializeDateFormatting('it');
      await initializeDateFormatting('en');
    });

    Future<void> inLanguage(WidgetTester tester, Locale locale) async {
      await tester.pumpWidget(GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        fallbackLocale: const Locale('it', 'IT'),
        home: const SizedBox.shrink(),
      ));
    }

    testWidgets('Italian', (tester) async {
      await inLanguage(tester, const Locale('it', 'IT'));

      expect(formatShortDate(DateTime(2026, 8, 20, 12)), '20 ago 2026');
      expect(formatMonthYear(DateTime(2026, 9, 1, 12)), 'settembre 2026');
      expect(formatDays(1), '1 giorno');
      expect(formatDays(12), '12 giorni');
      expect(formatMonths(1), '1 mese');
      expect(formatMonths(24), '24 mesi');
    });

    testWidgets('English only when chosen', (tester) async {
      await inLanguage(tester, const Locale('en', 'US'));

      expect(formatShortDate(DateTime(2026, 8, 20, 12)), '20 Aug 2026');
      expect(formatMonthYear(DateTime(2026, 9, 1, 12)), 'September 2026');
      expect(formatDays(12), '12 days');
      expect(formatMonths(24), '24 months');
    });
  });
}
