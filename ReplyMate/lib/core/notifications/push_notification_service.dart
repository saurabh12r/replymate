import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'push_notification.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _boxName = 'push_notifications_box';
  late Box<PushNotification> _box;
  Box<PushNotification> get box => _box;

  bool _initialized = false;

  static Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(45)) {
        Hive.registerAdapter(PushNotificationAdapter());
      }
      instance._box = await Hive.openBox<PushNotification>(_boxName);
      instance._initialized = true;
      instance.cleanOldNotifications();
    } catch (e) {
      debugPrint('PushNotificationService init failed, attempting fallback: $e');
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        instance._box = await Hive.openBox<PushNotification>(_boxName);
        instance._initialized = true;
      } catch (e2) {
        debugPrint('PushNotificationService fallback failed: $e2');
      }
    }
  }

  /// Adds a new notification to the local store
  Future<void> addNotification(PushNotification notification) async {
    if (!_initialized) return;
    try {
      await _box.put(notification.id, notification);
    } catch (e, st) {
      debugPrint('Error saving push notification: $e\n$st');
    }
  }

  /// Marks a specific notification as read
  Future<void> markAsRead(String id) async {
    if (!_initialized) return;
    final notification = _box.get(id);
    if (notification != null && !notification.isRead) {
      notification.isRead = true;
      await _box.put(id, notification);
    }
  }

  /// Marks all notifications as read
  Future<void> markAllAsRead() async {
    if (!_initialized) return;
    final unread = _box.values.where((n) => !n.isRead).toList();
    for (var n in unread) {
      n.isRead = true;
      await _box.put(n.id, n);
    }
  }

  /// Deletes a specific notification
  Future<void> deleteNotification(String id) async {
    if (!_initialized) return;
    await _box.delete(id);
  }

  /// Clears all notifications
  Future<void> clearAll() async {
    if (!_initialized) return;
    await _box.clear();
  }

  /// Gets the count of unread notifications
  int get unreadCount {
    if (!_initialized) return 0;
    return _box.values.where((n) => !n.isRead).length;
  }

  /// Keeps only the most recent 200 notifications
  Future<void> cleanOldNotifications() async {
    if (!_initialized) return;
    final all = _box.values.toList();
    if (all.length > 200) {
      // Sort ascending (oldest first)
      all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final toDelete = all.take(all.length - 200).map((n) => n.id).toList();
      await _box.deleteAll(toDelete);
    }
  }
}
