import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../models/notification_model.dart';
import '../../core/constants/app_constants.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(adminNotificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PageHeader(
                  title: 'Notifications',
                  subtitle: 'Stay updated with new registrations and expiring subscriptions',
                  icon: Icons.notifications_rounded,
                ),
              ),
              TextButton.icon(
                onPressed: () => _markAllRead(ref),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No Notifications',
                  message: 'You\'re all caught up!',
                );
              }
              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: notifications.map((n) => _NotificationTile(
                    notification: n,
                    isDark: isDark,
                    onTap: () => _handleNotificationTap(context, ref, n),
                    onMarkRead: () => _markRead(ref, n.id),
                    onDelete: () => _deleteNotification(ref, n.id),
                  )).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _markAllRead(WidgetRef ref) {
    ref.read(firestoreServiceProvider).markAllNotificationsRead('admin');
  }

  void _markRead(WidgetRef ref, String id) {
    ref.read(firestoreServiceProvider).markNotificationRead(id);
  }

  void _deleteNotification(WidgetRef ref, String id) {
    ref.read(firestoreServiceProvider).deleteNotification(id);
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(firestoreServiceProvider).markNotificationRead(n.id);
    if (n.type == NotificationType.newUserRegistered && n.userId != null) {
      context.go('/admin/users');
    } else if (n.type == NotificationType.subscriptionExpiringSoon || 
               n.type == NotificationType.subscriptionExpired) {
      context.go('/admin/expired-users');
    }
  }
}

class BrokerNotificationsScreen extends ConsumerWidget {
  const BrokerNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(brokerNotificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PageHeader(
                  title: 'Notifications',
                  subtitle: 'Stay updated with your users',
                  icon: Icons.notifications_rounded,
                ),
              ),
              TextButton.icon(
                onPressed: () => _markAllRead(context, ref),
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          notificationsAsync.when(
            data: (notifications) {
              if (notifications.isEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No Notifications',
                  message: 'You\'re all caught up!',
                );
              }
              return AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: notifications.map((n) => _NotificationTile(
                    notification: n,
                    isDark: isDark,
                    onTap: () => _handleNotificationTap(context, ref, n),
                    onMarkRead: () => _markRead(ref, n.id),
                    onDelete: () => _deleteNotification(ref, n.id),
                  )).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _markAllRead(BuildContext context, WidgetRef ref) async {
    final broker = ref.read(currentBrokerProvider).valueOrNull;
    if (broker != null) {
      await ref.read(firestoreServiceProvider).markAllNotificationsRead('broker', targetId: broker.brokerId);
    }
  }

  void _markRead(WidgetRef ref, String id) {
    ref.read(firestoreServiceProvider).markNotificationRead(id);
  }

  void _deleteNotification(WidgetRef ref, String id) {
    ref.read(firestoreServiceProvider).deleteNotification(id);
  }

  void _handleNotificationTap(BuildContext context, WidgetRef ref, AppNotification n) {
    ref.read(firestoreServiceProvider).markNotificationRead(n.id);
    if (n.type == NotificationType.newUserRegistered && n.userId != null) {
      context.go('/broker/users');
    } else if (n.type == NotificationType.subscriptionExpiringSoon || 
               n.type == NotificationType.subscriptionExpired) {
      context.go('/broker/expired-users');
    }
  }
}

class _NotificationTile extends StatefulWidget {
  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onMarkRead,
    required this.onDelete,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final textPrimary = widget.isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = widget.isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    
    IconData icon;
    Color iconColor;
    switch (n.type) {
      case NotificationType.newUserRegistered:
        icon = Icons.person_add_rounded;
        iconColor = AppTheme.successColor;
        break;
      case NotificationType.subscriptionExpiringSoon:
        icon = Icons.warning_rounded;
        iconColor = AppTheme.warningColor;
        break;
      case NotificationType.subscriptionExpired:
        icon = Icons.timer_off_rounded;
        iconColor = AppTheme.errorColor;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryColor.withOpacity(0.04)
                : (n.isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.03)),
            border: Border(
              bottom: BorderSide(
                color: widget.isDark
                    ? AppTheme.darkBorder.withOpacity(0.5)
                    : AppTheme.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppUtils.formatRelativeTime(n.createdAt),
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (_hovered) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.check_circle_outline, color: textSecondary, size: 20),
                  onPressed: widget.onMarkRead,
                  tooltip: 'Mark as read',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                  onPressed: widget.onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}