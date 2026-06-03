/// Lightweight French date formatting (no intl locale init required).
abstract class TantinDates {
  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  /// e.g. `5 juin`.
  static String dayMonth(DateTime date) {
    return '${date.day} ${_months[date.month - 1]}';
  }

  /// e.g. `Juin 2026`.
  static String monthYear(DateTime date) {
    final month = _months[date.month - 1];
    final capitalized = '${month[0].toUpperCase()}${month.substring(1)}';
    return '$capitalized ${date.year}';
  }

  /// Relative French label, e.g. `il y a 2 h`, falling back to `dayMonth`.
  static String relative(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);
    if (diff.isNegative) return dayMonth(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return dayMonth(date);
  }
}
