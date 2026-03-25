import 'activity_log.dart';
import 'log_filter_type.dart';

/// Calendar “today” in local timezone.
bool isToday(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

/// True if [date] is within the rolling last 7 days (local clock), inclusive of recent edge.
/// Future-dated rows are kept.
bool isWithin7Days(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  final diff = now.difference(local);
  if (diff.isNegative) return true;
  return diff.inDays < 7;
}

/// Rolling last 30 days (local), same semantics as [isWithin7Days].
bool isWithin30Days(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  final diff = now.difference(local);
  if (diff.isNegative) return true;
  return diff.inDays < 30;
}

/// Date-range filter only (newest-first list in → filtered list out).
List<ActivityLog> filterLogs(
  List<ActivityLog> logs,
  LogFilterType filter,
) {
  switch (filter) {
    case LogFilterType.today:
      return logs.where((e) => isToday(e.timestamp)).toList();
    case LogFilterType.week:
      return logs.where((e) => isWithin7Days(e.timestamp)).toList();
    case LogFilterType.all:
      return List<ActivityLog>.from(logs);
  }
}
