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
    required this.scheduledSent,
    required this.vacationSent,
    required this.scheduledFailed,
    required this.vacationFailed,
  });

  final int sent;
  final int failed;
  final int totalCalls;
  final int missedCalls;
  final int whatsappCalls;
  final int repliesSent;
  final int scheduledSent;
  final int vacationSent;
  final int scheduledFailed;
  final int vacationFailed;
}

/// Single-pass aggregation for today's logs only — O(n).
/// [sent]/[repliesSent]: auto-reply delivered; [failed]: no reply recorded for that activity.
TodayStats calculateTodayStats(List<ActivityLog> logs, {bool autoReplyEnabled = true}) {
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
  var scheduledSent = 0;
  var vacationSent = 0;
  var scheduledFailed = 0;
  var vacationFailed = 0;

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
      case EventType.scheduledSms:
        break;
    }
    
    if (log.type == EventType.scheduledSms) {
      // A scheduled SMS is Sent/Failed purely by its actual dispatch result
      // (log.replied, patched from the native send-result callback), independent
      // of the current auto-reply toggle. This keeps the dashboard counts
      // consistent with the Scheduled Messages screen and the analytics service,
      // both of which key off log.replied alone. Gating on autoReplyEnabled here
      // wrongly counted already-sent messages as failed whenever the toggle was off.
      if (log.replied) {
        scheduledSent++;
      } else {
        scheduledFailed++;
      }
    } else {
      if (log.replied && autoReplyEnabled) {
        sent++;
        repliesSent++;
        if (log.isVacation) {
          vacationSent++;
        }
      } else {
        failed++;
        if (log.isVacation) {
          vacationFailed++;
        }
      }
    }
  }

  return TodayStats(
    sent: sent + scheduledSent,
    failed: failed + scheduledFailed,
    totalCalls:
        incoming + missed + busy + rejected + outgoingAns + outgoingUnans,
    missedCalls: missed,
    whatsappCalls: whatsapp,
    repliesSent: repliesSent,
    scheduledSent: scheduledSent,
    vacationSent: vacationSent,
    scheduledFailed: scheduledFailed,
    vacationFailed: vacationFailed,
  );
}
