import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Decimal precision for every price and figure the app shows.
///
/// Precision belongs to the *kind* of value, not to the widget rendering it.
/// Before this file each model wrote its own `toStringAsFixed`, and the numbers
/// drifted: `costPerUnit` printed four decimals in the bill card and the offer
/// list, six on the admin side; a referral balance printed as `€23` on the
/// invite screen and `€23,00` two taps away; a monthly estimate was
/// interpolated straight from JSON, so whatever the API sent reached the screen
/// unrounded.
///
///   money      2 dp  — totals, fees, taxes, savings, referral rewards
///   unitPrice  3 dp  — €/kWh, €/Smc, spread
///   quantity   2 dp  — kWh / Smc consumption
///   percent    2 dp  — rates
///
/// Upload progress and file sizes are not covered here: they are UI chrome
/// rather than figures the customer is asked to compare, and `45%` / `1.5 MB`
/// read better whole.
const int kMoneyDecimals = 2;
const int kUnitPriceDecimals = 3;
const int kQuantityDecimals = 2;
const int kPercentDecimals = 2;

/// Shown wherever a figure is missing, matching the dash the bill and offer
/// models already returned for a null amount.
const String kMissingValue = '-';

/// The separator follows the language the customer picked, rather than a
/// hardcoded one: `€0,129` in Italian, `€0.129` in English. Getting this wrong
/// is not cosmetic — an Italian reader takes the dot in `€0.129` for a
/// thousands separator.
///
/// Falls back to Italian, matching `fallbackLocale` in `app.dart`. `intl` has
/// no `it_IT` symbol table and resolves it to `it`, which is why passing the
/// full tag is safe.
String get _locale => Get.locale?.toString() ?? 'it_IT';

/// Coerces an API value to a finite number, or null when there is nothing to
/// show.
///
/// The string branch is the common case, not the defensive one: Postgres
/// `decimal` columns cross the wire as strings, and several models keep them
/// that way (`monthlyEstimate`, `pricePerKwh`, `pricePerSmc` are all `String?`).
double? _toDouble(Object? value) {
  if (value == null) return null;

  if (value is num) {
    final asDouble = value.toDouble();
    return asDouble.isFinite ? asDouble : null;
  }

  final text = value.toString().trim();
  if (text.isEmpty) return null;

  // A comma is only a decimal point when nothing else in the string is: in
  // '1,234.56' it groups thousands, and swapping it would parse the number a
  // thousandfold wrong.
  final normalised = text.contains('.') ? text : text.replaceAll(',', '.');
  final parsed = double.tryParse(normalised);
  return (parsed != null && parsed.isFinite) ? parsed : null;
}

/// Renders at a fixed number of decimals with the locale's separators.
///
/// [grouped] is off for money and prices, which have never carried a thousands
/// separator here and would be restyled across every screen by adding one. It
/// is on for consumption, where a bill quotes `2.800 kWh` and the app already
/// grouped that figure.
String _decimals(double value, int decimals, {bool grouped = false}) {
  final pattern = '${grouped ? '#,##0' : '0'}.${'0' * decimals}';
  return NumberFormat(pattern, _locale).format(value);
}

/// A money amount with its symbol, e.g. `€128,40`.
String formatMoney(Object? value, {String fallback = kMissingValue}) {
  final amount = _toDouble(value);
  if (amount == null) return fallback;
  return '€${_decimals(amount, kMoneyDecimals)}';
}

/// An energy unit price, e.g. `€0,129/kWh`. Pass [unit] to append it.
String formatUnitPrice(
  Object? value, {
  String? unit,
  String fallback = kMissingValue,
}) {
  final price = _toDouble(value);
  if (price == null) return fallback;
  final formatted = '€${_decimals(price, kUnitPriceDecimals)}';
  return unit == null || unit.isEmpty ? formatted : '$formatted/$unit';
}

/// The bare figure at unit-price precision, e.g. `0,129`.
///
/// For the layouts that style the amount and its unit separately — the utility
/// detail hero prints the number at 32sp and ` €/kWh` beside it at a fraction
/// of that — so the symbol cannot be baked into the string.
String formatUnitPriceValue(Object? value, {String fallback = kMissingValue}) {
  final price = _toDouble(value);
  if (price == null) return fallback;
  return _decimals(price, kUnitPriceDecimals);
}

/// A consumption figure, e.g. `2.800,00 kWh`. Pass [unit] to append it.
String formatQuantity(
  Object? value, {
  String? unit,
  String fallback = kMissingValue,
}) {
  final quantity = _toDouble(value);
  if (quantity == null) return fallback;
  final formatted = _decimals(quantity, kQuantityDecimals, grouped: true);
  return unit == null || unit.isEmpty ? formatted : '$formatted $unit';
}

/// A percentage, e.g. `12,50%`. Expects a value already scaled to 0–100.
String formatPercent(Object? value, {String fallback = kMissingValue}) {
  final percent = _toDouble(value);
  if (percent == null) return fallback;
  return '${_decimals(percent, kPercentDecimals)}%';
}
