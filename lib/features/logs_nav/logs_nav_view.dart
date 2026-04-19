import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';

import '../../core/activity/activity_date_utils.dart';
import '../../core/activity/activity_log.dart';
import '../../core/activity/activity_log_display.dart';
import '../../core/activity/activity_log_filters.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/activity/activity_time_format.dart';
import '../../core/activity/event_type.dart';
import '../../core/activity/filter_type.dart';
import '../../core/activity/log_filter_type.dart';
import 'logs_nav_controller.dart';

/// Activity logs — Hive-backed, real-time list with filters.
class LogsNavView extends GetView<LogsNavController> {
  const LogsNavView({super.key});

  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildDateFilterRow(context),
        _buildTypeFilterRow(context),
        Expanded(child: _buildLogList(context)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final isSearching = controller.showSearch.value;
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2980), _primary, _primaryContainer],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
              isSearching ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Logs',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  ValueListenableBuilder<Box<ActivityLog>>(
                    valueListenable:
                        ActivityLogService.instance.box.listenable(),
                    builder: (_, box, __) => Text(
                      '${box.length} total entries',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _HeaderAction(
                icon: Icons.search_rounded,
                onTap: controller.toggleSearch,
              ),
              const SizedBox(width: 8),
              _HeaderAction(
                icon: Icons.ios_share_rounded,
                onTap: () => controller.exportFilteredLogs(context),
              ),
            ],
          ),
          secondChild: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or number…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withAlpha(160),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: controller.onSearchChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: controller.clearSearch,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDateFilterRow(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: LogFilterType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = LogFilterType.values[i];
          return Obx(() {
            final selected = controller.selectedDateFilter.value == f;
            return GestureDetector(
              onTap: () => controller.setDateFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primaryContainer : theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.outlineVariant,
                    width: 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  _dateFilterLabel(f),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  String _dateFilterLabel(LogFilterType f) {
    switch (f) {
      case LogFilterType.today:
        return 'Today';
      case LogFilterType.week:
        return 'This Week';
      case LogFilterType.all:
        return 'All';
    }
  }

  Widget _buildTypeFilterRow(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: FilterType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = FilterType.values[i];
          return Obx(() {
            final selected = controller.selectedFilter.value == f;
            return GestureDetector(
              onTap: () => controller.setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? theme.colorScheme.primary : theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    width: 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  _typeFilterLabel(f),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  String _typeFilterLabel(FilterType f) {
    switch (f) {
      case FilterType.all:
        return 'All types';
      case FilterType.incoming:
        return 'Incoming';
      case FilterType.missed:
        return 'Missed';
      case FilterType.whatsapp:
        return 'WhatsApp';
      case FilterType.outgoing:
        return 'Outgoing';
    }
  }

  Widget _buildLogList(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<Box<ActivityLog>>(
      valueListenable: ActivityLogService.instance.box.listenable(),
      builder: (context, box, _) {
        return Obx(() {
          final typeFilter = controller.selectedFilter.value;
          final dateFilter = controller.selectedDateFilter.value;
          final query = controller.searchQuery.value;

          final sorted = box.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          final logs = applyActivityLogFilters(
            sortedDesc: sorted,
            dateFilter: dateFilter,
            typeFilter: typeFilter,
            queryNormalized: query,
          );

          if (sorted.isEmpty) {
            return _emptyState(
              context,
              title: 'No activity yet',
              subtitle: 'Call events will appear here when they occur.',
            );
          }

          if (logs.isEmpty) {
            if (dateFilter == LogFilterType.today &&
                !sorted.any((e) => isToday(e.timestamp))) {
              return _emptyState(
                context,
                title: 'No activity today',
                subtitle: 'Nothing logged for the current day yet.',
              );
            }
            if (dateFilter == LogFilterType.week &&
                !sorted.any((e) => isWithin7Days(e.timestamp))) {
              return _emptyState(
                context,
                title: 'No activity this week',
                subtitle: 'Nothing in the last 7 days.',
              );
            }
            return _emptyState(
              context,
              title: 'No matching activity',
              subtitle: 'Try a different filter or search.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withAlpha(40),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: theme.colorScheme.error),
                  ),
                  onDismissed: (_) =>
                      ActivityLogService.instance.deleteLog(log.id),
                  child: ActivityLogCard(
                    log: log,
                    onLongPress: () => _showDetailSheet(context, log),
                  ),
                ),
              );
            },
          );
        });
      },
    );
  }

  Widget _emptyState(BuildContext context, {required String title, required String subtitle}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dim slightly in dark mode so the animation doesn't feel too bright;
            // no colour filtering — that would paint it as a flat solid block.
            Opacity(
              opacity: isDark ? 0.75 : 1.0,
              child: Lottie.asset(
                'assets/Empty State.lottie',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
                repeat: true,
                frameRate: FrameRate.max,
                errorBuilder: (ctx, err, st) => Icon(
                  Icons.history_rounded,
                  size: 64,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, ActivityLog log) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity detail',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(context, 'Name', activityLogDisplayName(log)),
            _detailRow(context, 'Number', activityLogDisplayPhone(log)),
            _detailRow(context, 'Type', activityLogTypeLabel(log.type)),
            _detailRow(context, 'Time', log.timestamp.toLocal().toString()),
            _detailRow(context, 'Auto-reply', log.replied ? 'Replied' : 'No Reply'),
            _detailRow(context, 'Id', log.id),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(31),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(40), width: 1),
        ),
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }
}

/// One row in the activity list (rounded card, avatar, type icon, status chip).
class ActivityLogCard extends StatelessWidget {
  const ActivityLogCard({
    super.key,
    required this.log,
    this.onLongPress,
  });

  final ActivityLog log;
  final VoidCallback? onLongPress;

  static const Color _secondary = Color(0xFF006A6A);

  Color _typeColor(ThemeData theme) {
    switch (log.type) {
      case EventType.incomingCall:
        return theme.colorScheme.primary;
      case EventType.missedCall:
        return theme.colorScheme.error;
      case EventType.whatsappCall:
        return const Color(0xFF25D366);
      case EventType.busyCall:
        return const Color(0xFFE65100);
      case EventType.rejectedCall:
        return const Color(0xFFD32F2F);
      case EventType.outgoingAnswered:
        return const Color(0xFF1565C0);
      case EventType.outgoingUnanswered:
        return const Color(0xFF6A1B9A);
    }
  }

  IconData get _typeIcon {
    switch (log.type) {
      case EventType.incomingCall:
        return Icons.call_received_rounded;
      case EventType.missedCall:
        return Icons.call_missed_rounded;
      case EventType.whatsappCall:
        return Icons.chat_rounded;
      case EventType.busyCall:
        return Icons.phone_in_talk_rounded;
      case EventType.rejectedCall:
        return Icons.phone_disabled_rounded;
      case EventType.outgoingAnswered:
        return Icons.call_made_rounded;
      case EventType.outgoingUnanswered:
        return Icons.phone_missed_rounded;
    }
  }

  String get _initials {
    final displayName = activityLogDisplayName(log);
    if (displayName == 'Private Number') {
      final digits = log.phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 2) {
        return digits.substring(digits.length - 2).toUpperCase();
      }
      return '?';
    }
    final parts =
        displayName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = _typeColor(theme);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: typeColor.withAlpha(28),
                child: Text(
                  _initials,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: typeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityLogDisplayName(log),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activityLogDisplayPhone(log),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(_typeIcon, size: 14, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          _typeLineLabel(log.type),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (log.messageSent.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        log.messageSent,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTimeAgo(log.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.replied
                          ? _secondary.withAlpha(22)
                          : theme.colorScheme.outlineVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      log.replied ? 'Replied' : 'No Reply',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: log.replied ? _secondary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLineLabel(EventType type) {
    switch (type) {
      case EventType.incomingCall:
        return 'Incoming';
      case EventType.missedCall:
        return 'Missed';
      case EventType.whatsappCall:
        return 'WhatsApp';
      case EventType.busyCall:
        return 'Busy';
      case EventType.rejectedCall:
        return 'Rejected';
      case EventType.outgoingAnswered:
        return 'Outgoing (Answered)';
      case EventType.outgoingUnanswered:
        return 'Outgoing (No Answer)';
    }
  }
}
