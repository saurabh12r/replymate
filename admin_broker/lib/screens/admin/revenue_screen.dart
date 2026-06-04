import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/charts/revenue_chart.dart';
import '../../models/broker_model.dart';

class RevenueScreen extends ConsumerWidget {
  const RevenueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(monthlyRevenueProvider);
    final approvalsAsync = ref.watch(approvalsStreamProvider);
    final brokersAsync = ref.watch(brokersStreamProvider);
    final statsAsync = ref.watch(adminStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Revenue Analytics',
            subtitle: 'Financial overview and broker performance',
            icon: Icons.bar_chart_rounded,
          ),
          const SizedBox(height: 24),

          // Summary cards
          statsAsync.when(
            data: (stats) => _RevenueSummaryRow(stats: stats),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 24),

          // Revenue chart
          AppCard(
            title: 'Monthly Revenue (Admin Share)',
            child: SizedBox(
              height: 280,
              child: revenueAsync.when(
                data: (data) => RevenueChart(data: data),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Broker performance table
          AppCard(
            title: 'Broker Performance',
            child: brokersAsync.when(
              data: (brokers) => _BrokerPerformanceTable(brokers: brokers),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
            ),
          ),
          const SizedBox(height: 24),

          // Recent transactions
          AppCard(
            title: 'Recent Transactions',
            child: approvalsAsync.when(
              data: (approvals) {
                if (approvals.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions',
                    message: 'Approved subscriptions will appear here.',
                  );
                }
                return Column(
                  children: approvals.take(20).map((a) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_rounded,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(
                        'User: ${a.userId.substring(0, 8)}...',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'By ${a.approvedByRole} • ${AppUtils.formatDate(a.approvedAt)}',
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppUtils.formatCurrency(a.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Admin: ${AppUtils.formatCurrency(a.adminRevenue)}',
                            style: TextStyle(
                                color: AppTheme.successColor, fontSize: 11),
                          ),
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
}

class _RevenueSummaryRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _RevenueSummaryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      int cols = 3;
      if (constraints.maxWidth < 700) cols = 1;

      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 90,
        ),
        children: [
          _MiniStatCard(
            title: 'Total Revenue',
            value: AppUtils.formatCurrency((stats['totalRevenue'] ?? 0).toDouble()),
            icon: Icons.account_balance_wallet_rounded,
            gradient: AppTheme.primaryGradient,
          ),
          _MiniStatCard(
            title: 'Active Subscriptions',
            value: '${stats['activeSubscriptions'] ?? 0}',
            icon: Icons.card_membership_rounded,
            gradient: AppTheme.accentGradient,
          ),
          _MiniStatCard(
            title: 'Total Brokers',
            value: '${stats['totalBrokers'] ?? 0}',
            icon: Icons.handshake_rounded,
            gradient: AppTheme.warningGradient,
          ),
        ],
      );
    });
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                Text(title,
                    style: TextStyle(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerPerformanceTable extends ConsumerWidget {
  final List<BrokerModel> brokers;
  const _BrokerPerformanceTable({required this.brokers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    if (brokers.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'No Brokers',
        message: 'Add brokers to see performance data.',
      );
    }

    // Sort by totalRevenue descending
    final sorted = [...brokers]
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return LayoutBuilder(builder: (context, constraints) {
      final tableWidth = constraints.maxWidth > 700 ? constraints.maxWidth.toDouble() : 700.0;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('Broker', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Code', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Users', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Exp. Admin', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Paid', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Pending', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Status', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...sorted.map((b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                child: Text(
                                  b.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(b.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(b.brokerCode,
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('${b.totalUsers}',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(AppUtils.formatCurrency(b.totalAdminRevenue),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(AppUtils.formatCurrency(b.totalPaidToAdmin),
                              style: TextStyle(
                                  fontSize: 12, 
                                  color: b.totalPaidToAdmin > 0 ? AppTheme.successColor : textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(AppUtils.formatCurrency(b.totalPendingPayment),
                              style: TextStyle(
                                  fontSize: 12, 
                                  color: b.totalPendingPayment > 0 ? AppTheme.errorColor : AppTheme.successColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: b.isActive
                                      ? AppTheme.successColor
                                      : AppTheme.darkTextSecondary,
                                ),
                              ),
                              if (b.totalPendingPayment > 0) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _showPaymentDialog(context, ref, b),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Receive',
                                      style: TextStyle(
                                        color: AppTheme.successColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
    });
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, BrokerModel broker) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Receive Payment from ${broker.name}'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Expected: ${AppUtils.formatCurrency(broker.totalAdminRevenue)}'),
              const SizedBox(height: 4),
              Text('Already Received: ${AppUtils.formatCurrency(broker.totalPaidToAdmin)}'),
              const SizedBox(height: 4),
              Text('Pending: ${AppUtils.formatCurrency(broker.totalPendingPayment)}',
                  style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount Received',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0 && amount <= broker.totalPendingPayment) {
                final currentUser = ref.read(currentUserProvider).valueOrNull;
                ref.read(firestoreServiceProvider).recordBrokerPayment(
                  brokerId: broker.brokerId,
                  amount: amount,
                  receivedBy: currentUser?.uid ?? 'admin',
                );
                Navigator.pop(ctx);
                showSnack(context, 'Payment recorded!');
              }
            },
            child: const Text('Record'),
          ),
          if (broker.totalPendingPayment > 0)
            ElevatedButton(
              onPressed: () {
                final currentUser = ref.read(currentUserProvider).valueOrNull;
                ref.read(firestoreServiceProvider).recordBrokerPayment(
                  brokerId: broker.brokerId,
                  amount: broker.totalPendingPayment,
                  receivedBy: currentUser?.uid ?? 'admin',
                );
                Navigator.pop(ctx);
                showSnack(context, 'Full payment received!');
              },
              child: const Text('Receive Full'),
            ),
        ],
      ),
    );
  }
}
