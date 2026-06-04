import 'activity_date_utils.dart';
import 'activity_log.dart';
import 'event_type.dart';

/// Aggregated dashboard counters for the current local calendar day.
class TodayStats {
  const TodayStats({
    required this.sent,
    required this.failed,
    required this.totalCalls,
    required this.missedCalls,
    required this.whatsappCalls,
    required this.repliesSent,
  });

  final int sent;
  final int failed;
  final int totalCalls;
  final int missedCalls;
  final int whatsappCalls;
  final int repliesSent;
}

/// Single-pass aggregation for today's logs only — O(n).
/// [sent]/[repliesSent]: auto-reply delivered; [failed]: no reply recorded for that activity.
TodayStats calculateTodayStats(List<ActivityLog> logs) {
  var sent = 0;
  var failed = 0;
  var incoming = 0;
  var missed = 0;
  var whatsapp = 0;
  var busy = 0;
  var rejected = 0;
  var outgoingAns = 0;
  var outgoingUnans = 0;
  var repliesSent = 0;

  for (final log in logs) {
    if (!isToday(log.timestamp)) continue;
    switch (log.type) {
      case EventType.incomingCall:
        incoming++;
        break;
      case EventType.missedCall:
        missed++;
        break;
      case EventType.whatsappCall:
        whatsapp++;
        break;
      case EventType.busyCall:
        busy++;
        break;
      case EventType.rejectedCall:
        rejected++;
        break;
      case EventType.outgoingAnswered:
        outgoingAns++;
        break;
      case EventType.outgoingUnanswered:
        outgoingUnans++;
        break;
    }
    if (log.replied) {
      sent++;
      repliesSent++;
    } else {
      failed++;
    }
  }

  return TodayStats(
    sent: sent,
    failed: failed,
    totalCalls:
        incoming + missed + busy + rejected + outgoingAns + outgoingUnans,
    missedCalls: missed,
    whatsappCalls: whatsapp,
    repliesSent: repliesSent,
  );
}
