import 'package:get/get.dart';

/// `1 giorno` / `12 giorni` — `1 day` / `12 days` in English.
String formatDays(int days) =>
    days == 1 ? 'duration.day_one'.tr : 'duration.days'.trParams({'count': '$days'});

/// `1 mese` / `12 mesi` — `1 month` / `12 months` in English.
String formatMonths(int months) => months == 1
    ? 'duration.month_one'.tr
    : 'duration.months'.trParams({'count': '$months'});
