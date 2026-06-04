import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/replymet_user.dart';
import '../../models/plan_model.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/status_badge.dart';
import '../../core/constants/app_constants.dart';
import '../../models/activity_log.dart';

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(adminPendingUsersProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Pending Approvals',
            subtitle: 'Users awaiting subscription assignment',
            icon: Icons.pending_actions_rounded,
          ),
          const SizedBox(height: 24),
          pendingAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'All Approvals Done!',
                  message: 'No pending users at the moment.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: users
                    .map((u) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ApprovalCard(user: u),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading pending approvals...',
                        style:
                            TextStyle(color: AppTheme.darkTextSecondary)),
                  ],
                ),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      color: AppTheme.errorColor, size: 48),
                  const SizedBox(height: 12),
                  Text('Failed to load approvals',
                      style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('$e',
                      style: TextStyle(
                          color: AppTheme.errorColor, fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(adminPendingUsersProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final ReplymetUser user;

  const _ApprovalCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final textPrimary =
        isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.warningColor.withOpacity(0.15),
            child: Text(
              user.name.isNotEmpty
                  ? user.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          // User Info
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  user.email,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  user.phone,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    StatusBadge(status: user.status),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppUtils.formatDate(user.createdAt),
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Approve Button
          ElevatedButton.icon(
            onPressed: () =>
                _showApprovalDialog(context, ref, user),
            icon: const Icon(
              Icons.check_circle_outline,
              size: 14,
            ),
            label: const Text(
              'Approve',
              style: TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),

          // Reject Button
          OutlinedButton.icon(
            onPressed: () =>
                _rejectUser(context, ref, user),
            icon: const Icon(
              Icons.block_rounded,
              size: 14,
            ),
            label: const Text(
              'Reject',
              style: TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    WidgetRef ref,
    ReplymetUser user,
  ) {
    showDialog(
      context: context,
      builder: (_) => _ApprovalDialog(user: user),
    );
  }

  Future<void> _rejectUser(
    BuildContext context,
    WidgetRef ref,
    ReplymetUser user,
  ) async {
    await ConfirmDialog.show(
      context,
      title: 'Reject User',
      content:
          'Suspend "${user.name}"\'s registration?',
      confirmText: 'Reject',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref
            .read(firestoreServiceProvider)
            .updateUserStatus(
              user.uid,
              AppConstants.statusSuspended,
            );

        if (context.mounted) {
          showSnack(
            context,
            'User rejected',
            isError: true,
          );
        }
      },
    );
  }
}
class _ApprovalDialog extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _ApprovalDialog({required this.user});

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  PlanModel? _selectedPlan;
  DateTime _startDate = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(activePlansStreamProvider);
    // ✅ Removed unused ref.watch(currentUserProvider) from build()
    //    It was causing unnecessary rebuilds and the value was never used here.

    return AlertDialog(
      title: Text('Approve ${widget.user.name}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                  Text(widget.user.email,
                      style: const TextStyle(fontSize: 12)),
                  Text(widget.user.phone,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Plan selection
            const Text('Select Plan',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            plansAsync.when(
              data: (plans) => DropdownButtonFormField<PlanModel>(
                value: _selectedPlan,
                hint: const Text('Choose a plan'),
                decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.card_membership_rounded)),
                items: plans
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                              '${p.name} - ${AppUtils.formatCurrency(p.price)} / ${p.durationLabel}'),
                        ))
                    .toList(),
                onChanged: (p) => setState(() => _selectedPlan = p),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 16),

            // Start date
            const Text('Start Date',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 1)),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.darkBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(AppUtils.formatDate(_startDate)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),

            // Revenue split preview
            if (_selectedPlan != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue Preview',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Plan Price',
                            style: TextStyle(fontSize: 12)),
                        Text(
                            AppUtils.formatCurrency(
                                _selectedPlan!.price),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('End Date',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          AppUtils.formatDate(
                              AppUtils.calculateEndDate(_startDate,
                                  _selectedPlan!.durationDays)),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selectedPlan == null || _loading) ? null : _approve,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Approve & Activate'),
        ),
      ],
    );
  }

  Future<void> _approve() async {
    final plan = _selectedPlan!;

    // ✅ FIX: Read currentUser and guard null BEFORE doing anything.
    // .value on AsyncValue returns null when loading or errored —
    // force-unwrapping it with ! caused the minified type crash.
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      if (mounted) {
        showSnack(context, 'Session expired. Please log in again.',
            isError: true);
      }
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(firestoreServiceProvider).approveUser(
            userId: widget.user.uid,
            approvedBy: currentUser.uid,
            approvedByRole: AppConstants.roleAdmin,
            brokerId: widget.user.brokerId ?? '', // ✅ guard nullable brokerId
            plan: plan,
            startDate: _startDate,
            brokerCommission: 0, // Admin approval = no broker commission
            adminRevenue: plan.price,
          );

      // Log activity
      await ref.read(firestoreServiceProvider).logActivity(ActivityLog(
            logId: AppUtils.generateId(),
            action:
                'Approved user ${widget.user.name} with plan ${plan.name}',
            performedBy: currentUser.uid,
            performedByRole: AppConstants.roleAdmin,
            targetId: widget.user.uid,
            targetType: 'user',
            createdAt: DateTime.now(),
          ));

      if (mounted) {
        Navigator.pop(context);
        showSnack(context, '${widget.user.name} approved successfully!');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}