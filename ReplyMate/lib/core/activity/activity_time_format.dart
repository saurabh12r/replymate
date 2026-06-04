/// Relative time for call-log style UI.
String formatTimeAgo(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  final minutes = diff.inMinutes;
  if (minutes < 60) {
    final m = minutes < 0 ? 0 : minutes;
    return '${m}m ago';
  }
  final hours = diff.inHours;
  if (hours < 24) {
    final h = hours < 0 ? 0 : hours;
    return '${h}h ago';
  }
  final days = diff.inDays;
  final d = days < 0 ? 0 : days;
  return '${d}d ago';
}
