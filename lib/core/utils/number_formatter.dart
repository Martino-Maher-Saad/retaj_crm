// كلاس لتنسيق الأرقام بفاصلة آلاف في حقل النص
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NumberFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,###");

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    // إزالة أي فواصل قديمة لتحويل النص لرقم
    String numStr = newValue.text.replaceAll(',', '');
    final number = int.tryParse(numStr);
    if (number == null) return oldValue;

    final newString = _formatter.format(number);
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}