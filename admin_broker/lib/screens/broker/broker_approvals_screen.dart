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
import '../../models/approval_model.dart';
import '../../core/constants/app_constants.dart';
import '../../models/activity_log.dart';
import '../../models/broker_model.dart';

class BrokerApprovalsScreen extends ConsumerWidget {
  const BrokerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(brokerPendingUsersProvider);
    final broker = ref.watch(currentBrokerProvider).valueOrNull;
    final isLimitReached = broker != null && broker.maxUsers > 0 && broker.totalUsers >= broker.maxUsers;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 560.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Pending Approvals',
                  subtitle: 'Approve your pending users',
                  icon: Icons.task_alt_rounded,
                ),
                const SizedBox(height: 24),
                if (isLimitReached && broker != null) ...[
                  _buildLimitWarningBanner(context, broker),
                  const SizedBox(height: 24),
                ],
                pendingAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return _BrokerApprovalsEmpty(onGoDashboard: () => context.go('/broker'));
                    }
                    return LayoutBuilder(
                      builder: (context, inner) {
                        final cardWidth = inner.maxWidth > 600 ? inner.maxWidth.toDouble() : 600.0;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: cardWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: users
                                  .map(
                                    (u) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _BrokerApprovalCard(
                                        user: u,
                                        isLimitReached: isLimitReached,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => _BrokerApprovalsError(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(brokerPendingUsersProvider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  'You cannot approve new users or assign plans to new users. Please contact administration to upgrade your limit.',
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

class _BrokerApprovalsEmpty extends StatelessWidget {
  final VoidCallback onGoDashboard;

  const _BrokerApprovalsEmpty({required this.onGoDashboard});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inbox_outlined,
                    color: AppTheme.primaryColor,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nothing to approve right now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'When someone signs up in ReplyMate with your broker code, they appear here so you can choose a plan and activate their subscription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your code is shown in the top bar of this portal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onGoDashboard,
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: const Text('Dashboard'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.go('/broker/users'),
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('My Users'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrokerApprovalsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BrokerApprovalsError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppCard(
            title: 'Could not load approvals',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, color: AppTheme.errorColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrokerApprovalCard extends ConsumerWidget {
  final ReplymetUser user;
  final bool isLimitReached;
  const _BrokerApprovalCard({required this.user, required this.isLimitReached});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

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
              offset: const Offset(0, 2)),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.warningColor.withOpacity(0.15),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ),
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.name,
                    style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(user.email, style: TextStyle(color: textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(user.phone, style: TextStyle(color: textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Row(children: [
                  StatusBadge(status: user.status),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppUtils.formatDate(user.createdAt),
                      style: TextStyle(color: textSecondary, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLimitReached ? null : () => _showApprovalDialog(context, ref, user),
            icon: const Icon(Icons.check_circle_outline, size: 14),
            label: const Text('Approve', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isLimitReached ? Colors.grey : AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(
      BuildContext context, WidgetRef ref, ReplymetUser user) {
    showDialog(
      context: context,
      builder: (_) => _BrokerApprovalDialog(user: user),
    );
  }
}

/// Broker approval dialog - similar to admin but uses broker commission
class _BrokerApprovalDialog extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _BrokerApprovalDialog({required this.user});

  @override
  ConsumerState<_BrokerApprovalDialog> createState() =>
      _BrokerApprovalDialogState();
}

class _BrokerApprovalDialogState
    extends ConsumerState<_BrokerApprovalDialog> {
  PlanModel? _selectedPlan;
  DateTime _startDate = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(brokerAssignedPlansProvider);
    final currentBroker = ref.watch(currentBrokerProvider).valueOrNull;

    double brokerCommission = 0;
    double adminRevenue = 0;
    if (_selectedPlan != null && currentBroker != null) {
      brokerCommission = _selectedPlan!.price * currentBroker.commissionPercent / 100;
      adminRevenue = _selectedPlan!.price - brokerCommission;
    }

    return AlertDialog(
      title: Text('Approve ${widget.user.name}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
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
                              '${p.name} - ${AppUtils.formatCurrency(p.price)}'),
                        ))
                    .toList(),
                onChanged: (p) =>
                    setState(() => _selectedPlan = p),
              ),
              loading: () =>
                  const CircularProgressIndicator(),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 12),

            // Start date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 1)),
                  lastDate: DateTime.now()
                      .add(const Duration(days: 365)),
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
                    const Icon(Icons.calendar_today_rounded,
                        size: 18),
                    const SizedBox(width: 10),
                    Text(AppUtils.formatDate(_startDate)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded),
                  ],
                ),
              ),
            ),

            // Revenue split
            if (_selectedPlan != null && currentBroker != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue Split',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    _RevRow('Admin Revenue (${100 - currentBroker.commissionPercent}%)',
                        AppUtils.formatCurrency(adminRevenue)),
                    _RevRow('Your Commission (${currentBroker.commissionPercent}%)',
                        AppUtils.formatCurrency(brokerCommission),
                        color: AppTheme.accentColor),
                  ],
                ),
              ),
            ],
            FutureBuilder<ApprovalModel?>(
              future: ref.read(firestoreServiceProvider).getLatestApprovalForUser(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final oldApp = snapshot.data!;
                  final approvedAt = oldApp.approvedAt;
                  if (approvedAt != null) {
                    final diff = DateTime.now().difference(approvedAt);
                    if (diff.inHours < 24) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            border: Border.all(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Warning: A plan was assigned within the last 24 hours. Overriding it now will deduct/refund the old plan\'s revenue.',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed:
              (_selectedPlan == null || _loading) ? null : _approve,
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
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final currentBroker = ref.read(currentBrokerProvider).valueOrNull;
    if (currentUser == null || currentBroker == null) return;

    final brokerCommission = plan.price * currentBroker.commissionPercent / 100;
    final adminRevenue = plan.price - brokerCommission;

    setState(() => _loading = true);
    try {
      await ref.read(firestoreServiceProvider).approveUser(
            userId: widget.user.uid,
            approvedBy: currentUser.uid,
            approvedByRole: AppConstants.roleBroker,
            brokerId: currentUser.uid,
            plan: plan,
            startDate: _startDate,
            brokerCommission: brokerCommission,
            adminRevenue: adminRevenue,
          );

      // Log activity
      await ref.read(firestoreServiceProvider).logActivity(ActivityLog(
            logId: AppUtils.generateId(),
            action:
                'Broker approved user ${widget.user.name} with plan ${plan.name}',
            performedBy: currentUser.uid,
            performedByRole: AppConstants.roleBroker,
            targetId: widget.user.uid,
            targetType: 'user',
            createdAt: DateTime.now(),
          ));

      if (mounted) {
        Navigator.pop(context);
        showSnack(context, '${widget.user.name} approved!');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _RevRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _RevRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}
