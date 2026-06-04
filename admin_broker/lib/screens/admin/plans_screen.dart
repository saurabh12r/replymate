import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/plan_model.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_widgets.dart';
import '../../models/activity_log.dart';
import '../../core/constants/app_constants.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Subscription Plans',
            subtitle: 'Create and manage subscription plans',
            icon: Icons.card_membership_rounded,
            action: ElevatedButton.icon(
              onPressed: () => _showPlanDialog(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Plan'),
            ),
          ),
          const SizedBox(height: 24),
          plansAsync.when(
            data: (plans) {
              if (plans.isEmpty) {
                return EmptyState(
                  icon: Icons.card_membership_outlined,
                  title: 'No Plans Yet',
                  message: 'Create your first subscription plan to get started.',
                  action: ElevatedButton.icon(
                    onPressed: () => _showPlanDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Create Plan'),
                  ),
                );
              }
              return LayoutBuilder(builder: (ctx, constraints) {
                int cols = 3;
                if (constraints.maxWidth < 900) cols = 2;
                if (constraints.maxWidth < 600) cols = 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 220,
                  ),
                  itemCount: plans.length,
                  itemBuilder: (ctx, i) => _PlanCard(
                    plan: plans[i],
                    onEdit: () => _showPlanDialog(context, ref, plan: plans[i]),
                    onDelete: () => _deletePlan(context, ref, plans[i]),
                    onToggle: () => _togglePlan(ref, plans[i]),
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

  void _showPlanDialog(BuildContext context, WidgetRef ref, {PlanModel? plan}) {
    showDialog(
      context: context,
      builder: (_) => _PlanDialog(plan: plan, ref: ref),
    );
  }

  Future<void> _deletePlan(
      BuildContext context, WidgetRef ref, PlanModel plan) async {
    await ConfirmDialog.show(
      context,
      title: 'Delete Plan',
      content: 'Are you sure you want to delete "${plan.name}"?',
      confirmText: 'Delete',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).deletePlan(plan.planId);
        if (context.mounted) showSnack(context, 'Plan deleted successfully');
      },
    );
  }

  Future<void> _togglePlan(WidgetRef ref, PlanModel plan) async {
    final updated = plan.copyWith(isActive: !plan.isActive);
    await ref.read(firestoreServiceProvider).updatePlan(updated);
  }
}

class _PlanCard extends StatefulWidget {
  final PlanModel plan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _PlanCard({
    required this.plan,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    // Pick gradient based on duration
    LinearGradient gradient;
    if (plan.durationDays >= 365) {
      gradient = AppTheme.primaryGradient;
    } else if (plan.durationDays >= 180) {
      gradient = AppTheme.accentGradient;
    } else {
      gradient = AppTheme.warningGradient;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppTheme.primaryColor.withOpacity(0.4)
                : border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.15 : 0.06),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          plan.durationLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppUtils.formatCurrency(plan.price),
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.description,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete',
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            backgroundColor:
                                AppTheme.errorColor.withOpacity(0.1),
                          ),
                        ),
                        const Spacer(),
                        Switch.adaptive(
                          value: plan.isActive,
                          activeColor: AppTheme.successColor,
                          onChanged: (_) => widget.onToggle(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating/editing plans
class _PlanDialog extends ConsumerStatefulWidget {
  final PlanModel? plan;
  final WidgetRef ref;

  const _PlanDialog({this.plan, required this.ref});

  @override
  ConsumerState<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends ConsumerState<_PlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _descCtrl;
  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toString() ?? '');
    _durationCtrl =
        TextEditingController(text: p?.durationDays.toString() ?? '30');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.plan != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Plan' : 'Create Plan'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Plan Name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Price (₹)', prefixText: '₹ '),
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Required';
                        if (double.tryParse(v!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Duration (Days)'),
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Required';
                        if (int.tryParse(v!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Active'),
                  const Spacer(),
                  Switch.adaptive(
                    value: _isActive,
                    activeColor: AppTheme.successColor,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
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
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final isEdit = widget.plan != null;
      final plan = PlanModel(
        planId: widget.plan?.planId ?? AppUtils.generateId(),
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        durationDays: int.parse(_durationCtrl.text),
        description: _descCtrl.text.trim(),
        isActive: _isActive,
      );
      final fs = ref.read(firestoreServiceProvider);
      if (isEdit) {
        await fs.updatePlan(plan);
      } else {
        await fs.createPlan(plan);
      }

      // Log activity
      final user = ref.read(currentUserProvider).valueOrNull;
      await fs.logActivity(ActivityLog(
        logId: AppUtils.generateId(),
        action: '${isEdit ? 'Updated' : 'Created'} plan: ${plan.name}',
        performedBy: user?.uid ?? 'unknown',
        performedByRole: AppConstants.roleAdmin,
        targetId: plan.planId,
        targetType: 'plan',
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Plan ${isEdit ? 'updated' : 'created'} successfully!');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
