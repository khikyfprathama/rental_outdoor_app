import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(newValue.text.replaceAll('.', ''));
    final formatter = NumberFormat.decimalPattern('id');
    String newText = formatter.format(value);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }

  static String format(double value) {
    return NumberFormat.decimalPattern('id').format(value);
  }

  static double parse(String value) {
    return double.tryParse(value.replaceAll('.', '')) ?? 0.0;
  }
}
