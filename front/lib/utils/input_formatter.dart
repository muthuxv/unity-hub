import 'package:flutter/services.dart';

class NumberRangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  NumberRangeTextInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else {
      final intValue = int.tryParse(newValue.text);
      if (intValue != null && intValue >= min && intValue <= max) {
        return newValue;
      }
    }
    return oldValue;
  }
}