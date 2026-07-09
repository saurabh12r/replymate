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

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  int _page = 0;
  static const _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    final filteredUsers = ref.watch(filteredUsersProvider);
    final query = ref.watch(userSearchQueryProvider);
    final statusFilter = ref.watch(userStatusFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pagination
    final totalPages = (filteredUsers.length / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, filteredUsers.length);
    final pageUsers = filteredUsers.sublist(start, end);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Users Management',
            subtitle: '${filteredUsers.length} total users',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 20),

          // Search & Filters
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 768;
              final searchField = TextField(
                onChanged: (v) =>
                    ref.read(userSearchQueryProvider.notifier).state = v,
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => ref
                              .read(userSearchQueryProvider.notifier)
                              .state = '',
                        )
                      : null,
                ),
              );

              final filterChips = _StatusFilterChips(
                selected: statusFilter,
                onSelected: (s) =>
                    ref.read(userStatusFilterProvider.notifier).state = s,
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    filterChips,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 12),
                  filterChips,
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Users List
          _UsersList(
            users: pageUsers,
            onStatusChange: (user, status) =>
                _updateStatus(context, ref, user, status),
          ),
          const SizedBox(height: 16),

          // Pagination
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      _page > 0 ? () => setState(() => _page--) : null,
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
      ),
    );
  }

  Future<void> _updateStatus(
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
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _StatusFilterChips extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _StatusFilterChips(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      null,
      AppConstants.statusActive,
      AppConstants.statusPending,
      AppConstants.statusExpired,
      AppConstants.statusSuspended,
    ];
    final labels = ['All', 'Active', 'Pending', 'Expired', 'Suspended'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(statuses.length, (i) {
          final isSelected = selected == statuses[i];
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: FilterChip(
              label: Text(labels[i], style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onSelected(statuses[i]),
            ),
          );
        }),
      ),
    );
  }
}

class _UsersList extends ConsumerWidget {
  final List<ReplymetUser> users;
  final void Function(ReplymetUser, String) onStatusChange;

  const _UsersList({required this.users, required this.onStatusChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: EmptyState(
          icon: Icons.people_outlined,
          title: 'No Users Found',
          message: 'No users match your current filters.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _UserCard(
          user: users[index],
          onStatusChange: onStatusChange,
          isDark: isDark,
        );
      },
    );
  }
}

class _UserCard extends ConsumerStatefulWidget {
  final ReplymetUser user;
  final void Function(ReplymetUser, String) onStatusChange;
  final bool isDark;

  const _UserCard({
    required this.user,
    required this.onStatusChange,
    required this.isDark,
  });

  @override
  ConsumerState<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends ConsumerState<_UserCard> {
  bool _isHovered = false;

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ReplymetUser user) async {
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

  void _showRemovePlanConfirmation(BuildContext context, WidgetRef ref, ReplymetUser user) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    await ConfirmDialog.show(
      context,
      title: 'Remove Plan',
      content: 'Are you sure you want to remove the subscription plan for "${user.name}"? This will cancel their active subscription and reset their status to pending.',
      confirmText: 'Remove Plan',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).removeUserPlan(
          user.uid,
          performedBy: currentUser?.uid ?? 'admin',
          performedByRole: 'admin',
        );
        if (context.mounted) {
          showSnack(context, 'Subscription plan removed successfully');
        }
      },
    );
  }

  void _showRemoveQueuePlanConfirmation(BuildContext context, WidgetRef ref, ReplymetUser user) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    await ConfirmDialog.show(
      context,
      title: 'Remove Queue Plan',
      content: 'Are you sure you want to remove the queued subscription plan for "${user.name}"? This will cancel their next scheduled subscription plan.',
      confirmText: 'Remove Queue Plan',
      confirmColor: AppTheme.errorColor,
      onConfirm: () async {
        await ref.read(firestoreServiceProvider).removeQueuePlan(
          user.uid,
          performedBy: currentUser?.uid ?? 'admin',
          performedByRole: 'admin',
        );
        if (context.mounted) {
          showSnack(context, 'Queued subscription plan removed successfully');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primaryColor.withOpacity(0.4)
                : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? AppTheme.primaryColor.withOpacity(0.08)
                  : Colors.black.withOpacity(0.02),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.push('/admin/user/${Uri.encodeComponent(user.phone)}'),
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Builder(
                builder: (context) {
                  final isMobile = MediaQuery.of(context).size.width < 850;

                  if (isMobile) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Premium Status Left Accent Bar
                        Container(
                          width: 6,
                          color: _getStatusColor(user.status),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row: Avatar, Name & Phone/Email, StatusBadge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email,
                                            style: TextStyle(color: textSecondary, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone_android_rounded, size: 10, color: textSecondary.withOpacity(0.6)),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.phone,
                                                style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: user.status),
                                  ],
                                ),
                                
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                
                                // Plan & Subscription row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Active Plan Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.workspace_premium_rounded,
                                                size: 13,
                                                color: AppTheme.primaryColor.withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  planName ?? (user.planId?.isNotEmpty == true ? user.planId! : 'No Active Plan'),
                                                  style: TextStyle(
                                                    color: textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                user.hasBroker ? Icons.handshake_rounded : Icons.person_outline_rounded,
                                                size: 11,
                                                color: textSecondary.withOpacity(0.6),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  user.hasBroker ? 'Broker: ${user.brokerId}' : 'Direct Admin',
                                                  style: TextStyle(
                                                    color: textSecondary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (user.nextPlanId != null && user.nextPlanId!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
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
                                    
                                    // Expiration Info
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 10, color: textSecondary.withOpacity(0.6)),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.subscriptionEnd != null
                                                  ? AppUtils.formatDate(user.subscriptionEnd)
                                                  : '—',
                                              style: TextStyle(
                                                color: user.isExpiringSoon ? AppTheme.warningColor : textSecondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Expiry Date',
                                          style: TextStyle(color: textSecondary.withOpacity(0.6), fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Actions Deck
                                Row(
                                  children: [
                                    // Plan management button
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _showAssignPlanDialog(context, user),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              user.isActive ? Icons.schedule_rounded : Icons.add_circle_outline_rounded,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              user.isActive ? 'Queue Plan' : 'Assign Plan',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Status toggle
                                    if (user.isSuspended)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => widget.onStatusChange(user, AppConstants.statusActive),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.successColor,
                                            side: const BorderSide(color: AppTheme.successColor),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.play_arrow_rounded, size: 12),
                                              SizedBox(width: 4),
                                              Text('Activate', style: TextStyle(fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (user.isActive)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => widget.onStatusChange(user, AppConstants.statusSuspended),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.warningColor,
                                            side: const BorderSide(color: AppTheme.warningColor),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: const [
                                              Icon(Icons.pause_rounded, size: 12),
                                              SizedBox(width: 4),
                                              Text('Suspend', style: TextStyle(fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (user.planId != null && user.planId!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_remove_outlined, size: 16),
                                        color: AppTheme.warningColor,
                                        tooltip: 'Remove Current Plan',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.warningColor.withOpacity(0.08),
                                          padding: const EdgeInsets.all(10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _showRemovePlanConfirmation(context, ref, user),
                                      ),
                                    ],
                                    if (user.nextPlanId != null && user.nextPlanId!.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_schedule_send_rounded, size: 16),
                                        color: AppTheme.errorColor,
                                        tooltip: 'Remove Queue Plan',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.errorColor.withOpacity(0.08),
                                          padding: const EdgeInsets.all(10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _showRemoveQueuePlanConfirmation(context, ref, user),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      color: AppTheme.errorColor,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.errorColor.withOpacity(0.08),
                                        padding: const EdgeInsets.all(10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showDeleteConfirmation(context, ref, user),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Desktop Layout (Row-based columns)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Premium Status Left Accent Bar
                      Container(
                        width: 6,
                        color: _getStatusColor(user.status),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Col 1: User Profile Info (Left)
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                                      child: Text(
                                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            user.name,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            user.email,
                                            style: TextStyle(color: textSecondary, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.phone_android_rounded, size: 12, color: textSecondary.withOpacity(0.6)),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.phone,
                                                style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const VerticalDivider(width: 32, indent: 8, endIndent: 8),

                              // Col 2: Subscription Plan (Center)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          size: 14,
                                          color: AppTheme.primaryColor.withOpacity(0.8),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            planName ?? (user.planId?.isNotEmpty == true ? user.planId! : 'No Active Plan'),
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          user.hasBroker ? Icons.handshake_rounded : Icons.person_outline_rounded,
                                          size: 12,
                                          color: textSecondary.withOpacity(0.6),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            user.hasBroker ? 'Broker: ${user.brokerId}' : 'Direct Admin',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (user.nextPlanId != null && user.nextPlanId!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.schedule_send_rounded,
                                              size: 10,
                                              color: AppTheme.successColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Next: ${user.nextPlanName ?? user.nextPlanId}',
                                              style: const TextStyle(
                                                color: AppTheme.successColor,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 12, color: textSecondary.withOpacity(0.6)),
                                        const SizedBox(width: 6),
                                        Text(
                                          user.subscriptionEnd != null
                                              ? 'Expires: ${AppUtils.formatDate(user.subscriptionEnd)}'
                                              : 'Expires: —',
                                          style: TextStyle(
                                            color: user.isExpiringSoon ? AppTheme.warningColor : textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const VerticalDivider(width: 32, indent: 8, endIndent: 8),

                              // Col 3: Status Badge
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: StatusBadge(status: user.status),
                                ),
                              ),

                              const VerticalDivider(width: 32, indent: 8, endIndent: 8),

                              // Col 4: Action Buttons (Right)
                              Expanded(
                                flex: 4,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Plan management button
                                    ElevatedButton.icon(
                                      onPressed: () => _showAssignPlanDialog(context, user),
                                      icon: Icon(
                                        user.isActive ? Icons.schedule_rounded : Icons.add_circle_outline_rounded,
                                        size: 12,
                                      ),
                                      label: Text(
                                        user.isActive ? 'Queue Plan' : 'Assign Plan',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        elevation: 0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Status toggle
                                    if (user.isSuspended)
                                      OutlinedButton.icon(
                                        onPressed: () => widget.onStatusChange(user, AppConstants.statusActive),
                                        icon: const Icon(Icons.play_arrow_rounded, size: 12),
                                        label: const Text('Activate', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.successColor,
                                          side: const BorderSide(color: AppTheme.successColor),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    if (user.isActive)
                                      OutlinedButton.icon(
                                        onPressed: () => widget.onStatusChange(user, AppConstants.statusSuspended),
                                        icon: const Icon(Icons.pause_rounded, size: 12),
                                        label: const Text('Suspend', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.warningColor,
                                          side: const BorderSide(color: AppTheme.warningColor),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                    if (user.planId != null && user.planId!.isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_remove_outlined, size: 16),
                                        color: AppTheme.warningColor,
                                        tooltip: 'Remove Current Plan',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.warningColor.withOpacity(0.08),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        onPressed: () => _showRemovePlanConfirmation(context, ref, user),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (user.nextPlanId != null && user.nextPlanId!.isNotEmpty) ...[
                                      IconButton(
                                        icon: const Icon(Icons.cancel_schedule_send_rounded, size: 16),
                                        color: AppTheme.errorColor,
                                        tooltip: 'Remove Queue Plan',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.errorColor.withOpacity(0.08),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        onPressed: () => _showRemoveQueuePlanConfirmation(context, ref, user),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      color: AppTheme.errorColor,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.errorColor.withOpacity(0.08),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                      onPressed: () => _showDeleteConfirmation(context, ref, user),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ),
      ),
    ),
  );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusActive:
        return AppTheme.successColor;
      case AppConstants.statusPending:
        return AppTheme.primaryColor;
      case AppConstants.statusExpired:
        return AppTheme.errorColor;
      case AppConstants.statusSuspended:
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }
}

void _showAssignPlanDialog(BuildContext context, ReplymetUser user) {
  showDialog(
    context: context,
    builder: (_) => _AssignPlanDialog(user: user),
  );
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
                ...activePlans.map((plan) => _AdminPlanOption(
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

class _AdminPlanOption extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminPlanOption({
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
