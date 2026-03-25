import 'activity_log.dart';
import 'event_type.dart';

/// Display name: empty → "Private Number".
String activityLogDisplayName(ActivityLog log) {
  final n = log.name.trim();
  if (n.isEmpty) return 'Private Number';
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
    case EventType.outgoingCall:
      return 'Outgoing';
  }
}
