import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/status_badge.dart';
import '../../models/replymet_user.dart';
import '../../models/broker_model.dart';

class BrokerDashboardScreen extends ConsumerWidget {
  const BrokerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBroker = ref.watch(currentBrokerProvider).valueOrNull;
    final brokerUsersAsync = ref.watch(brokerUsersProvider);
    final pendingAsync = ref.watch(brokerPendingUsersProvider);
    final approvalsAsync = ref.watch(brokerApprovalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Broker Dashboard',
            subtitle: currentBroker != null
                ? 'Hello, ${currentBroker.name} 👋'
                : 'Loading...',
            icon: Icons.dashboard_rounded,
            action: currentBroker != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'YOUR BROKER CODE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentBroker.brokerCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: currentBroker.brokerCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied Broker Code: ${currentBroker.brokerCode}'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Copy Broker Code',
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 24),
          if (currentBroker != null && currentBroker.maxUsers > 0 && currentBroker.totalUsers >= currentBroker.maxUsers) ...[
            _buildLimitWarningBanner(context, currentBroker),
            const SizedBox(height: 24),
          ],

          // Broker stats
          if (currentBroker != null) ...[
            LayoutBuilder(builder: (ctx, constraints) {
              int cols = 6;
              if (constraints.maxWidth < 1200) cols = 5;
              if (constraints.maxWidth < 1000) cols = 4;
              if (constraints.maxWidth < 800) cols = 3;
              if (constraints.maxWidth < 600) cols = 2;
              if (constraints.maxWidth < 400) cols = 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 180,
                children: [
                  StatCard(
                    title: 'Total Users',
                    value: currentBroker.maxUsers == 0
                        ? '${currentBroker.totalUsers}'
                        : '${currentBroker.totalUsers} / ${currentBroker.maxUsers}',
                    icon: Icons.people_alt_rounded,
                    gradient: AppTheme.primaryGradient,
                    subtitle: currentBroker.maxUsers == 0
                        ? 'Unlimited users'
                        : 'Limit: ${currentBroker.maxUsers} users',
                  ),
                  StatCard(
                    title: 'Wallet Balance',
                    value: AppUtils.formatCurrency(currentBroker.walletBalance),
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: AppTheme.accentGradient,
                  ),
                  StatCard(
                    title: 'Commission %',
                    value: '${currentBroker.commissionPercent}%',
                    icon: Icons.percent_rounded,
                    gradient: AppTheme.warningGradient,
                  ),
                  StatCard(
                    title: 'Total Revenue',
                    value: AppUtils.formatCurrency(currentBroker.totalRevenue),
                    icon: Icons.bar_chart_rounded,
                    gradient: AppTheme.errorGradient,
                  ),
                  StatCard(
                    title: 'Admin Payment Due',
                    value: AppUtils.formatCurrency(currentBroker.totalPendingPayment),
                    icon: Icons.money_off_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFe74c3c), Color(0xFFc0392b)],
                    ),
                    subtitle: currentBroker.totalPendingPayment > 0 ? 'Pay to admin' : 'All clear',
                  ),
                  StatCard(
                    title: 'Paid to Admin',
                    value: AppUtils.formatCurrency(currentBroker.totalPaidToAdmin),
                    icon: Icons.check_circle_outline_rounded,
                    gradient: AppTheme.accentGradient,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
          ],

          // Pending approvals section
          AppCard(
            title: 'Pending Approvals',
            trailing: TextButton(
              onPressed: () => context.go('/broker/approvals'),
              child: const Text('View All'),
            ),
            child: pendingAsync.when(
              data: (pending) {
                if (pending.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 36, color: textSecondary.withOpacity(0.7)),
                        const SizedBox(height: 8),
                        Text(
                          'No pending sign-ups',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share your broker code from the top bar. New users appear here and on Approvals.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textSecondary, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: pending.take(5).map((u) => _UserTile(user: u)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ),
          const SizedBox(height: 20),

          // Expiring soon section
          AppCard(
            title: 'Expiring Soon',
            child: brokerUsersAsync.when(
              data: (users) {
                final expiring = users
                    .where((u) => u.isActive && u.isExpiringSoon)
                    .toList();
                if (expiring.isEmpty) {
                  return const EmptyState(
                    icon: Icons.alarm_off_rounded,
                    title: 'No Expiring Users',
                    message: 'No subscriptions expiring in 7 days.',
                  );
                }
                return Column(
                  children: expiring.take(5).map((u) => _ExpiringTile(user: u)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ),
          const SizedBox(height: 20),

          // Recent approvals
          AppCard(
            title: 'Recent Approvals',
            child: approvalsAsync.when(
              data: (approvals) {
                if (approvals.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Approvals Yet',
                    message: 'Your approved subscriptions appear here.',
                  );
                }
                return Column(
                  children: approvals.take(5).map((a) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(
                          'User: ${a.userId.substring(0, 8)}...',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(AppUtils.formatDateTime(a.approvedAt),
                          style: TextStyle(color: textSecondary, fontSize: 11)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(AppUtils.formatCurrency(a.amount),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('Earned: ${AppUtils.formatCurrency(a.brokerCommission)}',
                              style: TextStyle(color: AppTheme.successColor, fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitWarningBanner(BuildContext context, BrokerModel broker) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Limit Reached (${broker.totalUsers} / ${broker.maxUsers})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have reached your broker user limit. You cannot approve new users or assign plans to new users. Please contact administration to upgrade your limit.',
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final ReplymetUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppTheme.warningColor.withOpacity(0.15),
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppTheme.warningColor, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      title: Text(user.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(user.phone, style: TextStyle(color: textSecondary, fontSize: 11)),
      trailing: StatusBadge(status: user.status),
    );
  }
}

class _ExpiringTile extends StatelessWidget {
  final ReplymetUser user;
  const _ExpiringTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.alarm_rounded, color: AppTheme.warningColor, size: 18),
      ),
      title: Text(user.name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        'Expires ${AppUtils.formatDate(user.subscriptionEnd)}',
        style: TextStyle(color: AppTheme.warningColor, fontSize: 11),
      ),
      trailing: Text(
        AppUtils.getDaysRemaining(user.subscriptionEnd),
        style: const TextStyle(
            color: AppTheme.warningColor, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
