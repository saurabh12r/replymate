import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/status_badge.dart';
import '../../models/replymet_user.dart';
import '../../models/plan_model.dart';
import '../../core/constants/app_constants.dart';

class BrokerExpiredUsersScreen extends ConsumerStatefulWidget {
  const BrokerExpiredUsersScreen({super.key});

  @override
  ConsumerState<BrokerExpiredUsersScreen> createState() => _BrokerExpiredUsersScreenState();
}

class _BrokerExpiredUsersScreenState extends ConsumerState<BrokerExpiredUsersScreen> {
  String _search = '';
  int _page = 0;
  static const _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(brokerUsersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Expired Users',
            subtitle: 'Your users whose subscription has ended',
            icon: Icons.timer_off_rounded,
          ),
          const SizedBox(height: 20),
          usersAsync.when(
            data: (allUsers) {
              final expiredUsers = allUsers
                  .where((u) =>
                      u.status == AppConstants.statusExpired &&
                      !u.isSuspended)
                  .toList();

              final filtered = expiredUsers.where((u) {
                final q = _search.toLowerCase();
                return q.isEmpty ||
                    u.name.toLowerCase().contains(q) ||
                    u.phone.contains(q) ||
                    u.email.toLowerCase().contains(q);
              }).toList();

              final totalPages = (filtered.length / _pageSize).ceil();
              final start = _page * _pageSize;
              final end = (start + _pageSize).clamp(0, filtered.length);
              final pageUsers = filtered.isEmpty ? [] : filtered.sublist(start, end);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) {
                            setState(() {
                              _search = v;
                              _page = 0;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search by name, email, phone...',
                            prefixIcon: Icon(Icons.search_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${filtered.length} expired users',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (pageUsers.isEmpty)
                    const EmptyState(
                      icon: Icons.timer_off_outlined,
                      title: 'No Expired Users',
                      message: 'All your users have active subscriptions.',
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: pageUsers
                            .map((u) => _BrokerExpiredUserTile(user: u))
                            .toList(),
                      ),
                    ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _page > 0
                              ? () => setState(() => _page--)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Text('${_page + 1} / $totalPages'),
                        IconButton(
                          onPressed: _page < totalPages - 1
                              ? () => setState(() => _page++)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _BrokerExpiredUserTile extends StatefulWidget {
  final ReplymetUser user;
  const _BrokerExpiredUserTile({required this.user});

  @override
  State<_BrokerExpiredUserTile> createState() => _BrokerExpiredUserTileState();
}

class _BrokerExpiredUserTileState extends State<_BrokerExpiredUserTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () => context.push('/broker/user/${Uri.encodeComponent(u.phone)}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryColor.withOpacity(0.04)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppTheme.darkBorder.withOpacity(0.5)
                    : AppTheme.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              child: Text(
                u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.name,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(u.email,
                      style: TextStyle(color: textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(u.phone,
                  style: TextStyle(color: textSecondary, fontSize: 12)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                u.subscriptionEnd != null
                    ? AppUtils.formatDate(u.subscriptionEnd)
                    : '—',
                style: TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 11,
                ),
              ),
            ),
            StatusBadge(status: u.status),
            const SizedBox(width: 8),
            _AssignButton(
              label: 'Assign Plan',
              onTap: () => _showAssignPlanDialog(context, u),
            ),
          ],
        ),
      ),
    ),);
  }

  void _showAssignPlanDialog(BuildContext context, ReplymetUser user) {
    showDialog(
      context: context,
      builder: (_) => _BrokerAssignPlanDialog(user: user),
    );
  }
}

class _AssignButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AssignButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _BrokerAssignPlanDialog extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _BrokerAssignPlanDialog({required this.user});

  @override
  ConsumerState<_BrokerAssignPlanDialog> createState() => _BrokerAssignPlanDialogState();
}

class _BrokerAssignPlanDialogState extends ConsumerState<_BrokerAssignPlanDialog> {
  PlanModel? _selectedPlan;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text('Assign Plan to ${widget.user.name}'),
      content: SizedBox(
        width: 400,
        child: plansAsync.when(
          data: (plans) {
            final activePlans = plans.where((p) => p.isActive).toList();
            if (activePlans.isEmpty) {
              return const Text(
                  'No active plans available. Please create a plan first.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a plan:'),
                const SizedBox(height: 12),
                ...activePlans.map((plan) => _BrokerPlanOption(
                      plan: plan,
                      isSelected: _selectedPlan?.planId == plan.planId,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedPlan = plan),
                    )),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading plans: $e'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedPlan == null || _loading
              ? null
              : () => _assignPlan(context),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign Plan'),
        ),
      ],
    );
  }

  Future<void> _assignPlan(BuildContext context) async {
    if (_selectedPlan == null) return;
    setState(() => _loading = true);

    try {
      final broker = ref.read(currentBrokerProvider).valueOrNull;
      final brokerId = broker?.brokerId;
      final brokerCommission = _selectedPlan!.price * 0.20;
      final adminRevenue = _selectedPlan!.price * 0.80;

      await ref.read(firestoreServiceProvider).assignPlanToUser(
            userId: widget.user.uid,
            approvedBy: broker?.brokerId ?? 'unknown',
            approvedByRole: AppConstants.roleBroker,
            plan: _selectedPlan!,
            brokerId: brokerId,
            brokerCommission: brokerCommission,
            adminRevenue: adminRevenue,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan assigned to ${widget.user.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _BrokerPlanOption extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BrokerPlanOption({
    required this.plan,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.darkBorder.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primaryColor,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '${plan.durationLabel} • ₹${plan.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}