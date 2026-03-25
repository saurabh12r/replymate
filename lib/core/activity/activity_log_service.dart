import 'dart:convert';
import 'dart:math';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_date_utils.dart';
import 'activity_log.dart';
import 'activity_log_channel.dart';
import 'event_type.dart';

const String kActivityLogsBoxName = 'activity_logs';
const int _kHiveActivitySchemaVersion = 3;
const String _kHiveSchemaPrefsKey = 'activity_logs_hive_schema_v';

/// Hive-backed activity log + import from Android pending file.
class ActivityLogService {
  ActivityLogService._();

  static final ActivityLogService instance = ActivityLogService._();

  static const int _dedupeWindowMs = 2000;
  static const int _dedupeScanMax = 64;

  final ActivityLogChannel _channel = ActivityLogChannel();

  Box<ActivityLog>? _box;

  Box<ActivityLog> get box {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('ActivityLogService: Hive box not open. Call init() first.');
    }
    return b;
  }

  /// Registers adapter, migrates schema if needed, opens [kActivityLogsBoxName].
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_kHiveSchemaPrefsKey) ?? 0;
    if (stored < _kHiveActivitySchemaVersion) {
      await Hive.deleteBoxFromDisk(kActivityLogsBoxName);
      await prefs.setInt(_kHiveSchemaPrefsKey, _kHiveActivitySchemaVersion);
    }

    if (!Hive.isAdapterRegistered(ActivityLogAdapter().typeId)) {
      Hive.registerAdapter(ActivityLogAdapter());
    }
    instance._box = await Hive.openBox<ActivityLog>(kActivityLogsBoxName);
  }

  /// Deletes entries older than 7 days (local rolling window). Returns removed count.
  Future<int> cleanOldLogs() async {
    final b = box;
    final keysToDelete = <dynamic>[];
    for (final key in b.keys) {
      final log = b.get(key);
      if (log == null) {
        keysToDelete.add(key);
        continue;
      }
      if (!isWithin7Days(log.timestamp)) {
        keysToDelete.add(key);
      }
    }
    if (keysToDelete.isEmpty) return 0;
    await b.deleteAll(keysToDelete);
    return keysToDelete.length;
  }

  /// Import native pending lines (call rows + replied patches).
  Future<int> syncPendingFromNative() async {
    final lines = await _channel.pullPendingLogs();
    if (lines.isEmpty) return 0;
    var n = 0;
    for (final line in lines) {
      try {
        final map = jsonDecode(line) as Map<String, dynamic>;
        final kind = map['kind'] as String?;

        if (kind == 'patchReplied') {
          final id = map['id'] as String?;
          if (id == null) continue;
          final replied = map['replied'] as bool? ?? false;
          final existing = box.get(id);
          if (existing != null) {
            await box.put(
              id,
              ActivityLog(
                id: existing.id,
                name: existing.name,
                phoneNumber: existing.phoneNumber,
                type: existing.type,
                replied: replied,
                messageSent: existing.messageSent,
                timestamp: existing.timestamp,
              ),
            );
            n++;
          }
          continue;
        }

        if (kind == 'call' || kind == null) {
          final id = map['id'] as String? ?? _newId();
          final name = map['name'] as String? ?? '';
          final phone = map['phoneNumber'] as String? ?? '';
          final typeIndex = map['type'] as int? ?? 0;
          final ts = map['timestamp'] as int? ??
              DateTime.now().toUtc().millisecondsSinceEpoch;

          final bool replied;
          if (kind == 'call') {
            replied = map['replied'] as bool? ?? false;
          } else {
            // Legacy native row: isSuccess → replied
            if (typeIndex < 0 || typeIndex >= EventType.values.length) continue;
            replied = map['isSuccess'] as bool? ?? map['replied'] as bool? ?? false;
          }

          if (typeIndex < 0 || typeIndex >= EventType.values.length) continue;

          final messageSent = map['messageSent'] as String? ?? '';

          final inserted = await _putIfAllowed(
            ActivityLog(
              id: id,
              name: name,
              phoneNumber: phone,
              type: EventType.values[typeIndex],
              replied: replied,
              messageSent: messageSent,
              timestamp: DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true),
            ),
          );
          if (inserted) n++;
        }
      } catch (_) {
        // Skip malformed lines.
      }
    }
    return n;
  }

  /// Persists a call-activity row (tests / future Dart-side events).
  Future<void> saveCallLog({
    required EventType type,
    required String phoneNumber,
    String name = '',
    bool replied = false,
    String messageSent = '',
  }) async {
    final log = ActivityLog(
      id: _newId(),
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      type: type,
      replied: replied,
      messageSent: messageSent.trim(),
      timestamp: DateTime.now().toUtc(),
    );
    await _putIfAllowed(log);
  }

  Future<void> deleteLog(String id) => box.delete(id);

  Future<bool> _putIfAllowed(ActivityLog candidate) async {
    if (_isDuplicateOfRecent(candidate)) return false;
    await box.put(candidate.id, candidate);
    return true;
  }

  bool _isDuplicateOfRecent(ActivityLog candidate) {
    final now = candidate.timestamp.toUtc().millisecondsSinceEpoch;
    final entries = box.toMap().entries.toList();
    final start = entries.length > _dedupeScanMax ? entries.length - _dedupeScanMax : 0;
    for (var i = entries.length - 1; i >= start; i--) {
      final other = entries[i].value;
      if (other.type != candidate.type) continue;
      if (other.phoneNumber != candidate.phoneNumber) continue;
      final delta =
          (now - other.timestamp.toUtc().millisecondsSinceEpoch).abs();
      if (delta <= _dedupeWindowMs) return true;
    }
    return false;
  }

  static String _newId() {
    final r = Random();
    return '${DateTime.now().toUtc().millisecondsSinceEpoch}_${r.nextInt(1 << 32)}';
  }
}

/// Convenience: save a call log with current UTC timestamp.
Future<void> saveCallLog({
  required EventType type,
  required String phoneNumber,
  String name = '',
  bool replied = false,
  String messageSent = '',
}) =>
    ActivityLogService.instance.saveCallLog(
      type: type,
      phoneNumber: phoneNumber,
      name: name,
      replied: replied,
      messageSent: messageSent,
    );

/// Deletes activity rows older than 7 days.
Future<void> cleanOldLogs() async {
  await ActivityLogService.instance.cleanOldLogs();
}
