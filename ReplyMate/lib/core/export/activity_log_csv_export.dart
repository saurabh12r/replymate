import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../activity/activity_log.dart';
import '../activity/activity_log_channel.dart';
import '../activity/activity_log_display.dart';
import '../activity/event_type.dart';

/// RFC4180-style escaping for CSV cells.
String escapeCsvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// CSV header: Name, Phone, Type, Message, Replied, Date, Time
String generateCSV(List<ActivityLog> logs) {
  final buf = StringBuffer();
  buf.writeln('Name,Phone,Event Type,Message Sent,Replied,Date,Time');
  for (final log in logs) {
    final name = escapeCsvField(activityLogDisplayName(log));
    final phone = escapeCsvField(activityLogDisplayPhone(log));
    final type = escapeCsvField(_eventTypeExportLabel(log));
    final msg = escapeCsvField(log.messageSent);
    final replied = log.replied ? 'Yes' : 'No';
    final local = log.timestamp.toLocal();
    final date = '${local.year}-${_two(local.month)}-${_two(local.day)}';
    final time =
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
    buf.writeln('$name,$phone,$type,$msg,$replied,$date,$time');
  }
  return buf.toString();
}

/// Channel + reply outcome for the Event Type column.
String _eventTypeExportLabel(ActivityLog log) {
  final channel = switch (log.type) {
    EventType.incomingCall => 'Incoming',
    EventType.missedCall => 'Missed',
    EventType.whatsappCall => 'WhatsApp',
    EventType.busyCall => 'Busy',
    EventType.rejectedCall => 'Rejected',
    EventType.outgoingAnswered => 'Outgoing Answered',
    EventType.outgoingUnanswered => 'Outgoing Unanswered',
  };
  final outcome = log.replied ? 'Reply Sent' : 'Reply Failed';
  return '$channel — $outcome';
}

/// Generates CSV, writes to temp dir, then copies to public Downloads via native MediaStore.
/// Returns the saved file name so the caller can show it to the user.
Future<String> exportData(List<ActivityLog> logs) async {
  if (logs.isEmpty) {
    throw ArgumentError('No logs to export');
  }

  // Request storage permission on Android ≤ 12 (API 32)
  if (Platform.isAndroid) {
    final status = await Permission.storage.request();
    if (!status.isGranted && !status.isLimited) {
      // On Android 13+, storage permission is not needed for MediaStore writes
      // so we continue regardless
    }
  }

  final csv = generateCSV(logs);

  // Write to temp directory first (always writable, no permissions needed)
  final tmp = await getTemporaryDirectory();
  final now = DateTime.now();
  final fileName =
      'ReplyMate_Report_${now.year}-${_two(now.month)}-${_two(now.day)}_${now.millisecondsSinceEpoch}.csv';
  final tmpPath = '${tmp.path}/$fileName';
  final tmpFile = File(tmpPath);
  await tmpFile.writeAsString(csv, flush: true);

  if (!await tmpFile.exists()) {
    throw StateError('Failed to write temp CSV file');
  }

  // Copy to public Downloads via native MediaStore (Android 10+) or direct copy (Android ≤ 9)
  final channel = ActivityLogChannel();
  await channel.saveFileToDownloads(
    filePath: tmpPath,
    fileName: fileName,
    mimeType: 'text/csv',
  );

  // Clean up temp file
  try {
    await tmpFile.delete();
  } catch (_) {}

  return fileName;
}
