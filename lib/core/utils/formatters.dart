import 'package:intl/intl.dart';

/// Display formatting helpers shared across features.
abstract final class Formatters {
  static final _thousands = NumberFormat('#,##0', 'en_US');

  /// 450000 -> "RWF 450,000".
  static String rwf(int amount) => 'RWF ${_thousands.format(amount)}';

  /// 450000 -> "RWF 450K", used where space is tight (compare table).
  static String rwfShort(int amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return 'RWF ${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}M';
    }
    if (amount >= 1000) return 'RWF ${(amount / 1000).round()}K';
    return 'RWF $amount';
  }

  /// 1.234 -> "1.2 km".
  static String km(double value) => '${value.toStringAsFixed(1)} km';

  /// "Sat 3 Oct 2026".
  static String longDate(DateTime d) => DateFormat('EEE d MMM y').format(d);

  /// "26 Sep".
  static String dayMonth(DateTime d) => DateFormat('d MMM').format(d);

  /// "Sat".
  static String weekday(DateTime d) => DateFormat('EEE').format(d);

  /// "Sat 3 Oct".
  static String shortDate(DateTime d) => DateFormat('EEE d MMM').format(d);

  /// "12 Sep 2026".
  static String date(DateTime d) => DateFormat('d MMM y').format(d);

  /// "+250 788 123 456" from a 9-digit local number.
  static String phone(String localNumber) {
    final digits = localNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return '+250 $localNumber';
    return '+250 ${digits.substring(0, 3)} ${digits.substring(3, 6)} '
        '${digits.substring(6)}';
  }

  /// "Jean Claude M." -> "JM"
  static String initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty && RegExp('[A-Za-z]').hasMatch(p[0]))
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
