import 'package:intl/intl.dart';

String formatCurrency(num amount, {String currency = 'FCFA'}) {
  final f = NumberFormat('#,##0', 'fr_FR');
  return '${f.format(amount)} $currency';
}

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return DateFormat('dd/MM/yyyy').format(date);
}

String greetingByHour() {
  final h = DateTime.now().hour;
  if (h < 12) return 'goodMorning';
  if (h < 18) return 'goodAfternoon';
  return 'goodEvening';
}

bool isValidPhone(String phone) {
  return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone.replaceAll(' ', ''));
}

bool isValidEmail(String email) {
  return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
