String formatAmountMinor(int amountMinor) {
  final sign = amountMinor < 0 ? '-' : '';
  final abs = amountMinor.abs();
  final whole = abs ~/ 100;
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '$sign\$$whole.$cents';
}

String formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
