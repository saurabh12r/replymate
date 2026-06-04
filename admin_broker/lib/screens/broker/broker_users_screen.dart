import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/status_badge.dart';
import '../../models/replymet_user.dart';
import '../../models/plan_model.dart';
import '../../core/constants/app_constants.dart';

class BrokerUsersScreen extends ConsumerStatefulWidget {
  const BrokerUsersScreen({super.key});

  @override
  ConsumerState<BrokerUsersScreen> createState() => _BrokerUsersScreenState();
}

class _BrokerUsersScreenState extends ConsumerState<BrokerUsersScreen> {
  String _search = '';
  String? _statusFilter;
  int _page = 0;
  static const _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(brokerUsersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'My Users',
            subtitle: 'All users assigned to you',
            icon: Icons.group_rounded,
          ),
          const SizedBox(height: 20),
          usersAsync.when(
            data: (allUsers) {
              // Filter
              final filtered = allUsers.where((u) {
                final q = _search.toLowerCase();
                final matchesSearch = q.isEmpty ||
                    u.name.toLowerCase().contains(q) ||
                    u.phone.contains(q) ||
                    u.email.toLowerCase().contains(q);
                final matchesStatus =
                    _statusFilter == null || u.status == _statusFilter;
                return matchesSearch && matchesStatus;
              }).toList();

              final totalPages = (filtered.length / _pageSize).ceil();
              final start = _page * _pageSize;
              final end = (start + _pageSize).clamp(0, filtered.length);
              final pageUsers = filtered.isEmpty ? [] : filtered.sublist(start, end);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search & filter
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
                            hintText: 'Search users...',
                            prefixIcon:
                                Icon(Icons.search_rounded, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String?>(
                        value: _statusFilter,
                        hint: const Text('All Status'),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ...[
                            AppConstants.statusActive,
                            AppConstants.statusPending,
                            AppConstants.statusExpired,
                            AppConstants.statusSuspended,
                          ]
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.toUpperCase())))
                              .toList(),
                        ],
                        onChanged: (v) => setState(() {
                          _statusFilter = v;
                          _page = 0;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${filtered.length} users',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (pageUsers.isEmpty)
                    const EmptyState(
                      icon: Icons.group_outlined,
                      title: 'No Users Found',
                      message: 'No users match your current filters.',
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: pageUsers
                            .map((u) => _BrokerUserTile(user: u))
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

class _BrokerUserTile extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _BrokerUserTile({required this.user});

  @override
  ConsumerState<_BrokerUserTile> createState() => _BrokerUserTileState();
}

class _BrokerUserTileState extends ConsumerState<_BrokerUserTile> {
  bool _hovered = false;

  void _showDeleteConfirmation(BuildContext context) async {
    final user = widget.user;
    await ConfirmDialog.show(
      context,
      title: 'Delete User',
      content: 'Are you sure you want to delete "${user.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).deleteUser(user.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

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
                        : AppTheme.lightBorder)),
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
                    fontSize: 14),
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
                          fontWeight: FontWeight.w600)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (u.subscriptionEnd != null)
                    Text(
                      AppUtils.formatDate(u.subscriptionEnd),
                      style: TextStyle(
                        color: u.isExpiringSoon
                            ? AppTheme.warningColor
                            : textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  if (u.subscriptionEnd != null)
                    Text(
                      AppUtils.getDaysRemaining(u.subscriptionEnd),
                      style: TextStyle(
                        color: u.isExpiringSoon
                            ? AppTheme.warningColor
                            : textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            StatusBadge(status: u.status),
            const SizedBox(width: 8),
            if (u.isExpired)
              _ActionButton(
                label: 'Assign Plan',
                color: AppTheme.primaryColor,
                onTap: () => _showAssignPlanDialog(context, u),
              ),
            _ActionButton(
              label: 'Delete',
              color: AppTheme.errorColor,
              onTap: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
      ),
    ),);
  }

  void _showAssignPlanDialog(BuildContext context, ReplymetUser user) {
    showDialog(
      context: context,
      builder: (_) => _AssignPlanDialog(user: user),
    );
  }
}

class _AssignPlanDialog extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _AssignPlanDialog({required this.user});

  @override
  ConsumerState<_AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends ConsumerState<_AssignPlanDialog> {
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
              return const Text('No active plans available. Please create a plan first.');
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a plan:'),
                const SizedBox(height: 12),
                ...activePlans.map((plan) => _PlanOption(
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

class _PlanOption extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanOption({
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
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '${plan.durationLabel} • ₹${plan.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
