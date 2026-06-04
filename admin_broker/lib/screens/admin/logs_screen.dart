import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/status_badge.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Activity Logs',
            subtitle: 'Full audit trail of all actions',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 24),
          logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'No Logs Yet',
                  message: 'Activity logs will appear as actions are taken.',
                );
              }
              return AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final log = logs[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: log.performedByRole == 'admin'
                                  ? AppTheme.primaryGradient
                                  : AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getActionIcon(log.action),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.action,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    RoleBadge(role: log.performedByRole),
                                    const SizedBox(width: 8),
                                    Text(
                                      'UID: ${log.performedBy.substring(0, 8)}...',
                                      style: TextStyle(
                                          color: textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppUtils.formatDateTime(log.createdAt),
                            style: TextStyle(
                                color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
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

  IconData _getActionIcon(String action) {
    if (action.contains('plan')) return Icons.card_membership_rounded;
    if (action.contains('broker')) return Icons.handshake_rounded;
    if (action.contains('user') || action.contains('Approved')) {
      return Icons.person_rounded;
    }
    return Icons.bolt_rounded;
  }
}
