import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    symbol: 'RWF ',
    decimalDigits: 0,
    locale: 'en_RW',
  );

  static String currency(double amount) => _currency.format(amount);

  static String date(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('MMM d, yyyy • h:mm a').format(dt);

  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);

  static String relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return date(dt);
  }

  static String compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  static String orderId(String id) =>
      '#${id.substring(0, 8).toUpperCase()}';

  static String phone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return phone;
  }

  static String rating(double rating) => rating.toStringAsFixed(1);

  static String percentage(double value) => '${value.toStringAsFixed(0)}%';

  static String weight(double kg) =>
      kg < 1 ? '${(kg * 1000).toStringAsFixed(0)}g' : '${kg.toStringAsFixed(1)}kg';
}
