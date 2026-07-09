import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';

const double _mobileBreakpoint = 600;

final isMobileProvider = Provider<bool>((ref) {
  return false;
});

class ResponsiveShell extends ConsumerWidget {
  final Widget child;
  final List<_NavItem> adminItems;
  final List<_NavItem> brokerItems;
  final bool isAdmin;

  const ResponsiveShell({
    super.key,
    required this.child,
    required this.adminItems,
    required this.brokerItems,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;
    final items = isAdmin ? adminItems : brokerItems;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _getSelectedIndex(items, location);

    if (isMobile) {
      return Scaffold(
        backgroundColor: bg,
        body: child,
        bottomNavigationBar: _MobileBottomNav(
          items: items,
          currentIndex: currentIndex,
          isDark: isDark,
        ),
      );
    }

    return _DesktopShell(
      child: child,
      items: items,
      isAdmin: isAdmin,
      isDark: isDark,
    );
  }

  int _getSelectedIndex(List<_NavItem> items, String location) {
    for (int i = 0; i < items.length; i++) {
      if (location == items[i].route) return i;
      final route = items[i].route;
      if (route != '/admin' && route != '/broker' && location.startsWith(route)) {
        return i;
      }
    }
    return 0;
  }
}

class _DesktopShell extends ConsumerWidget {
  final Widget child;
  final List<_NavItem> items;
  final bool isAdmin;
  final bool isDark;

  const _DesktopShell({
    required this.child,
    required this.items,
    required this.isAdmin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final userName = currentUser?.name ?? 'User';
    final userRole = isAdmin ? 'admin' : 'broker';
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          _DesktopSidebar(
            items: items,
            userName: userName,
            userRole: userRole,
            isDark: isDark,
            location: location,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopTopBar(isDark: isDark, isAdmin: isAdmin),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final List<_NavItem> items;
  final String userName;
  final String userRole;
  final bool isDark;
  final String location;
  final Color textPrimary;
  final Color textSecondary;

  const _DesktopSidebar({
    required this.items,
    required this.userName,
    required this.userRole,
    required this.isDark,
    required this.location,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: border)),
      ),
      child: Column(
        children: [
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
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: items.map((item) {
                final isActive = location == item.route ||
                    (item.route != '/admin' &&
                        item.route != '/broker' &&
                        location.startsWith(item.route));
                return _SidebarTile(
                  item: item,
                  isActive: isActive,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                );
              }).toList(),
            ),
          ),
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
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userRole.toUpperCase(),
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends ConsumerWidget {
  final bool isDark;
  final bool isAdmin;

  const _DesktopTopBar({required this.isDark, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final isDarkMode = ref.watch(themeModeProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).state = !isDarkMode,
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: textSecondary,
              size: 20,
            ),
            tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.go(isAdmin ? '/admin/notifications' : '/broker/notifications'),
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppTheme.errorColor,
              child: Icon(Icons.notifications_outlined, color: textSecondary, size: 20),
            ),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final bool isDark;

  const _MobileBottomNav({
    required this.items,
    required this.currentIndex,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final selectedColor = AppTheme.primaryColor;
    final unselectedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.route),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected ? selectedColor : unselectedColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? selectedColor : unselectedColor,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

  const _SidebarTile({
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final bg = isActive
        ? AppTheme.primaryColor.withOpacity(0.15)
        : _hovered
            ? AppTheme.primaryColor.withOpacity(0.07)
            : Colors.transparent;
    final iconColor = isActive ? AppTheme.primaryColor : widget.textSecondary;
    final textColor = isActive ? AppTheme.primaryColor : widget.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3)) : null,
          ),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(widget.item.icon, color: iconColor, size: 20),
            title: Text(
              widget.item.label,
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500),
            ),
            onTap: () => context.go(widget.item.route),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  _NavItem(this.label, this.icon, this.route);
}

final adminNavItems = [
  _NavItem('Dashboard', Icons.dashboard_rounded, '/admin'),
  _NavItem('Users', Icons.people_alt_rounded, '/admin/users'),
  _NavItem('Expired Users', Icons.timer_off_rounded, '/admin/expired-users'),
  _NavItem('Approvals', Icons.pending_actions_rounded, '/admin/approvals'),
  _NavItem('Brokers', Icons.handshake_rounded, '/admin/brokers'),
  _NavItem('Plans', Icons.card_membership_rounded, '/admin/plans'),
  _NavItem('Revenue', Icons.bar_chart_rounded, '/admin/revenue'),
  _NavItem('Campaigns', Icons.campaign_rounded, '/admin/campaigns'),
  _NavItem('Notifications', Icons.notifications_rounded, '/admin/notifications'),
  _NavItem('Logs', Icons.history_rounded, '/admin/logs'),
  _NavItem('Settings', Icons.settings_rounded, '/admin/settings'),
];

final brokerNavItems = [
  _NavItem('Dashboard', Icons.dashboard_rounded, '/broker'),
  _NavItem('Users', Icons.group_rounded, '/broker/users'),
  _NavItem('Expired Users', Icons.timer_off_rounded, '/broker/expired-users'),
  _NavItem('Campaigns', Icons.campaign_rounded, '/broker/campaigns'),
  _NavItem('Notifications', Icons.notifications_rounded, '/broker/notifications'),
  _NavItem('Approvals', Icons.task_alt_rounded, '/broker/approvals'),
  _NavItem('Analytics', Icons.analytics_rounded, '/broker/analytics'),
];