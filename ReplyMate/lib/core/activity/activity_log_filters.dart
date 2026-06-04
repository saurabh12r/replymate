import 'activity_date_utils.dart';
import 'activity_log.dart';
import 'event_type.dart';
import 'filter_type.dart';
import 'log_filter_type.dart';

/// One pass: date range + call-type + search (after [sortedDesc] is already sorted).
List<ActivityLog> applyActivityLogFilters({
  required List<ActivityLog> sortedDesc,
  required LogFilterType dateFilter,
  required FilterType typeFilter,
  required String queryNormalized,
}) {
  final q = queryNormalized.trim().toLowerCase();
  final out = <ActivityLog>[];
  for (final e in sortedDesc) {
    switch (dateFilter) {
      case LogFilterType.today:
        if (!isToday(e.timestamp)) continue;
        break;
      case LogFilterType.week:
        if (!isWithin7Days(e.timestamp)) continue;
        break;
      case LogFilterType.all:
        break;
    }
    switch (typeFilter) {
      case FilterType.all:
        break;
      case FilterType.incoming:
        if (e.type != EventType.incomingCall &&
            e.type != EventType.busyCall &&
            e.type != EventType.rejectedCall) {
          continue;
        }
        break;
      case FilterType.missed:
        if (e.type != EventType.missedCall) continue;
        break;
      case FilterType.whatsapp:
        if (e.type != EventType.whatsappCall) continue;
        break;
      case FilterType.outgoing:
        if (e.type != EventType.outgoingAnswered &&
            e.type != EventType.outgoingUnanswered) {
          continue;
        }
        break;
    }
    if (q.isNotEmpty) {
      if (!e.name.toLowerCase().contains(q) &&
          !e.phoneNumber.toLowerCase().contains(q)) {
        continue;
      }
    }
    out.add(e);
  }
  return out;
}
