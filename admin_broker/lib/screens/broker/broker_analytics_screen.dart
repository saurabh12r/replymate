import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/stat_card.dart';
import '../../models/approval_model.dart';

class BrokerAnalyticsScreen extends ConsumerWidget {
  const BrokerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBroker = ref.watch(currentBrokerProvider).valueOrNull;
    final brokerUsersAsync = ref.watch(brokerUsersProvider);
    final approvalsAsync = ref.watch(brokerApprovalsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'My Analytics',
            subtitle: 'Performance overview and earnings',
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 24),

          // Summary cards
          if (currentBroker != null)
            LayoutBuilder(builder: (ctx, constraints) {
              int cols = 4;
              if (constraints.maxWidth < 800) cols = 2;
              if (constraints.maxWidth < 500) cols = 1;
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
                    value: '${currentBroker.totalUsers}',
                    icon: Icons.people_alt_rounded,
                    gradient: AppTheme.primaryGradient,
                  ),
                  StatCard(
                    title: 'Total Earned',
                    value: AppUtils.formatCurrency(
                        currentBroker.walletBalance),
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: AppTheme.accentGradient,
                  ),
                  StatCard(
                    title: 'Active Users',
                    value: (brokerUsersAsync.valueOrNull ?? [])
                            .where((u) => u.isActive)
                            .length
                            .toString() ??
                        '—',
                    icon: Icons.check_circle_rounded,
                    gradient: AppTheme.warningGradient,
                  ),
                  StatCard(
                    title: 'Expiring Soon',
                    value: (brokerUsersAsync.valueOrNull ?? [])
                            .where((u) =>
                                u.isActive && u.isExpiringSoon)
                            .length
                            .toString() ??
                        '—',
                    icon: Icons.alarm_rounded,
                    gradient: AppTheme.errorGradient,
                  ),
                ],
              );
            }),
          const SizedBox(height: 24),

          // Approvals over time chart
          AppCard(
            title: 'Monthly Approvals',
            child: SizedBox(
              height: 240,
              child: approvalsAsync.when(
                data: (approvals) => _MonthlyApprovalsChart(approvals: approvals),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // User breakdown
          AppCard(
            title: 'User Status Breakdown',
            child: brokerUsersAsync.when(
              data: (users) {
                final active = users.where((u) => u.isActive).length;
                final pending = users.where((u) => u.isPending).length;
                final expired = users.where((u) => u.isExpired).length;
                final suspended = users.where((u) => u.isSuspended).length;
                final total = users.length;

                if (total == 0) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Users',
                    message: 'Start approving users to see analytics.',
                  );
                }

                return Column(
                  children: [
                    _StatBar('Active', active, total, AppTheme.successColor),
                    const SizedBox(height: 10),
                    _StatBar('Pending', pending, total, AppTheme.warningColor),
                    const SizedBox(height: 10),
                    _StatBar('Expired', expired, total, AppTheme.errorColor),
                    const SizedBox(height: 10),
                    _StatBar('Suspended', suspended, total, textSecondary),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ),
          const SizedBox(height: 20),

          // Expiring renewals
          AppCard(
            title: 'Renewal Reminders',
            child: brokerUsersAsync.when(
              data: (users) {
                final expiring = users
                    .where((u) => u.isActive && u.isExpiringSoon)
                    .toList()
                  ..sort((a, b) =>
                      (a.subscriptionEnd ?? DateTime.now()).compareTo(
                          b.subscriptionEnd ?? DateTime.now()));

                if (expiring.isEmpty) {
                  return const EmptyState(
                    icon: Icons.alarm_off_rounded,
                    title: 'No Renewals Needed',
                    message: 'No subscriptions expiring in next 7 days.',
                  );
                }

                return Column(
                  children: expiring.map((u) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm_rounded,
                            color: AppTheme.warningColor, size: 20),
                      ),
                      title: Text(u.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Expires: ${AppUtils.formatDate(u.subscriptionEnd)}',
                        style: TextStyle(
                            color: textSecondary, fontSize: 11),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppUtils.getDaysRemaining(u.subscriptionEnd),
                          style: const TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
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
}

class _StatBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _StatBar(this.label, this.count, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _MonthlyApprovalsChart extends StatelessWidget {
  final List<ApprovalModel> approvals;
  const _MonthlyApprovalsChart({required this.approvals});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    if (approvals.isEmpty) {
      return const Center(child: Text('No approvals yet'));
    }

    // Group by month
    final Map<String, int> monthlyCount = {};
    for (final a in approvals) {
      if (a.approvedAt != null) {
        final key =
            '${a.approvedAt!.year}-${a.approvedAt!.month.toString().padLeft(2, '0')}';
        monthlyCount[key] = (monthlyCount[key] ?? 0) + 1;
      }
    }

    final sortedKeys = monthlyCount.keys.toList()..sort();
    final bars = sortedKeys.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: monthlyCount[e.value]!.toDouble(),
            gradient: AppTheme.accentGradient,
            width: 24,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    final maxY = monthlyCount.values
        .fold(0, (prev, v) => v > prev ? v : prev)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.3,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= sortedKeys.length) return const Text('');
                final parts = sortedKeys[index].split('-');
                final months = [
                  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                final m = int.tryParse(parts.last) ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(months[m],
                      style: TextStyle(color: textSecondary, fontSize: 11)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: TextStyle(color: textSecondary, fontSize: 10),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                .withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: bars,
      ),
    );
  }
}
