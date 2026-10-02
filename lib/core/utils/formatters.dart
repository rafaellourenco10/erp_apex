import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'pt_BR');

  static String currency(num value) => _currency.format(value);

  static final NumberFormat _currencyCompact = NumberFormat.compactCurrency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static final DateFormat _month = DateFormat('MMM', 'pt_BR');

  /// Short currency for tight spaces like chart labels, e.g. "R$ 12,5 mil".
  static String currencyCompact(num value) => _currencyCompact.format(value);

  static String date(DateTime value) => _date.format(value);

  /// Abbreviated month name, e.g. "set."
  static String month(DateTime value) => _month.format(value);

  /// Formats a Brazilian phone number, e.g. "43991112222" -> "(43) 99111-2222".
  static String phone(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return raw;
  }

  /// Returns up to two uppercase initials from a name, for avatar placeholders.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
