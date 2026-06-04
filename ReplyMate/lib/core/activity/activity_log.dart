import 'package:hive/hive.dart';

import 'event_type.dart';

/// Single persisted call-activity row (Hive).
class ActivityLog {
  ActivityLog({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.type,
    required this.replied,
    this.messageSent = '',
    required this.timestamp,
  });

  String id;
  String name;
  String phoneNumber;
  EventType type;
  bool replied;

  /// SMS body that was sent (or intended) for this row.
  String messageSent;
  DateTime timestamp;
}

/// Hive v3: adds [messageSent]. [typeId] 44 — schema bump wipes box on upgrade.
class ActivityLogAdapter extends TypeAdapter<ActivityLog> {
  @override
  final int typeId = 44;

  @override
  ActivityLog read(BinaryReader reader) {
    return ActivityLog(
      id: reader.readString(),
      name: reader.readString(),
      phoneNumber: reader.readString(),
      type: EventType.values[reader.readByte()],
      replied: reader.readBool(),
      messageSent: reader.readString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        reader.readInt(),
        isUtc: true,
      ),
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLog obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.phoneNumber);
    writer.writeByte(obj.type.index);
    writer.writeBool(obj.replied);
    writer.writeString(obj.messageSent);
    writer.writeInt(obj.timestamp.toUtc().millisecondsSinceEpoch);
  }
}
