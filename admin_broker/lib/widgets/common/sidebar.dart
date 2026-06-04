import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  _NavItem(this.label, this.icon, this.route);
}

final _adminNavItems = [
  _NavItem('Dashboard', Icons.dashboard_rounded, '/admin'),
  _NavItem('Users', Icons.people_alt_rounded, '/admin/users'),
  _NavItem('Expired Users', Icons.timer_off_rounded, '/admin/expired-users'),
  _NavItem('Pending Approvals', Icons.pending_actions_rounded, '/admin/approvals'),
  _NavItem('Brokers', Icons.handshake_rounded, '/admin/brokers'),
  _NavItem('Plans', Icons.card_membership_rounded, '/admin/plans'),
  _NavItem('Revenue', Icons.bar_chart_rounded, '/admin/revenue'),
  _NavItem('Statistics', Icons.analytics_rounded, '/admin/stats'),
  _NavItem('Campaigns', Icons.campaign_rounded, '/admin/campaigns'),
  _NavItem('Notifications', Icons.notifications_rounded, '/admin/notifications'),
  _NavItem('Logs', Icons.history_rounded, '/admin/logs'),
  _NavItem('Settings', Icons.settings_rounded, '/admin/settings'),
];

final _brokerNavItems = [
  _NavItem('Dashboard', Icons.dashboard_rounded, '/broker'),
  _NavItem('My Users', Icons.group_rounded, '/broker/users'),
  _NavItem('Expired Users', Icons.timer_off_rounded, '/broker/expired-users'),
  _NavItem('Campaigns', Icons.campaign_rounded, '/broker/campaigns'),
  _NavItem('Notifications', Icons.notifications_rounded, '/broker/notifications'),
  _NavItem('Approvals', Icons.task_alt_rounded, '/broker/approvals'),
  _NavItem('Analytics', Icons.analytics_rounded, '/broker/analytics'),
];

/// Admin sidebar navigation
class AdminSidebar extends ConsumerStatefulWidget {
  const AdminSidebar({super.key});

  @override
  ConsumerState<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends ConsumerState<AdminSidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final items = currentUser?.isAdmin == true ? _adminNavItems : _brokerNavItems;
    return _SidebarBase(
      items: items,
      collapsed: _collapsed,
      onToggle: () => setState(() => _collapsed = !_collapsed),
      userName: currentUser?.name ?? 'User',
      userEmail: currentUser?.email ?? '',
      userRole: currentUser?.role ?? '',
    );
  }
}

/// Broker sidebar navigation
class BrokerSidebar extends ConsumerStatefulWidget {
  const BrokerSidebar({super.key});

  @override
  ConsumerState<BrokerSidebar> createState() => _BrokerSidebarState();
}

class _BrokerSidebarState extends ConsumerState<BrokerSidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    return _SidebarBase(
      items: _brokerNavItems,
      collapsed: _collapsed,
      onToggle: () => setState(() => _collapsed = !_collapsed),
      userName: currentUser?.name ?? 'Broker',
      userEmail: currentUser?.email ?? '',
      userRole: 'broker',
    );
  }
}

class _SidebarBase extends ConsumerWidget {
  final List<_NavItem> items;
  final bool collapsed;
  final VoidCallback onToggle;
  final String userName;
  final String userEmail;
  final String userRole;

  const _SidebarBase({
    required this.items,
    required this.collapsed,
    required this.onToggle,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final location = GoRouterState.of(context).matchedLocation;

    final width = collapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
          // Logo & collapse toggle
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ReplyMate',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    collapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                    color: textSecondary,
                    size: 20,
                  ),
                  tooltip: collapsed ? 'Expand' : 'Collapse',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: items.map((item) {
                final isActive = location == item.route ||
                    (item.route != '/admin' &&
                        item.route != '/broker' &&
                        location.startsWith(item.route));
                return _NavTile(
                  item: item,
                  isActive: isActive,
                  collapsed: collapsed,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              }).toList(),
            ),
          ),

          // User profile section
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          userRole.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                    },
                    icon: Icon(Icons.logout_rounded, color: textSecondary, size: 18),
                    tooltip: 'Sign Out',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final bool collapsed;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.collapsed,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final bg = isActive
        ? AppTheme.primaryColor.withOpacity(0.15)
        : _hovered
            ? AppTheme.primaryColor.withOpacity(0.07)
            : Colors.transparent;
    final iconColor =
        isActive ? AppTheme.primaryColor : widget.textSecondary;
    final textColor =
        isActive ? AppTheme.primaryColor : widget.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Tooltip(
          message: widget.collapsed ? widget.item.label : '',
          preferBelow: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: ListTile(
              dense: true,
              contentPadding: widget.collapsed
                  ? const EdgeInsets.symmetric(horizontal: 10)
                  : const EdgeInsets.symmetric(horizontal: 12),
              leading: Icon(widget.item.icon, color: iconColor, size: 20),
              title: widget.collapsed
                  ? null
                  : Text(
                      widget.item.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
              onTap: () => context.go(widget.item.route),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
