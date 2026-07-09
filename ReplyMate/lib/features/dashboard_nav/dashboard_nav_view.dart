import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_nav_controller.dart';
import 'dashboard_home_tab.dart';
import '../logs_nav/logs_nav_view.dart';
import '../profile/profile_tab.dart';
import '../stores/stores_list_view.dart';

/// Dashboard with Navigation (Shell)
/// Stitch Screen ID: 8838ec89e7394356ae1cdd9b72e02d8b
///
/// Owns the bottom nav + IndexedStack.
/// Each tab's controller is independently registered via DashboardNavBinding.
class DashboardNavView extends GetView<DashboardNavController> {
  const DashboardNavView({super.key});

  static const _tabs = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.list_alt_rounded, 'Logs'),
    (Icons.storefront_rounded, 'Businesses'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: controller.selectedIndex.value == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          controller.selectedIndex.value = 0;
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: IndexedStack(
              index: controller.selectedIndex.value,
              children: const [
                DashboardHomeTab(),
                LogsNavView(),
                StoresListView(showBack: false),
                ProfileTab(),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withAlpha(50),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = controller.selectedIndex.value == i;
                return _NavItem(
                  icon: tab.$1,
                  label: tab.$2,
                  selected: selected,
                  onTap: () => controller.onNavTap(i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primary.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 22,
                color: selected ? primary : onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? primary : onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
