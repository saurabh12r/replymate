import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildDateFilterRow(),
        _buildTypeFilterRow(),
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

  Widget _buildDateFilterRow() {
    return Container(
      height: 48,
      color: _surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? _primaryContainer : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _primaryContainer : _outlineVariant,
                    width: 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _primary.withAlpha(35),
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
                    color: selected ? Colors.white : _onSurfaceVariant,
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

  Widget _buildTypeFilterRow() {
    return Container(
      height: 48,
      color: _surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _primary : _outlineVariant,
                    width: 1.2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _primary.withAlpha(40),
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
                    color: selected ? Colors.white : _onSurfaceVariant,
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
    }
  }

  Widget _buildLogList(BuildContext context) {
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
              title: 'No activity yet',
              subtitle: 'Call events will appear here when they occur.',
            );
          }

          if (logs.isEmpty) {
            if (dateFilter == LogFilterType.today &&
                !sorted.any((e) => isToday(e.timestamp))) {
              return _emptyState(
                title: 'No activity today',
                subtitle: 'Nothing logged for the current day yet.',
              );
            }
            if (dateFilter == LogFilterType.week &&
                !sorted.any((e) => isWithin7Days(e.timestamp))) {
              return _emptyState(
                title: 'No activity this week',
                subtitle: 'Nothing in the last 7 days.',
              );
            }
            return _emptyState(
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
                      color: _error.withAlpha(40),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: _error),
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

  Widget _emptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: _outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 13, color: _onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, ActivityLog log) {
    showModalBottomSheet<void>(
      context: context,
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
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow('Name', activityLogDisplayName(log)),
            _detailRow('Number', activityLogDisplayPhone(log)),
            _detailRow('Type', activityLogTypeLabel(log.type)),
            _detailRow('Time', log.timestamp.toLocal().toString()),
            _detailRow('Auto-reply', log.replied ? 'Replied' : 'No Reply'),
            _detailRow('Id', log.id),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String k, String v) {
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
                color: _onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: GoogleFonts.inter(fontSize: 13, color: _onSurface),
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

  static const Color _primary = Color(0xFF24389C);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);

  Color get _typeColor {
    switch (log.type) {
      case EventType.incomingCall:
        return _primary;
      case EventType.missedCall:
        return _error;
      case EventType.whatsappCall:
        return const Color(0xFF25D366);
      case EventType.busyCall:
        return const Color(0xFFE65100);
      case EventType.outgoingCall:
        return const Color(0xFF1565C0);
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
      case EventType.outgoingCall:
        return Icons.call_made_rounded;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                backgroundColor: _typeColor.withAlpha(28),
                child: Text(
                  _initials,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _typeColor,
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
                        color: _onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activityLogDisplayPhone(log),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(_typeIcon, size: 14, color: _typeColor),
                        const SizedBox(width: 4),
                        Text(
                          _typeLineLabel(log.type),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _typeColor,
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
                          color: _onSurfaceVariant,
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
                      color: _onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.replied
                          ? _secondary.withAlpha(22)
                          : _outlineVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      log.replied ? 'Replied' : 'No Reply',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: log.replied ? _secondary : _onSurfaceVariant,
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
      case EventType.outgoingCall:
        return 'Outgoing';
    }
  }
}
