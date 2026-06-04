import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/charts/revenue_chart.dart';
import '../../models/replymet_user.dart';
import '../../models/activity_log.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final revenueAsync = ref.watch(monthlyRevenueProvider);
    final allUsersAsync = ref.watch(allUsersStreamProvider);
    final pendingAsync = ref.watch(adminPendingUsersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          PageHeader(
            title: 'Dashboard',
            subtitle: 'Welcome back! Here\'s what\'s happening.',
            icon: Icons.dashboard_rounded,
            action: ElevatedButton.icon(
              onPressed: () => ref.invalidate(adminStatsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 28),

          // Stats cards
          statsAsync.when(
            data: (stats) => _StatsGrid(stats: stats),
            loading: () => const _StatsGridSkeleton(),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: AppTheme.errorColor)),
          ),
          const SizedBox(height: 28),

          // Charts row
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 900;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue chart
                  Expanded(
                    flex: 6,
                    child: AppCard(
                      title: 'Monthly Revenue',
                      trailing: _periodChip(),
                      child: SizedBox(
                        height: 240,
                        child: revenueAsync.when(
                          data: (data) => RevenueChart(data: data),
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('$e')),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // User status donut
                  Expanded(
                    flex: 4,
                    child: AppCard(
                      title: 'User Breakdown',
                      child: SizedBox(
                        height: 240,
                        child: allUsersAsync.when(
                          data: (users) => _buildDonut(users),
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('$e')),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                AppCard(
                  title: 'Monthly Revenue',
                  trailing: _periodChip(),
                  child: SizedBox(
                    height: 200,
                    child: revenueAsync.when(
                      data: (data) => RevenueChart(data: data),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  title: 'User Breakdown',
                  child: SizedBox(
                    height: 200,
                    child: allUsersAsync.when(
                      data: (users) => _buildDonut(users),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 28),

          // Bottom row: Pending approvals
          _PendingApprovalsCard(pendingAsync: pendingAsync),
        ],
      ),
    );
  }

  Widget _periodChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Last 6 months',
          style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildDonut(List<ReplymetUser> users) {
    return UserStatusDonut(
      active: users.where((u) => u.isActive).length,
      pending: users.where((u) => u.isPending).length,
      expired: users.where((u) => u.isExpired).length,
      suspended: users.where((u) => u.isSuspended).length,
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      int crossCount = 5;
      if (constraints.maxWidth < 1200) crossCount = 4;
      if (constraints.maxWidth < 900) crossCount = 3;
      if (constraints.maxWidth < 600) crossCount = 2;
      if (constraints.maxWidth < 400) crossCount = 1;

      final cards = [
        StatCard(
          title: 'Total Users',
          value: '${stats['totalUsers'] ?? 0}',
          icon: Icons.people_alt_rounded,
          gradient: AppTheme.primaryGradient,
          subtitle: 'All time',
        ),
        StatCard(
          title: 'Active Subscriptions',
          value: '${stats['activeSubscriptions'] ?? 0}',
          icon: Icons.card_membership_rounded,
          gradient: AppTheme.accentGradient,
          subtitle: 'Active',
        ),
        StatCard(
          title: 'Total Brokers',
          value: '${stats['totalBrokers'] ?? 0}',
          icon: Icons.handshake_rounded,
          gradient: AppTheme.warningGradient,
        ),
        StatCard(
          title: 'Total Revenue',
          value: AppUtils.formatCurrency(
              (stats['totalRevenue'] ?? 0).toDouble()),
          icon: Icons.account_balance_wallet_rounded,
          gradient: AppTheme.errorGradient,
        ),
        StatCard(
          title: 'Pending Approvals',
          value: '${stats['pendingApprovals'] ?? 0}',
          icon: Icons.pending_actions_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          subtitle: 'Need action',
        ),
      ];

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 180,
        ),
        itemCount: cards.length,
        itemBuilder: (ctx, i) => cards[i],
      );
    });
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      int crossCount = 5;
      if (constraints.maxWidth < 1200) crossCount = 4;
      if (constraints.maxWidth < 900) crossCount = 3;
      if (constraints.maxWidth < 600) crossCount = 2;
      if (constraints.maxWidth < 400) crossCount = 1;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 180,
        ),
        itemCount: 5,
        itemBuilder: (ctx, i) => const LoadingShimmer(height: 120),
      );
    });
  }
}

class _PendingApprovalsCard extends ConsumerWidget {
  final AsyncValue<List<ReplymetUser>> pendingAsync;
  const _PendingApprovalsCard({required this.pendingAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      title: 'Pending Approvals',
      trailing: TextButton(
        onPressed: () => context.go('/admin/approvals'),
        child: const Text('View All'),
      ),
      child: SizedBox(
        height: 280,
        child: pendingAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outlined,
              title: 'All Clear!',
              message: 'No pending approvals.',
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: users.length > 5 ? 5 : users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final user = users[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.warningColor.withOpacity(0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                title: Text(user.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(user.phone, style: const TextStyle(fontSize: 12)),
                trailing: TextButton(
                  onPressed: () => context.go('/admin/approvals'),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('$e'),
        ),
      ),
    );
  }
}


