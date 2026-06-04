import 'package:hive/hive.dart';

/// Represents a single push notification received via FCM
class PushNotification {
  PushNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.type,
    this.payloadData,
    required this.timestamp,
    this.isRead = false,
  });

  String id;
  String title;
  String body;
  String? imageUrl;
  String? type;
  Map<String, dynamic>? payloadData;
  DateTime timestamp;
  bool isRead;

  // Helper copyWith method
  PushNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? type,
    Map<String, dynamic>? payloadData,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return PushNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      payloadData: payloadData ?? this.payloadData,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Hive TypeAdapter for [PushNotification].
/// Using typeId 45 to avoid conflict with ActivityLog (44).
class PushNotificationAdapter extends TypeAdapter<PushNotification> {
  @override
  final int typeId = 45;

  @override
  PushNotification read(BinaryReader reader) {
    return PushNotification(
      id: reader.readString(),
      title: reader.readString(),
      body: reader.readString(),
      imageUrl: reader.readBool() ? reader.readString() : null,
      type: reader.readBool() ? reader.readString() : null,
      payloadData: reader.readBool()
          ? Map<String, dynamic>.from(reader.readMap())
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        reader.readInt(),
        isUtc: true,
      ),
      isRead: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, PushNotification obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    
    // Nullable image URL
    writer.writeBool(obj.imageUrl != null);
    if (obj.imageUrl != null) writer.writeString(obj.imageUrl!);

    // Nullable type
    writer.writeBool(obj.type != null);
    if (obj.type != null) writer.writeString(obj.type!);

    // Nullable payload
    writer.writeBool(obj.payloadData != null);
    if (obj.payloadData != null) writer.writeMap(obj.payloadData!);

    // Timestamp & read status
    writer.writeInt(obj.timestamp.toUtc().millisecondsSinceEpoch);
    writer.writeBool(obj.isRead);
  }
}
