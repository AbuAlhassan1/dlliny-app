String formatChatRelative(DateTime when, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(when);

  if (diff.isNegative) return 'now';
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';

  final today = DateTime(reference.year, reference.month, reference.day);
  final that = DateTime(when.year, when.month, when.day);
  final dayDiff = today.difference(that).inDays;

  if (dayDiff == 1) return 'Yesterday';
  if (dayDiff < 7) return _weekday(when.weekday);
  return '${when.year}-${_two(when.month)}-${_two(when.day)}';
}

String _weekday(int w) {
  switch (w) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    default:
      return 'Sun';
  }
}

String _two(int n) => n < 10 ? '0$n' : '$n';

String formatChatBubbleTime(DateTime when) {
  return '${_two(when.hour)}:${_two(when.minute)}';
}

DateTime? tryParseChatTime(String? iso) {
  if (iso == null) return null;
  return DateTime.tryParse(iso)?.toLocal();
}
