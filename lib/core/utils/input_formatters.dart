import 'package:flutter/services.dart';

/// Upper-cases as the user types.
///
/// `TextCapitalization.characters` only asks the soft keyboard to *show* capital
/// letters — it does not touch the value, and it does nothing at all for a
/// hardware keyboard or a paste. A Codice Fiscale is stored, sent and compared
/// upper case, so a field that leaves the value as typed shows the customer
/// something different from what is saved, and a
/// pasted `rssmra…` reads back as a change they did not make.
///
/// The selection is carried over unchanged: case never alters length, so the
/// caret cannot move.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return newValue.copyWith(text: upper);
  }
}
