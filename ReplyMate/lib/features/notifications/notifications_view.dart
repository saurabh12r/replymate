import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/notifications/push_notification.dart';
import '../../core/notifications/push_notification_service.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () => controller.markAllAsRead(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear all',
            onPressed: () {
              Get.defaultDialog(
                title: 'Clear All',
                middleText: 'Are you sure you want to clear all notifications?',
                textConfirm: 'Clear',
                textCancel: 'Cancel',
                confirmTextColor: Colors.white,
                onConfirm: () {
                  controller.clearAll();
                  Get.back();
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<PushNotification>>(
        valueListenable: PushNotificationService.instance.box.listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(50),
            ),
            itemBuilder: (context, index) {
              final n = notifications[index];
              final isUnread = !n.isRead;
              
              return Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  controller.deleteNotification(n.id);
                },
                child: Material(
                  color: isUnread 
                      ? theme.colorScheme.primary.withAlpha(10)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.markAsRead(n.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6, right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isUnread 
                                  ? theme.colorScheme.primary 
                                  : Colors.transparent,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: GoogleFonts.inter(
                                          fontWeight: isUnread 
                                              ? FontWeight.bold 
                                              : FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(n.timestamp),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: theme.colorScheme.onSurface.withAlpha(
                                      isUnread ? 255 : 200,
                                    ),
                                  ),
                                ),
                                if (n.imageUrl != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      n.imageUrl!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return DateFormat.jm().format(dt);
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(dt);
    } else {
      return DateFormat.MMMd().format(dt);
    }
  }
}
