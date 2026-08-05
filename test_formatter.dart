class TextEditingValue {
  final String text;
  TextEditingValue({required this.text});
}
class PrefixTextInputFormatter {
  final String prefix;
  PrefixTextInputFormatter(this.prefix);
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (!newValue.text.startsWith(prefix)) {
      if (newValue.text.isEmpty) {
        return TextEditingValue(
          text: prefix,
        );
      }
      return oldValue;
    }
    final rest = newValue.text.substring(prefix.length);
    if (rest.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(rest)) {
      return oldValue;
    }
    return newValue;
  }
}
void main() {
  final formatter = PrefixTextInputFormatter('APT-');
  final result1 = formatter.formatEditUpdate(TextEditingValue(text: 'APT-'), TextEditingValue(text: 'APT-1'));
  print('result1: ' + result1.text);
  final result2 = formatter.formatEditUpdate(TextEditingValue(text: 'APT-'), TextEditingValue(text: '1APT-'));
  print('result2: ' + result2.text);
  final result3 = formatter.formatEditUpdate(TextEditingValue(text: ''), TextEditingValue(text: '1'));
  print('result3: ' + result3.text);
}
