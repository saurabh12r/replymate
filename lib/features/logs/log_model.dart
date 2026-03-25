/// LogModel
/// Represents a single activity log entry.
class LogModel {
  const LogModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.callType,
    required this.timestamp,
    required this.replySent,
  });

  final String id;
  final String name;
  final String phone;
  final CallType callType;
  final DateTime timestamp;
  final bool replySent;

  String get callTypeLabel {
    switch (callType) {
      case CallType.incoming:
        return 'Incoming Call';
      case CallType.missed:
        return 'Missed Call';
      case CallType.whatsapp:
        return 'WhatsApp Call';
      case CallType.unknown:
        return 'Unknown Origin';
    }
  }
}

enum CallType { incoming, missed, whatsapp, unknown }
