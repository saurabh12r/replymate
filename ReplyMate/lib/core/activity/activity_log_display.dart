import 'activity_log.dart';
import 'event_type.dart';

/// Display name: empty → "Unknown Number" (or "Private Number" if number is also empty).
String activityLogDisplayName(ActivityLog log) {
  final n = log.name.trim();
  if (n.isEmpty) {
    if (log.phoneNumber.trim().isEmpty) {
      return 'Private Number';
    }
    return 'Unknown Number';
  }
  return n;
}

/// Display phone: empty → "Unknown Origin".
String activityLogDisplayPhone(ActivityLog log) {
  final p = log.phoneNumber.trim();
  if (p.isEmpty) return 'Unknown Origin';
  return p;
}

String activityLogTypeLabel(EventType type) {
  switch (type) {
    case EventType.incomingCall:
      return 'Incoming';
    case EventType.missedCall:
      return 'Missed';
    case EventType.whatsappCall:
      return 'WhatsApp';
    case EventType.busyCall:
      return 'Busy';
    case EventType.rejectedCall:
      return 'Rejected';
    case EventType.outgoingAnswered:
      return 'Outgoing (Answered)';
    case EventType.outgoingUnanswered:
      return 'Outgoing (No Answer)';
    case EventType.scheduledSms:
      return 'Scheduled SMS';
  }
}
