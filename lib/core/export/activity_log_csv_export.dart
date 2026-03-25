import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../activity/activity_log.dart';
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
    final time = '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}';
    buf.writeln('$name,$phone,$type,$msg,$replied,$date,$time');
  }
  return buf.toString();
}

/// Channel + reply outcome for the Event Type column (spec: Incoming, Missed, WhatsApp, Reply Sent, Reply Failed).
String _eventTypeExportLabel(ActivityLog log) {
  final channel = switch (log.type) {
    EventType.incomingCall => 'Incoming',
    EventType.missedCall => 'Missed',
    EventType.whatsappCall => 'WhatsApp',
    EventType.busyCall => 'Busy',
    EventType.outgoingCall => 'Outgoing',
  };
  final outcome = log.replied ? 'Reply Sent' : 'Reply Failed';
  return '$channel — $outcome';
}

/// Writes CSV to the temp directory and opens the system share sheet.
Future<void> exportData(List<ActivityLog> logs) async {
  if (logs.isEmpty) {
    throw ArgumentError('No logs to export');
  }
  final csv = generateCSV(logs);
  final dir = await getTemporaryDirectory();
  final now = DateTime.now();
  final fileName =
      'analytics_${now.year}-${_two(now.month)}-${_two(now.day)}.csv';
  final path = '${dir.path}/$fileName';
  final file = File(path);
  await file.writeAsString(csv, flush: true);
  if (!await file.exists()) {
    throw StateError('Failed to write export file');
  }
  await Share.shareXFiles(
    [
      XFile(
        file.path,
        mimeType: 'text/csv',
        name: fileName,
      ),
    ],
    subject: 'ReplyMate activity export',
    text: 'Activity log export (${logs.length} rows)',
  );
}
