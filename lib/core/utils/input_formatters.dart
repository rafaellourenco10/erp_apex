import 'package:flutter/services.dart';

String _onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

TextEditingValue _collapsedAtEnd(String text) {
  return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
}

/// Formats a Brazilian phone number while typing: "(44) 9999-0000" for 10
/// digits (landline), switching to "(44) 99999-0000" once an 11th digit
/// (cell phone) is entered. Limits input to 11 digits.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = _onlyDigits(newValue.text);
    if (digits.length > 11) digits = digits.substring(0, 11);

    final String text;
    if (digits.isEmpty) {
      text = '';
    } else if (digits.length <= 2) {
      text = '($digits';
    } else if (digits.length <= 6) {
      text = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.length <= 10) {
      text = '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else {
      text = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    return _collapsedAtEnd(text);
  }
}

/// Formats CPF ("000.000.000-00") while typing up to 11 digits, then
/// switches to CNPJ ("00.000.000/0000-00") once a 12th digit is entered.
/// Limits input to 14 digits (the maximum, for CNPJ).
class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = _onlyDigits(newValue.text);
    if (digits.length > 14) digits = digits.substring(0, 14);

    final String text;
    if (digits.length <= 11) {
      text = _formatCpf(digits);
    } else {
      text = _formatCnpj(digits);
    }
    return _collapsedAtEnd(text);
  }

  String _formatCpf(String d) {
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
    if (d.length <= 9) return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  String _formatCnpj(String d) {
    if (d.length <= 2) return d;
    if (d.length <= 5) return '${d.substring(0, 2)}.${d.substring(2)}';
    if (d.length <= 8) return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5)}';
    if (d.length <= 12) {
      return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8)}';
    }
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/'
        '${d.substring(8, 12)}-${d.substring(12)}';
  }
}
