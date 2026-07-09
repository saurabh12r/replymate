import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/broker_model.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../widgets/common/status_badge.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/activity_log.dart';
import '../../models/replymet_user.dart';
import '../../models/plan_model.dart';

class BrokersScreen extends ConsumerStatefulWidget {
  const BrokersScreen({super.key});

  @override
  ConsumerState<BrokersScreen> createState() => _BrokersScreenState();
}

class _BrokersScreenState extends ConsumerState<BrokersScreen> {
  @override
  Widget build(BuildContext context) {
    final brokersAsync = ref.watch(brokersStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Broker Management',
            subtitle: 'Onboard and manage brokers',
            icon: Icons.handshake_rounded,
            action: ElevatedButton.icon(
              onPressed: () => _showAddBrokerDialog(context, ref),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add Broker'),
            ),
          ),
          const SizedBox(height: 24),
          brokersAsync.when(
            data: (brokers) {
              if (brokers.isEmpty) {
                return EmptyState(
                  icon: Icons.handshake_outlined,
                  title: 'No Brokers Yet',
                  message: 'Add your first broker to start managing users.',
                  action: ElevatedButton.icon(
                    onPressed: () => _showAddBrokerDialog(context, ref),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add Broker'),
                  ),
                );
              }
              return LayoutBuilder(builder: (ctx, constraints) {
                int cols = 3;
                if (constraints.maxWidth < 1100) cols = 2;
                if (constraints.maxWidth < 700) cols = 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 395,
                  ),
                  itemCount: brokers.length,
                  itemBuilder: (ctx, i) => _BrokerCard(
                    broker: brokers[i],
                    onToggle: () => _toggleBroker(context, ref, brokers[i]),
                    onEdit: () => _showEditBrokerDialog(context, ref, brokers[i]),
                    onDelete: () => _deleteBroker(context, ref, brokers[i]),
                  ),
                );
              });
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  void _showAddBrokerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _BrokerDialog(ref: ref),
    );
  }

  void _showEditBrokerDialog(
      BuildContext context, WidgetRef ref, BrokerModel broker) {
    showDialog(
      context: context,
      builder: (_) => _BrokerDialog(broker: broker, ref: ref),
    );
  }

  Future<void> _toggleBroker(
      BuildContext context, WidgetRef ref, BrokerModel broker) async {
    final action = broker.isActive ? 'suspend' : 'activate';
    await ConfirmDialog.show(
      context,
      title: '${action.capitalize()} Broker',
      content: 'Are you sure you want to $action "${broker.name}"?',
      confirmText: action.capitalize(),
      confirmColor:
          broker.isActive ? AppTheme.errorColor : AppTheme.successColor,
      onConfirm: () async {
        await ref
            .read(firestoreServiceProvider)
            .toggleBrokerStatus(broker.brokerId, !broker.isActive);
        if (context.mounted)
          showSnack(context, 'Broker ${action}d successfully');
      },
    );
  }

  Future<void> _deleteBroker(
      BuildContext context, WidgetRef ref, BrokerModel broker) async {
    await ConfirmDialog.show(
      context,
      title: 'Delete Broker',
      content: 'Are you sure you want to delete "${broker.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).deleteBroker(broker.brokerId);
        if (context.mounted) {
          showSnack(context, 'Broker deleted successfully');
        }
      },
    );
  }
}

extension StringCapExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _BrokerCard extends ConsumerStatefulWidget {
  final BrokerModel broker;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BrokerCard({
    required this.broker,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<_BrokerCard> createState() => _BrokerCardState();
}

class _BrokerCardState extends ConsumerState<_BrokerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.broker;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? AppTheme.primaryColor.withOpacity(0.4) : border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(_hovered ? 0.15 : 0.06),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                  child: Text(
                    b.name.isNotEmpty ? b.name[0].toUpperCase() : 'B',
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name,
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(b.brokerCode,
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
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
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            
            // At a Glance - Summary Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 At a Glance',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatRow(
                    icon: Icons.people_alt_rounded,
                    label: 'Total Users',
                    value: '${b.totalUsers}',
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Wallet Balance',
                    value: AppUtils.formatCurrency(b.walletBalance),
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.percent_rounded,
                    label: 'Commission',
                    value: '${b.commissionPercent}%',
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.people_outline_rounded,
                    label: 'User Limit',
                    value: b.maxUsers == 0 ? 'Unlimited' : '${b.maxUsers}',
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Total Revenue',
                    value: AppUtils.formatCurrency(b.totalRevenue),
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.money_off_rounded,
                    label: 'Pending to Admin',
                    value: AppUtils.formatCurrency(b.totalPendingPayment),
                    textSecondary: textSecondary,
                    valueColor: b.totalPendingPayment > 0 ? AppTheme.warningColor : null,
                  ),
                  const SizedBox(height: 4),
                  _StatRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Paid to Admin',
                    value: AppUtils.formatCurrency(b.totalPaidToAdmin),
                    textSecondary: textSecondary,
                    valueColor: AppTheme.successColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (b.totalPendingPayment > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(context, ref, b),
                      icon: const Icon(Icons.payments_rounded, size: 14),
                      label: const Text('Receive Payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: AppTheme.successColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // 2x2 Grid of Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text('Edit', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text('Delete', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppTheme.errorColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showBrokerUsersDialog(context, ref, b),
                        icon: const Icon(Icons.people_alt_rounded, size: 14),
                        label: const Text('View Users', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onToggle,
                        icon: Icon(
                            b.isActive
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 14),
                        label: Text(b.isActive ? 'Suspend' : 'Activate', style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: b.isActive
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBrokerUsersDialog(BuildContext context, WidgetRef ref, BrokerModel broker) {
    showDialog(
      context: context,
      builder: (_) => _BrokerUsersListDialog(broker: broker),
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, BrokerModel broker) {
    final amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Receive Payment from ${broker.name}'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total to Admin: ${AppUtils.formatCurrency(broker.totalAdminRevenue)}'),
                const SizedBox(height: 4),
                Text('Paid: ${AppUtils.formatCurrency(broker.totalPaidToAdmin)}'),
                const SizedBox(height: 4),
                Text('Pending: ${AppUtils.formatCurrency(broker.totalPendingPayment)}',
                    style: const TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Enter Amount Received',
                    prefixIcon: Icon(Icons.currency_rupee),
                    hintText: 'Enter amount broker paid',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            Builder(
              builder: (context) {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                final isValid = amount > 0 && amount <= broker.totalPendingPayment;
                return TextButton(
                  onPressed: isValid ? () {
                    final currentUser = ref.read(currentUserProvider).valueOrNull;
                    ref.read(firestoreServiceProvider).recordBrokerPayment(
                      brokerId: broker.brokerId,
                      amount: amount,
                      receivedBy: currentUser?.uid ?? 'admin',
                    );
                    Navigator.pop(ctx);
                    showSnack(context, 'Recorded: ${AppUtils.formatCurrency(amount)}');
                  } : null,
                  child: const Text('Record'),
                );
              },
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
                  showSnack(context, 'Full payment received: ${AppUtils.formatCurrency(broker.totalPendingPayment)}');
                },
                child: const Text('Mark Full Paid'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textSecondary;
  final Color? valueColor;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textSecondary,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    
    return Row(
      children: [
        Icon(icon, size: 14, color: textSecondary),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Text(label,
              style: TextStyle(color: textSecondary, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 2,
          child: Text(value,
              style: TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w600,
                color: valueColor ?? defaultColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

/// Dialog to add/edit broker
class _BrokerDialog extends ConsumerStatefulWidget {
  final BrokerModel? broker;
  final WidgetRef ref;

  const _BrokerDialog({this.broker, required this.ref});

  @override
  ConsumerState<_BrokerDialog> createState() => _BrokerDialogState();
}

class _BrokerDialogState extends ConsumerState<_BrokerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _passCtrl;
  late TextEditingController _commissionCtrl;
  late TextEditingController _maxUsersCtrl;
  bool _loading = false;

  bool get isEdit => widget.broker != null;
  List<String> _selectedPlanIds = [];

  @override
  void initState() {
    super.initState();
    final b = widget.broker;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _emailCtrl = TextEditingController(text: b?.email ?? '');
    _phoneCtrl = TextEditingController(text: b?.phone ?? '');
    _passCtrl = TextEditingController();
    _commissionCtrl =
        TextEditingController(text: b?.commissionPercent.toString() ?? '10');
    _maxUsersCtrl =
        TextEditingController(text: b?.maxUsers.toString() ?? '0');
    _selectedPlanIds = b?.assignedPlanIds != null ? List<String>.from(b!.assignedPlanIds) : [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _commissionCtrl.dispose();
    _maxUsersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansStreamProvider);
    return AlertDialog(
      title: Text(isEdit ? 'Edit Broker' : 'Add New Broker'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outlined)),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined)),
                  enabled: !isEdit,
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (!AppUtils.isValidEmail(v!)) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded)),
                    validator: (v) {
                      if (v?.isEmpty == true) return 'Required';
                      if (v!.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commissionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Commission %',
                      prefixIcon: Icon(Icons.percent_rounded),
                      suffixText: '%'),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    final val = double.tryParse(v!);
                    if (val == null || val < 0 || val > 100) {
                      return 'Enter 0-100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxUsersCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Max Users Limit (0 for Unlimited)',
                      prefixIcon: Icon(Icons.people_alt_outlined)),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    final val = int.tryParse(v!);
                    if (val == null || val < 0) {
                      return 'Enter 0 or a positive integer';
                    }
                    return null;
                  },
                ),
                plansAsync.when(
                  data: (plans) {
                    if (plans.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text('Assign Specific Plans',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                        const SizedBox(height: 8),
                        ...plans.map((plan) {
                          final isChecked = _selectedPlanIds.contains(plan.planId);
                          return CheckboxListTile(
                            title: Text(
                                '${plan.name} (${AppUtils.formatCurrency(plan.price)})'),
                            subtitle: Text(plan.durationLabel),
                            value: isChecked,
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedPlanIds.add(plan.planId);
                                } else {
                                  _selectedPlanIds.remove(plan.planId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Error loading plans: $e',
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Update' : 'Create Broker'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final fs = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final currentUser = ref.read(currentUserProvider).valueOrNull;

      if (isEdit) {
        // Update existing broker
        final updated = widget.broker!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          commissionPercent: double.parse(_commissionCtrl.text),
          maxUsers: int.parse(_maxUsersCtrl.text.trim()),
          assignedPlanIds: _selectedPlanIds,
        );
        await fs.updateBroker(updated);
      } else {
        // Create new broker auth account + Firestore documents
        final userModel = await authService.createBrokerAccount(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );

        final broker = BrokerModel(
          brokerId: userModel.uid,
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          brokerCode: AppUtils.generateBrokerCode(),
          commissionPercent: double.parse(_commissionCtrl.text),
          maxUsers: int.parse(_maxUsersCtrl.text.trim()),
          assignedPlanIds: _selectedPlanIds,
        );
        await fs.createBroker(broker);

        // Log activity
        await fs.logActivity(ActivityLog(
          logId: AppUtils.generateId(),
          action: 'Added new broker: ${broker.name} (${broker.brokerCode})',
          performedBy: currentUser?.uid ?? 'unknown',
          performedByRole: AppConstants.roleAdmin,
          targetId: broker.brokerId,
          targetType: 'broker',
          createdAt: DateTime.now(),
        ));
      }

      if (mounted) {
        Navigator.pop(context);
        showSnack(context,
            'Broker ${isEdit ? 'updated' : 'created'} successfully!');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _BrokerUsersListDialog extends ConsumerStatefulWidget {
  final BrokerModel broker;
  const _BrokerUsersListDialog({required this.broker});

  @override
  ConsumerState<_BrokerUsersListDialog> createState() => _BrokerUsersListDialogState();
}

class _BrokerUsersListDialogState extends ConsumerState<_BrokerUsersListDialog> {
  String _search = '';
  String? _statusFilter;
  int _page = 0;
  static const _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersByBrokerStreamProvider(widget.broker.brokerId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Users for Broker: ${widget.broker.name} (${widget.broker.brokerCode})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 1000,
        height: 600,
        child: usersAsync.when(
          data: (allUsers) {
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
            final pageUsers = filtered.isEmpty ? <ReplymetUser>[] : filtered.sublist(start, end);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search and Filters
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
                    const SizedBox(width: 12),
                    DropdownButton<String?>(
                      value: _statusFilter,
                      hint: const Text('All Status'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...[
                          AppConstants.statusActive,
                          AppConstants.statusPending,
                          AppConstants.statusExpired,
                          AppConstants.statusSuspended,
                        ].map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.toUpperCase()))).toList(),
                      ],
                      onChanged: (v) => setState(() {
                        _statusFilter = v;
                        _page = 0;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${filtered.length} users associated with this broker',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: pageUsers.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'No Users Found',
                          message: 'No users match your filters or this broker has no users.',
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 950,
                            child: ListView.builder(
                              itemCount: pageUsers.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // Header Row
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: isDark
                                                ? AppTheme.darkBorder
                                                : AppTheme.lightBorder),
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(flex: 3, child: Text('User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('Subscription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        Expanded(flex: 5, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      ],
                                    ),
                                  );
                                }
                                final u = pageUsers[index - 1];
                                return _BrokerUserListRow(
                                  user: u,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  onStatusChange: (user, status) => _updateUserStatus(context, ref, user, status),
                                  onDelete: (user) => _deleteUser(context, ref, user),
                                  onAssignPlan: (user) => _showAssignPlanDialog(context, ref, user),
                                  onMoveToAdmin: (user) => _moveToAdmin(context, ref, user),
                                );
                              },
                            ),
                          ),
                        ),
                ),
                if (totalPages > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _page > 0
                            ? () => setState(() => _page--)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Text('Page ${_page + 1} of $totalPages'),
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
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Future<void> _updateUserStatus(
    BuildContext context,
    WidgetRef ref,
    ReplymetUser user,
    String status,
  ) async {
    final label = status == AppConstants.statusActive
        ? 'activate'
        : status == AppConstants.statusSuspended
            ? 'suspend'
            : 'expire';

    await ConfirmDialog.show(
      context,
      title: '${label.capitalize()} User',
      content: 'Are you sure you want to $label "${user.name}"?',
      confirmText: label.capitalize(),
      confirmColor: status == AppConstants.statusActive
          ? AppTheme.successColor
          : AppTheme.errorColor,
      onConfirm: () async {
        await ref
            .read(firestoreServiceProvider)
            .updateUserStatus(user.uid, status);
        if (context.mounted) {
          showSnack(context, 'User ${label}d successfully');
        }
      },
    );
  }

  Future<void> _deleteUser(
    BuildContext context,
    WidgetRef ref,
    ReplymetUser user,
  ) async {
    await ConfirmDialog.show(
      context,
      title: 'Delete User',
      content: 'Are you sure you want to delete "${user.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).deleteUser(user.uid);
        if (context.mounted) {
          showSnack(context, 'User deleted successfully');
        }
      },
    );
  }

  Future<void> _moveToAdmin(
    BuildContext context,
    WidgetRef ref,
    ReplymetUser user,
  ) async {
    await ConfirmDialog.show(
      context,
      title: 'Move to Admin',
      content: 'Are you sure you want to move "${user.name}" to direct Admin management? They will no longer be associated with this broker.',
      confirmText: 'Move to Admin',
      confirmColor: AppTheme.primaryColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).moveUserToAdmin(user.uid);
        if (context.mounted) {
          showSnack(context, 'User moved to Admin management successfully');
        }
      },
    );
  }

  void _showAssignPlanDialog(BuildContext context, WidgetRef ref, ReplymetUser user) {
    showDialog(
      context: context,
      builder: (_) => _BrokerUserAssignPlanDialog(user: user),
    );
  }
}

class _BrokerUserListRow extends ConsumerWidget {
  final ReplymetUser user;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Function(ReplymetUser, String) onStatusChange;
  final Function(ReplymetUser) onDelete;
  final Function(ReplymetUser) onAssignPlan;
  final Function(ReplymetUser) onMoveToAdmin;

  const _BrokerUserListRow({
    required this.user,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onStatusChange,
    required this.onDelete,
    required this.onAssignPlan,
    required this.onMoveToAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansStreamProvider);
    final planName = plansAsync.maybeWhen(
            data: (plans) {
              for (final p in plans) {
                if (p.planId == user.planId) return p.name;
              }
              return null;
            },
            orElse: () => null,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: isDark
                  ? AppTheme.darkBorder.withOpacity(0.5)
                  : AppTheme.lightBorder),
        ),
      ),
      child: Row(
        children: [
          // User
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(user.email, style: TextStyle(color: textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Contact
          Expanded(
            flex: 2,
            child: Text(user.phone, style: TextStyle(color: textSecondary, fontSize: 12)),
          ),
          // Plan
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planName ?? (user.planId?.isNotEmpty == true ? user.planId! : '—'),
                  style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.nextPlanId != null && user.nextPlanId!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Next: ${user.nextPlanName ?? user.nextPlanId}',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Subscription
          Expanded(
            flex: 2,
            child: Text(
              user.subscriptionEnd != null
                  ? AppUtils.formatDate(user.subscriptionEnd)
                  : '—',
              style: TextStyle(
                color: user.isExpiringSoon ? AppTheme.warningColor : textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: StatusBadge(status: user.status),
          ),
          // Actions
          Expanded(
            flex: 5,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => onAssignPlan(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    user.isActive ? 'Queue Plan' : 'Assign Plan',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                if (user.isSuspended)
                  OutlinedButton(
                    onPressed: () => onStatusChange(user, AppConstants.statusActive),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                      side: const BorderSide(color: AppTheme.successColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Activate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                if (user.isActive)
                  OutlinedButton(
                    onPressed: () => onStatusChange(user, AppConstants.statusSuspended),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warningColor,
                      side: const BorderSide(color: AppTheme.warningColor),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Suspend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                OutlinedButton(
                  onPressed: () => onMoveToAdmin(user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentColor,
                    side: const BorderSide(color: AppTheme.accentColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Move to Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  onPressed: () => onDelete(user),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: 'Delete User',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerUserAssignPlanDialog extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _BrokerUserAssignPlanDialog({required this.user});

  @override
  ConsumerState<_BrokerUserAssignPlanDialog> createState() => _BrokerUserAssignPlanDialogState();
}

class _BrokerUserAssignPlanDialogState extends ConsumerState<_BrokerUserAssignPlanDialog> {
  PlanModel? _selectedPlan;
  bool _loading = false;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startDate = widget.user.subscriptionEnd ?? DateTime.now();
  }

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
                ...activePlans.map((plan) => _BrokerUserPlanOption(
                      plan: plan,
                      isSelected: _selectedPlan?.planId == plan.planId,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedPlan = plan),
                    )),
                const SizedBox(height: 16),
                const Text('Start Date:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _startDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.user.isActive && widget.user.subscriptionEnd != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Note: Start Date defaults to current plan expiration date (${AppUtils.formatDate(widget.user.subscriptionEnd)}).',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
        if (widget.user.isActive) ...[
          OutlinedButton(
            onPressed: _selectedPlan == null || _loading
                ? null
                : () => _assignPlan(context, isQueue: false),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Override Current'),
          ),
          ElevatedButton(
            onPressed: _selectedPlan == null || _loading
                ? null
                : () => _assignPlan(context, isQueue: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Queue Next Plan'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _selectedPlan == null || _loading
                ? null
                : () => _assignPlan(context, isQueue: false),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Assign Plan'),
          ),
        ],
      ],
    );
  }

  Future<void> _assignPlan(BuildContext context, {required bool isQueue}) async {
    if (_selectedPlan == null) return;
    setState(() => _loading = true);

    try {
      final admin = ref.read(currentUserProvider).valueOrNull;
      final brokerId = widget.user.brokerId;
      final brokerCommission = 0.0;
      final adminRevenue = _selectedPlan!.price;

      if (isQueue) {
        await ref.read(firestoreServiceProvider).queueNextPlanForUser(
              userId: widget.user.uid,
              approvedBy: admin?.uid ?? 'admin',
              approvedByRole: AppConstants.roleAdmin,
              plan: _selectedPlan!,
              brokerId: brokerId,
              brokerCommission: brokerCommission,
              adminRevenue: adminRevenue,
              startDate: _startDate,
            );
      } else {
        await ref.read(firestoreServiceProvider).assignPlanToUser(
              userId: widget.user.uid,
              approvedBy: admin?.uid ?? 'admin',
              approvedByRole: AppConstants.roleAdmin,
              plan: _selectedPlan!,
              brokerId: brokerId,
              brokerCommission: brokerCommission,
              adminRevenue: adminRevenue,
              startDate: _startDate,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isQueue 
                ? 'Plan queued as next subscription for ${widget.user.name}'
                : 'Plan assigned to ${widget.user.name}'),
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

class _BrokerUserPlanOption extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BrokerUserPlanOption({
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
