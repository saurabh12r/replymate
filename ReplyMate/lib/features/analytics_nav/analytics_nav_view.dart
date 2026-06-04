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

class AnalyticsNavView extends GetView<AnalyticsNavController> {
  const AnalyticsNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          return Scaffold(
            backgroundColor: cs.surface,
            body: CustomScrollView(
              slivers: [
                _SliverHeroHeader(
                  logs: logs,
                  controller: controller,
                  insights: insights,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PeriodChips(controller: controller),
                      const SizedBox(height: 24),
                      if (!snap.hasLogsInPeriod) ...[
                        _EmptyState(),
                      ] else ...[
                        _SectionLabel('Performance'),
                        const SizedBox(height: 12),
                        _KpiRow(snap: snap),
                        const SizedBox(height: 24),
                        _SectionLabel('Replies Over Time'),
                        const SizedBox(height: 12),
                        _ChartCard(snap: snap),
                        const SizedBox(height: 24),
                        _SectionLabel('Call Breakdown'),
                        const SizedBox(height: 12),
                        _BreakdownGrid(snap: snap),
                        const SizedBox(height: 24),
                        _SectionLabel('Channels'),
                        const SizedBox(height: 12),
                        _ChannelsCard(snap: snap),
                        const SizedBox(height: 32),
                        _DownloadCard(controller: controller, logs: logs),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

// ─── Sliver hero header ───────────────────────────────────────────────────────
class _SliverHeroHeader extends StatelessWidget {
  const _SliverHeroHeader({
    required this.logs,
    required this.controller,
    required this.insights,
  });
  final List<ActivityLog> logs;
  final AnalyticsNavController controller;
  final ActivityLogInsights insights;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F2460),
              cs.primary,
              const Color(0xFF5C6BC0),
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: GoogleFonts.manrope(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Call & reply activity insights',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                      () => _IconBtn(
                        icon: Icons.sync_rounded,
                        loading: controller.isExporting.value,
                        onTap: controller.syncLogs,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _HeroStat(
                      label: 'All-time',
                      value: '${insights.totalRepliesSentAllTime}',
                      icon: Icons.send_rounded,
                    ),
                    const SizedBox(width: 12),
                    _HeroStat(
                      label: 'Today',
                      value: '${insights.repliesToday}',
                      icon: Icons.today_rounded,
                    ),
                    const SizedBox(width: 12),
                    _HeroStat(
                      label: 'This week',
                      value: '${insights.repliesLast7Days}',
                      icon: Icons.date_range_rounded,
                    ),
                  ],
                ),
                if (insights.mostContactedNumber != '—') ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_pin_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Top contact: ${insights.mostContactedNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${insights.mostContactedReplyCount} replies',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// ─── Period chips ─────────────────────────────────────────────────────────────
class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.controller});
  final AnalyticsNavController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Obx(() {
      final sel = controller.selectedFilter.value;
      return Row(
        children: AnalyticsNavController.filters.map((f) {
          final active = sel == f;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setFilter(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: f != AnalyticsNavController.filters.last ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: cs.primary.withAlpha(50),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  f.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, size: 36, color: cs.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No data yet',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No activity found for this period.\nMake or receive calls to start tracking.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI row ──────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.snap});
  final ActivityAnalyticsSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sent = snap.replySentCount;
    final eff = snap.hasEfficiencyDenominator
        ? '${snap.efficiencyPercent.round()}%'
        : '—';

    return Row(
      children: [
        _KpiCard(
          value: '$sent',
          label: 'Replies Sent',
          color: cs.primary,
          icon: Icons.send_rounded,
        ),
        const SizedBox(width: 12),
        _KpiCard(
          value: eff,
          label: 'Success Rate',
          color: const Color(0xFF00897B),
          icon: Icons.verified_rounded,
        ),
        const SizedBox(width: 12),
        _KpiCard(
          value: '$sent/$kAnalyticsResponseGoalTarget',
          label: 'Goal Progress',
          color: const Color(0xFFE65100),
          icon: Icons.track_changes_rounded,
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
  final String value, label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(30)),
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
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chart card ──────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.snap});
  final ActivityAnalyticsSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = snap.barBuckets
        .map((b) => b.count)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily Distribution',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'by time of day',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY > 0 ? maxY + 1 : 4,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => cs.primary.withAlpha(230),
                    getTooltipItem: (g, gi, rod, ri) {
                      final i = g.x.toInt();
                      if (i < 0 || i >= snap.barBuckets.length) return null;
                      return BarTooltipItem(
                        '${snap.barBuckets[i].label}\n${snap.barBuckets[i].count}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                      getTitlesWidget: (v, _) => Text(
                        v == v.roundToDouble() ? '${v.toInt()}' : '',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= snap.barBuckets.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            snap.barBuckets[i].label,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: cs.onSurfaceVariant,
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
                  horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outlineVariant.withAlpha(80),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  snap.barBuckets.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: snap.barBuckets[i].count.toDouble(),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [cs.primary.withAlpha(160), cs.primary],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY > 0 ? maxY + 1 : 4,
                          color: cs.primary.withAlpha(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Breakdown grid ───────────────────────────────────────────────────────────
class _BreakdownGrid extends StatelessWidget {
  const _BreakdownGrid({required this.snap});
  final ActivityAnalyticsSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      _StatItem(
        'Total Calls',
        '${snap.totalCalls}',
        Icons.call_rounded,
        cs.primary,
      ),
      _StatItem(
        'Missed',
        '${snap.missedCalls}',
        Icons.phone_missed_rounded,
        cs.error,
      ),
      _StatItem(
        'WhatsApp',
        '${snap.whatsappCalls}',
        Icons.forum_rounded,
        const Color(0xFF25D366),
      ),
      _StatItem(
        'Sent',
        '${snap.repliesSent}',
        Icons.send_rounded,
        const Color(0xFF00897B),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: items.map((e) => _BreakdownTile(item: e)).toList(),
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color);
  final String label, value;
  final IconData icon;
  final Color color;
}

class _BreakdownTile extends StatelessWidget {
  const _BreakdownTile({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.color.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 20, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Channels card ────────────────────────────────────────────────────────────
class _ChannelsCard extends StatelessWidget {
  const _ChannelsCard({required this.snap});
  final ActivityAnalyticsSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = [
      _ChannelRow(
        'SMS Auto-Reply',
        snap.smsDirectReplies,
        Icons.sms_rounded,
        cs.primary,
      ),
      _ChannelRow(
        'WhatsApp Calls',
        snap.whatsappChannelEvents,
        Icons.forum_rounded,
        const Color(0xFF25D366),
      ),
    ];
    final maxVal = rows
        .map((r) => r.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final r = e.value;
          final fraction = maxVal > 0 ? r.count / maxVal : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < rows.length - 1 ? 16 : 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: r.color.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(r.icon, size: 20, color: r.color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.label,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            '${r.count}',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: r.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: fraction.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: cs.outlineVariant.withAlpha(60),
                          valueColor: AlwaysStoppedAnimation<Color>(r.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChannelRow {
  const _ChannelRow(this.label, this.count, this.icon, this.color);
  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

// ─── Download card ────────────────────────────────────────────────────────────
class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.controller, required this.logs});
  final AnalyticsNavController controller;
  final List<ActivityLog> logs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final period = controller.selectedFilter.value.label;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0F2460), cs.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
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
                      'Download Report',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$period period · CSV format',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => GestureDetector(
              onTap: controller.isExporting.value
                  ? null
                  : () => controller.exportFilteredLogs(context, logs),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                    controller.isExporting.value ? 40 : 255,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (controller.isExporting.value) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: cs.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Saving…',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.download_for_offline_rounded,
                        color: cs.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Save to Downloads',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
