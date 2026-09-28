import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Dates with month names follow the app language: `20 ago 2026` in Italian,
/// `20 Aug 2026` in English. Italian unless the user picked English.
///
/// The symbol tables are loaded in `main.dart`; should they be missing (a
/// widget test that never ran `main`), the date falls back to a numeric
/// `20/08/2026` rather than throwing.
String get _dateLocale => Get.locale?.languageCode == 'en' ? 'en' : 'it';

String _format(String pattern, DateTime date) {
  try {
    return DateFormat(pattern, _dateLocale).format(date.toLocal());
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }
}

/// `20 ago 2026`
String formatShortDate(DateTime date) => _format('d MMM y', date);

/// `20 agosto 2026`
String formatLongDate(DateTime date) => _format('d MMMM y', date);

/// `agosto 2026`
String formatMonthYear(DateTime date) => _format('MMMM y', date);
