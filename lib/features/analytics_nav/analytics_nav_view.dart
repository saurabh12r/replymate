import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/activity/activity_log.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/analytics/activity_analytics_service.dart';
import '../../core/analytics/analytics_filter.dart';
import 'analytics_nav_controller.dart';

/// Analytics — Hive-backed, real-time metrics with Daily / Weekly / Monthly filters.
class AnalyticsNavView extends GetView<AnalyticsNavController> {
  const AnalyticsNavView({super.key});

  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ActivityLog>>(
      valueListenable: ActivityLogService.instance.box.listenable(),
      builder: (context, box, _) {
        final logs = box.values.toList();
        return Obx(() {
          final snap = ActivityAnalyticsService.compute(
            logs,
            controller.selectedFilter.value,
          );
          final insights = ActivityLogInsights.compute(logs);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, logs),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildInsightsRow(insights),
                    const SizedBox(height: 12),
                    _buildTopContactCard(insights),
                    const SizedBox(height: 20),
                    if (!snap.hasLogsInPeriod) ...[
                      _buildNoActivityCard(),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildKpiRow(snap),
                      const SizedBox(height: 20),
                      _buildChartCard(snap),
                      const SizedBox(height: 20),
                      _buildTopChannels(snap),
                      const SizedBox(height: 20),
                      _buildStatGrid(snap),
                      const SizedBox(height: 24),
                    ],
                  ]),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildHeader(BuildContext context, List<ActivityLog> logs) {
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Call & auto-reply insights from your activity log',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withAlpha(190),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsRow(ActivityLogInsights i) {
    return Row(
      children: [
        Expanded(
          child: _InsightChip(
            label: 'All-time replies',
            value: '${i.totalRepliesSentAllTime}',
            icon: Icons.send_rounded,
            color: _primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InsightChip(
            label: 'Today',
            value: '${i.repliesToday}',
            icon: Icons.today_rounded,
            color: _secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _InsightChip(
            label: '7 days',
            value: '${i.repliesLast7Days}',
            icon: Icons.date_range_rounded,
            color: const Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildTopContactCard(ActivityLogInsights i) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primary.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_pin_rounded, color: _primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most contacted number',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  i.mostContactedNumber,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${i.mostContactedReplyCount} replies',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Obx(() {
      final selected = controller.selectedFilter.value;
      return Row(
        children: [
          for (var i = 0; i < AnalyticsNavController.filters.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    controller.setFilter(AnalyticsNavController.filters[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right:
                        i < AnalyticsNavController.filters.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == AnalyticsNavController.filters[i]
                        ? _primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected == AnalyticsNavController.filters[i]
                          ? _primary
                          : _outlineVariant,
                      width: 1.2,
                    ),
                    boxShadow: selected == AnalyticsNavController.filters[i]
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
                    AnalyticsNavController.filters[i].label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected == AnalyticsNavController.filters[i]
                          ? Colors.white
                          : _onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildNoActivityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 56, color: _outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No activity',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nothing logged for this period yet.\nTry Weekly or Monthly, or check back after calls.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(ActivityAnalyticsSnapshot snap) {
    final sent = snap.replySentCount;
    final sentLabel =
        sent >= 1000 ? '${(sent / 1000).toStringAsFixed(1)}k' : '$sent';
    final effLabel = snap.hasEfficiencyDenominator
        ? '${snap.efficiencyPercent.round()}%'
        : '—';
    return Row(
      children: [
        _KpiCard(
          value: sentLabel,
          label: 'Total Sent',
          icon: Icons.send_rounded,
          color: _primary,
        ),
        const SizedBox(width: 10),
        _KpiCard(
          value: effLabel,
          label: 'Efficiency',
          icon: Icons.verified_rounded,
          color: _secondary,
        ),
        const SizedBox(width: 10),
        _KpiCard(
          value: '$sent/$kAnalyticsResponseGoalTarget',
          label: 'Response Goal',
          icon: Icons.track_changes_rounded,
          color: const Color(0xFFE65100),
        ),
      ],
    );
  }

  Widget _buildChartCard(ActivityAnalyticsSnapshot snap) {
    final maxCount = snap.barBuckets
        .map((b) => b.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final hasReplies = snap.replySentCount > 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(controller.selectedFilter.value),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Replies Over Time',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _primary.withAlpha(180),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Replies (local time)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (!hasReplies) ...[
              const SizedBox(height: 12),
              Text(
                'No replies in this period — chart shows zeroed slots.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _RepliesBarChart(
                buckets: snap.barBuckets,
                barColor: _primary,
                maxY: maxCount > 0 ? maxCount.toDouble() : 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopChannels(ActivityAnalyticsSnapshot snap) {
    final rows = <_ChannelData>[
      _ChannelData('Live Chat', 0, 'chat', '—'),
      _ChannelData('Email Automation', 0, 'email', '—'),
      _ChannelData(
        'WhatsApp',
        snap.whatsappChannelEvents,
        'whatsapp',
        '${snap.whatsappChannelEvents} calls',
      ),
      _ChannelData(
        'SMS Direct',
        snap.smsDirectReplies,
        'sms',
        '${snap.smsDirectReplies} replies',
      ),
    ];
    final maxCount = rows.map((r) => r.count).reduce((a, b) => a > b ? a : b);
    final denom = maxCount > 0 ? maxCount : 1;

    const colors = [_primary, _secondary, Color(0xFF25D366), Color(0xFFE65100)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Channels',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < rows.length; i++) ...[
            _ChannelRow(
              name: rows[i].name,
              trailing: rows[i].trailing,
              fraction: rows[i].count / denom,
              color: colors[i % colors.length],
              icon: _channelIcon(rows[i].iconKey),
            ),
            if (i < rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  IconData _channelIcon(String key) {
    switch (key) {
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'whatsapp':
        return Icons.forum_rounded;
      default:
        return Icons.sms_rounded;
    }
  }

  Widget _buildStatGrid(ActivityAnalyticsSnapshot snap) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _MiniStatCard(
          icon: Icons.call_rounded,
          label: 'Total Calls',
          value: '${snap.totalCalls}',
          color: _primary,
        ),
        _MiniStatCard(
          icon: Icons.phone_missed_rounded,
          label: 'Missed Calls',
          value: '${snap.missedCalls}',
          color: _error,
        ),
        _MiniStatCard(
          icon: Icons.forum_rounded,
          label: 'WhatsApp Calls',
          value: '${snap.whatsappCalls}',
          color: const Color(0xFF25D366),
        ),
        _MiniStatCard(
          icon: Icons.send_rounded,
          label: 'Replies Sent',
          value: '${snap.repliesSent}',
          color: _secondary,
        ),
      ],
    );
  }

  // ignore: unused_element — export UI hidden for now; logic remains in controller
  Widget _buildExportCta(BuildContext context, List<ActivityLog> allLogs) {
    return Obx(() {
      final busy = controller.isExporting.value;
      return GestureDetector(
        onTap: busy
            ? null
            : () => controller.exportFilteredLogs(context, allLogs),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _primaryContainer],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _primary.withAlpha(60),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(31),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Data',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Download or share analytics',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.ios_share_rounded,
                size: 20,
                color: Colors.white.withAlpha(220),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ChannelData {
  const _ChannelData(this.name, this.count, this.iconKey, this.trailing);
  final String name;
  final int count;
  final String iconKey;
  final String trailing;
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC5C5D4).withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _onSurface,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: _onSurfaceVariant,
              height: 1.1,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element — header export hidden for now
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
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _onSurface,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: _onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepliesBarChart extends StatelessWidget {
  const _RepliesBarChart({
    required this.buckets,
    required this.barColor,
    required this.maxY,
  });

  final List<AnalyticsTimeBucket> buckets;
  final Color barColor;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => barColor.withAlpha(220),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final i = group.x.toInt();
              if (i < 0 || i >= buckets.length) return null;
              return BarTooltipItem(
                '${buckets[i].label}\n${buckets[i].count}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY <= 5 ? 1 : (maxY / 4).ceilToDouble(),
              getTitlesWidget: (v, meta) => Text(
                v == v.roundToDouble() ? '${v.toInt()}' : '',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: _AnalyticsColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= buckets.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[i].label,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      color: _AnalyticsColors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY <= 5 ? 1 : (maxY / 4).ceilToDouble(),
          getDrawingHorizontalLine: (v) => FlLine(
            color: const Color(0xFFC5C5D4).withAlpha(60),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          buckets.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: buckets[i].count.toDouble(),
                width: 18,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                color: barColor,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: barColor.withAlpha(18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsColors {
  static const onSurfaceVariant = Color(0xFF454652);
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.name,
    required this.trailing,
    required this.fraction,
    required this.color,
    required this.icon,
  });

  final String name;
  final String trailing;
  final double fraction;
  final Color color;
  final IconData icon;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  Text(
                    trailing,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: _outlineVariant.withAlpha(80),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _onSurface,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: _onSurfaceVariant,
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
