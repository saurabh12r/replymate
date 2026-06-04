import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/activity/activity_log.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/activity/today_stats.dart';
import '../../core/notifications/push_notification_service.dart';
import '../dashboard/dashboard_controller.dart';
import 'dashboard_nav_controller.dart';

/// Dashboard Home Tab (content only — no bottom nav)
/// Used inside DashboardNavView as tab 0.
/// Stitch Screen ID: c9f778dbd8df4d52b55759e3997f2300
class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  DashboardController get controller => Get.find<DashboardController>();

  static const Color _primary = Color(0xFF24389C);
  static const Color _success = Color(0xFF2E7D32);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ActivityLogService.instance.cleanOldLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildAutoReplyCard(context),
              const SizedBox(height: 20),
              _buildSectionLabel(context, 'Today\'s Activity'),
              const SizedBox(height: 12),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2980), _primary, _primaryContainer],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ReplyMate',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder(
                valueListenable: PushNotificationService.instance.box.listenable(),
                builder: (context, box, child) {
                  final unreadCount = PushNotificationService.instance.unreadCount;
                  return Stack(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Get.toNamed('/notifications');
                          },
                          child: const Icon(
                            Icons.notifications_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${controller.userName.value} 👋',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.autoReplyEnabled.value
                      ? 'Your auto-reply is active and running'
                      : 'Auto-reply is currently paused',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoReplyCard(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: controller.autoReplyEnabled.value
                          ? theme.colorScheme.primary.withAlpha(20)
                          : theme.colorScheme.outlineVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 22,
                      color: controller.autoReplyEnabled.value
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto Reply',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: controller.autoReplyEnabled.value
                                    ? const Color(0xFF2E7D32)
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                            Text(
                              'Status: ${controller.status.value}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: controller.autoReplyEnabled.value
                                    ? const Color(0xFF2E7D32)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.autoReplyEnabled.value,
                    onChanged: (_) => controller.toggleAutoReply(),
                    activeThumbColor: Colors.white,
                    activeTrackColor: _success,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: theme.colorScheme.outlineVariant,
                  ),
                ],
              ),
            ),
            if (controller.autoReplyEnabled.value)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _secondary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _secondary.withAlpha(120),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.eventChannelListening.value
                                ? 'Listening for events…'
                                : 'Connect app to see live events',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _secondary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Obx(() {
                      final line = controller.lastEngineEventLine.value;
                      if (line.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6, left: 18),
                        child: Text(
                          line,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(100),
                  width: 1,
                ),
              ),
              child: Obx(() {
                final name = controller.activeBusinessName.value.trim();
                final display = name.isEmpty ? 'No business yet' : name;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Active Business',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 22),
                      child: Text(
                        'Default SMS SIM business, or your first active business.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        display,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: name.isEmpty
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ValueListenableBuilder<Box<ActivityLog>>(
                valueListenable: ActivityLogService.instance.box.listenable(),
                builder: (context, box, _) {
                  final stats = calculateTodayStats(box.values.toList());
                  return Row(
                    children: [
                      _StatChip(
                        value: '${stats.sent}',
                        label: 'Sent Today',
                        color: _secondary,
                        icon: Icons.check_circle_rounded,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        value: '${stats.failed}',
                        label: 'Failed',
                        color: _error,
                        icon: Icons.cancel_rounded,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return ValueListenableBuilder<Box<ActivityLog>>(
      valueListenable: ActivityLogService.instance.box.listenable(),
      builder: (context, box, _) {
        final stats = calculateTodayStats(box.values.toList());
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _StatCard(
              icon: Icons.call_rounded,
              label: 'Total Calls',
              value: '${stats.totalCalls}',
              color: _primary,
            ),
            _StatCard(
              icon: Icons.phone_missed_rounded,
              label: 'Missed Calls',
              value: '${stats.missedCalls}',
              color: _error,
            ),
            _StatCard(
              icon: Icons.forum_rounded,
              label: 'WhatsApp Calls',
              value: '${stats.whatsappCalls}',
              color: const Color(0xFF25D366),
            ),
            _StatCard(
              icon: Icons.send_rounded,
              label: 'Replies Sent',
              value: '${stats.repliesSent}',
              color: _secondary,
            ),
          ],
        );
      },
    );
  }

  // Kept for future use; the "Quick Actions" section is currently hidden.
  // ignore: unused_element
  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      (Icons.edit_rounded, 'Edit Template', _primary),
      (Icons.history_rounded, 'View Logs', _secondary),
      (Icons.tune_rounded, 'Settings', theme.colorScheme.onSurfaceVariant),
    ];
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: EdgeInsets.only(right: i < actions.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actions[i].$1, size: 22, color: actions[i].$3),
                    const SizedBox(height: 6),
                    Text(
                      actions[i].$2,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
