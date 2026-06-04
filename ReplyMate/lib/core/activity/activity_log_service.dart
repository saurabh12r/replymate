import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'activity_date_utils.dart';
import 'activity_log.dart';
import 'activity_log_channel.dart';
import 'event_type.dart';

const String kActivityLogsBoxName = 'activity_logs';
const int _kHiveActivitySchemaVersion = 4;
const String _kHiveSchemaPrefsKey = 'activity_logs_hive_schema_v';

/// Hive-backed activity log + import from Android pending file.
class ActivityLogService {
  ActivityLogService._();

  static final ActivityLogService instance = ActivityLogService._();

  static const int _dedupeWindowMs = 2000;
  static const int _dedupeScanMax = 64;

  final ActivityLogChannel _channel = ActivityLogChannel();

  Box<ActivityLog>? _box;

  bool get isBoxReady {
    final b = _box;
    return b != null && b.isOpen;
  }

  Box<ActivityLog> get box {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError(
        'ActivityLogService: Hive box not open. Call init() first.',
      );
    }
    return b;
  }

  /// Registers adapter, migrates schema if needed, opens [kActivityLogsBoxName].
  static Future<void> init() async {
    void registerAdapterIfNeeded() {
      if (!Hive.isAdapterRegistered(ActivityLogAdapter().typeId)) {
        Hive.registerAdapter(ActivityLogAdapter());
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_kHiveSchemaPrefsKey) ?? 0;
      if (stored < _kHiveActivitySchemaVersion) {
        try {
          await Hive.deleteBoxFromDisk(kActivityLogsBoxName);
        } catch (_) {}
        await prefs.setInt(_kHiveSchemaPrefsKey, _kHiveActivitySchemaVersion);
      }
      registerAdapterIfNeeded();
      instance._box = await Hive.openBox<ActivityLog>(kActivityLogsBoxName);
    } catch (e, st) {
      assert(() {
        debugPrint(
          'ReplyMate: ActivityLogService.init primary path failed: $e\n$st',
        );
        return true;
      }());
      try {
        registerAdapterIfNeeded();
        instance._box = await Hive.openBox<ActivityLog>(kActivityLogsBoxName);
      } catch (e2, st2) {
        assert(() {
          debugPrint(
            'ReplyMate: ActivityLogService.init fallback failed: $e2\n$st2',
          );
          return true;
        }());
        instance._box = null;
      }
    }
  }

  /// Deletes entries older than 7 days (local rolling window). Returns removed count.
  Future<int> cleanOldLogs() async {
    if (!isBoxReady) return 0;
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
    if (!isBoxReady) return 0;
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
          final ts =
              map['timestamp'] as int? ??
              DateTime.now().toUtc().millisecondsSinceEpoch;

          final bool replied;
          if (kind == 'call') {
            replied = map['replied'] as bool? ?? false;
          } else {
            // Legacy native row: isSuccess → replied
            if (typeIndex < 0 || typeIndex >= EventType.values.length) continue;
            replied =
                map['isSuccess'] as bool? ?? map['replied'] as bool? ?? false;
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
    await resolveMissingContactNames();
    return n;
  }

  /// Helper to get the last 8 digits of a phone number for highly robust matching across country codes/formatting.
  String _normalizeForMatching(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 8) {
      return digits.substring(digits.length - 8);
    }
    return digits;
  }

  /// Walks through the Hive box and resolves any empty or placeholder names against the device contacts.
  Future<void> resolveMissingContactNames() async {
    if (!isBoxReady) return;
    try {
      final hasPerm = await fc.FlutterContacts.permissions.has(fc.PermissionType.read);
      if (!hasPerm) return;

      final contacts = await fc.FlutterContacts.getAll(
        properties: {fc.ContactProperty.phone},
      );
      if (contacts.isEmpty) return;

      // Build lookup map using last 8 digits
      final contactMap = <String, String>{};
      for (final c in contacts) {
        final displayName = c.displayName?.trim() ?? '';
        if (displayName.isEmpty) continue;
        for (final p in c.phones) {
          final numStr = p.normalizedNumber?.trim().isNotEmpty == true
              ? p.normalizedNumber!.trim()
              : p.number.trim();
          final matchKey = _normalizeForMatching(numStr);
          if (matchKey.isNotEmpty) {
            contactMap[matchKey] = displayName;
          }
        }
      }

      if (contactMap.isEmpty) return;

      final b = box;
      for (final key in b.keys) {
        final log = b.get(key);
        if (log == null) continue;
        final name = log.name.trim();
        // Resolve if the name is empty or currently shows a placeholder
        if (name.isEmpty || name == 'Unknown Number' || name == 'Private Number') {
          final matchKey = _normalizeForMatching(log.phoneNumber);
          if (matchKey.isNotEmpty && contactMap.containsKey(matchKey)) {
            final resolvedName = contactMap[matchKey]!;
            if (resolvedName != log.name) {
              await b.put(
                key,
                ActivityLog(
                  id: log.id,
                  name: resolvedName,
                  phoneNumber: log.phoneNumber,
                  type: log.type,
                  replied: log.replied,
                  messageSent: log.messageSent,
                  timestamp: log.timestamp,
                ),
              );
            }
          }
        }
      }
    } catch (e, st) {
      assert(() {
        debugPrint('ReplyMate: resolveMissingContactNames failed: $e\n$st');
        return true;
      }());
    }
  }

  /// Persists a call-activity row (tests / future Dart-side events).
  Future<void> saveCallLog({
    required EventType type,
    required String phoneNumber,
    String name = '',
    bool replied = false,
    String messageSent = '',
  }) async {
    if (!isBoxReady) return;
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

  Future<void> deleteLog(String id) async {
    if (!isBoxReady) return;
    await box.delete(id);
  }

  Future<bool> _putIfAllowed(ActivityLog candidate) async {
    if (!isBoxReady) return false;
    if (_isDuplicateOfRecent(candidate)) return false;
    await box.put(candidate.id, candidate);
    return true;
  }

  bool _isDuplicateOfRecent(ActivityLog candidate) {
    if (!isBoxReady) return false;
    final now = candidate.timestamp.toUtc().millisecondsSinceEpoch;
    final entries = box.toMap().entries.toList();
    final start = entries.length > _dedupeScanMax
        ? entries.length - _dedupeScanMax
        : 0;
    for (var i = entries.length - 1; i >= start; i--) {
      final other = entries[i].value;
      if (other.type != candidate.type) continue;
      if (other.phoneNumber != candidate.phoneNumber) continue;
      final delta = (now - other.timestamp.toUtc().millisecondsSinceEpoch)
          .abs();
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
}) => ActivityLogService.instance.saveCallLog(
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
