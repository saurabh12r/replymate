import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/daily_stats.dart';
import '../../providers/data_providers.dart';
import '../../widgets/common/app_widgets.dart';

// ─── local state providers ────────────────────────────────────────────────────

final _tabProvider = StateProvider<int>((ref) => 0); // 0=Daily 1=Monthly
final _rangeProvider = StateProvider<int>((ref) => 30); // days / months to show

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Statistics',
            subtitle: 'SMS and call performance — by day and month',
            icon: Icons.analytics_rounded,
          ),
          const SizedBox(height: 20),

          // ── Today banner ───────────────────────────────────────────────────
          _TodayBanner(ref: ref),
          const SizedBox(height: 20),

          // ── Tab + range controls ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              _Tab(label: 'Daily', index: 0, current: tab, ref: ref),
              _Tab(label: 'Monthly', index: 1, current: tab, ref: ref),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Range chips ────────────────────────────────────────────────────
          _RangeChips(tab: tab, ref: ref),
          const SizedBox(height: 20),

          // ── Chart ──────────────────────────────────────────────────────────
          if (tab == 0)
            _DailyView(cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary, bg: bg)
          else
            _MonthlyView(cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary, bg: bg),
        ],
      ),
    );
  }
}

// ─── Today banner ─────────────────────────────────────────────────────────────

class _TodayBanner extends ConsumerWidget {
  final WidgetRef ref;
  const _TodayBanner({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final async = ref.watch(dailyStatsProvider);
    return async.when(
      data: (list) {
        // first item in the stream is today (descending)
        final today = list.isNotEmpty ? list.first : null;
        final sent = today?.smsSent ?? 0;
        final failed = today?.smsFailed ?? 0;
        final calls = today?.callsReceived ?? 0;
        final missed = today?.missedCalls ?? 0;
        final total = sent + failed;
        final rate = total > 0 ? (sent / total * 100).toStringAsFixed(0) : '0';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.today_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text("Today's Performance",
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _BannerStat(label: 'SMS Sent', value: '$sent', icon: Icons.send_rounded),
              _BannerStat(label: 'Failed', value: '$failed', icon: Icons.sms_failed_rounded),
              _BannerStat(label: 'Rate', value: '$rate%', icon: Icons.verified_rounded),
              _BannerStat(label: 'Calls', value: '$calls', icon: Icons.call_rounded),
              _BannerStat(label: 'Missed', value: '$missed', icon: Icons.call_missed_rounded),
            ]),
          ]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _BannerStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.manrope(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]),
      ),
    );
  }
}

// ─── Tab widget ───────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int index, current;
  final WidgetRef ref;
  const _Tab({required this.label, required this.index, required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(_tabProvider.notifier).state = index;
          ref.read(_rangeProvider.notifier).state = index == 0 ? 30 : 12;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: active ? AppTheme.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: active ? Colors.white : Colors.grey,
              )),
        ),
      ),
    );
  }
}

// ─── Range chips ──────────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  const _RangeChips({required this.tab, required this.ref});

  @override
  Widget build(BuildContext context) {
    final ranges = tab == 0
        ? [7, 14, 30, 60, 90]
        : [3, 6, 12];
    final current = ref.watch(_rangeProvider);

    return Row(
      children: ranges.map((r) {
        final active = current == r;
        final label = tab == 0 ? '${r}d' : '${r}m';
        return GestureDetector(
          onTap: () => ref.read(_rangeProvider.notifier).state = r,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryColor : Colors.transparent,
              border: Border.all(color: active ? AppTheme.primaryColor : Colors.grey.withAlpha(80)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : Colors.grey,
                )),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Daily view ───────────────────────────────────────────────────────────────

class _DailyView extends ConsumerWidget {
  final Color cardBg, textPrimary, textSecondary, bg;
  const _DailyView({required this.cardBg, required this.textPrimary, required this.textSecondary, required this.bg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(_rangeProvider);
    final async = ref.watch(dailyStatsProvider);

    return async.when(
      data: (days) {
        final filtered = days.take(range).toList();
        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_today_rounded,
            title: 'No Daily Data',
            message: 'SMS and call stats will appear here once activity is recorded.',
          );
        }

        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_today_rounded,
            title: 'No Daily Data',
            message: 'SMS and call stats will appear here once activity is recorded.',
          );
        }

        return Column(children: [
          _DailyBarChart(days: filtered.reversed.toList(), cardBg: cardBg, textSecondary: textSecondary),
          const SizedBox(height: 20),
          _StatsTable(
            header: ['Date', 'Sent', 'Failed', 'Rate', 'Calls', 'Missed'],
            rows: filtered.map((d) {
              final total = d.smsSent + d.smsFailed;
              final rate = total > 0 ? '${(d.smsSent / total * 100).round()}%' : '—';
              final now = DateTime.now();
              return _TableRow(
                cells: [
                  AppUtils.formatDate(d.date),
                  '${d.smsSent}',
                  '${d.smsFailed}',
                  rate,
                  '${d.callsReceived}',
                  '${d.missedCalls}',
                ],
                colors: [null, AppTheme.successColor, d.smsFailed > 0 ? AppTheme.errorColor : null, null, AppTheme.infoColor, d.missedCalls > 0 ? AppTheme.warningColor : null],
                hasBadge: [false, false, false, false, false, false],
                isToday: d.date.year == now.year && d.date.month == now.month && d.date.day == now.day,
              );
            }).toList(),
            cardBg: cardBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ]);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// ─── Monthly view ─────────────────────────────────────────────────────────────

class _MonthlyView extends ConsumerWidget {
  final Color cardBg, textPrimary, textSecondary, bg;
  const _MonthlyView({required this.cardBg, required this.textPrimary, required this.textSecondary, required this.bg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(_rangeProvider);
    final async = ref.watch(monthlyStatsProvider);

    return async.when(
      data: (months) {
        final filtered = months.take(range).toList();
        if (filtered.isEmpty) {
          return const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No Monthly Data',
            message: 'Monthly statistics will appear here.',
          );
        }

        return Column(children: [
          _MonthlyBarChart(months: filtered.reversed.toList(), cardBg: cardBg, textSecondary: textSecondary),
          const SizedBox(height: 20),
          _StatsTable(
            header: ['Month', 'Sent', 'Failed', 'Rate', 'Calls', 'Missed', 'New Users'],
            rows: filtered.map((m) {
              final total = m.smsSent + m.smsFailed;
              final rate = total > 0 ? '${(m.smsSent / total * 100).round()}%' : '—';
              return _TableRow(
                cells: [
                  '${m.monthName} ${m.year}',
                  '${m.smsSent}',
                  '${m.smsFailed}',
                  rate,
                  '${m.callsReceived}',
                  '${m.missedCalls}',
                  '${m.newUsers}',
                ],
                colors: [null, AppTheme.successColor, m.smsFailed > 0 ? AppTheme.errorColor : null, null, AppTheme.infoColor, m.missedCalls > 0 ? AppTheme.warningColor : null, AppTheme.accentColor],
                hasBadge: [false, false, false, false, false, false, false],
                isToday: false,
              );
            }).toList(),
            cardBg: cardBg,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ]);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// ─── Daily stacked bar chart ──────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final List<DailyStats> days;
  final Color cardBg, textSecondary;
  const _DailyBarChart({required this.days, required this.cardBg, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    final visible = days.take(14).toList(); // max 14 bars before it's cramped
    final maxVal = visible.fold<int>(0, (p, d) {
      final t = d.smsSent + d.smsFailed;
      return t > p ? t : p;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _LegendDot(color: AppTheme.successColor, label: 'Sent'),
          const SizedBox(width: 12),
          _LegendDot(color: AppTheme.errorColor, label: 'Failed'),
          const SizedBox(width: 12),
          _LegendDot(color: AppTheme.infoColor, label: 'Calls'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: visible.map((d) {
              final total = d.smsSent + d.smsFailed;
              final barH = maxVal > 0 ? (total / maxVal * 90).clamp(2.0, 90.0) : 2.0;
              final sentH = total > 0 ? barH * d.smsSent / total : 0.0;
              final failH = barH - sentH;
              final label = '${d.date.month}/${d.date.day}';
              return Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (total > 0)
                    Text('$total', style: TextStyle(fontSize: 7, color: textSecondary)),
                  const SizedBox(height: 2),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (failH > 0)
                      Container(width: 14, height: failH,
                          decoration: BoxDecoration(color: AppTheme.errorColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                    if (sentH > 0)
                      Container(width: 14, height: sentH,
                          decoration: BoxDecoration(color: AppTheme.successColor,
                              borderRadius: failH > 0 ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(3)))),
                  ]),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(fontSize: 8, color: textSecondary)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─── Monthly bar chart ────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyStats> months;
  final Color cardBg, textSecondary;
  const _MonthlyBarChart({required this.months, required this.cardBg, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    final maxVal = months.fold<int>(0, (p, m) {
      final t = m.smsSent + m.smsFailed;
      return t > p ? t : p;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _LegendDot(color: AppTheme.successColor, label: 'Sent'),
          const SizedBox(width: 12),
          _LegendDot(color: AppTheme.errorColor, label: 'Failed'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((m) {
              final total = m.smsSent + m.smsFailed;
              final barH = maxVal > 0 ? (total / maxVal * 90).clamp(2.0, 90.0) : 2.0;
              final sentH = total > 0 ? barH * m.smsSent / total : 0.0;
              final failH = barH - sentH;
              return Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (total > 0)
                    Text('$total', style: TextStyle(fontSize: 7, color: textSecondary)),
                  const SizedBox(height: 2),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    if (failH > 0)
                      Container(width: 20, height: failH,
                          decoration: BoxDecoration(color: AppTheme.errorColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)))),
                    if (sentH > 0)
                      Container(width: 20, height: sentH,
                          decoration: BoxDecoration(color: AppTheme.successColor,
                              borderRadius: failH > 0 ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(3)))),
                  ]),
                  const SizedBox(height: 4),
                  Text(m.monthName, style: TextStyle(fontSize: 9, color: textSecondary)),
                ]),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─── Reusable stats table ─────────────────────────────────────────────────────

class _TableRow {
  final List<String> cells;
  final List<Color?> colors;
  final List<bool> hasBadge;
  final bool isToday;
  const _TableRow({required this.cells, required this.colors, required this.hasBadge, this.isToday = false});
}

class _StatsTable extends StatelessWidget {
  final List<String> header;
  final List<_TableRow> rows;
  final Color cardBg, textPrimary, textSecondary;
  const _StatsTable({
    required this.header,
    required this.rows,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: header.asMap().entries.map((e) {
            return Expanded(
              child: Text(e.value,
                  textAlign: e.key == 0 ? TextAlign.left : TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: textSecondary)),
            );
          }).toList()),
        ),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Container(
            decoration: BoxDecoration(
              color: row.isToday
                  ? AppTheme.primaryColor.withAlpha(12)
                  : i.isEven ? Colors.transparent : AppTheme.primaryColor.withAlpha(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: row.cells.asMap().entries.map((e) {
              final idx = e.key;
              final cell = e.value;
              final color = (row.colors.length > idx ? row.colors[idx] : null) ?? textPrimary;
              return Expanded(
                child: Row(
                  mainAxisAlignment: idx == 0 ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    if (row.isToday && idx == 0) ...[
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(cell,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                    ),
                  ],
                ),
              );
            }).toList()),
          );
        }),
        // Totals footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha(15),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: _buildTotals()),
        ),
      ]),
    );
  }

  List<Widget> _buildTotals() {
    if (rows.isEmpty) return [];
    final colCount = header.length;
    final totals = List.filled(colCount, 0);
    for (final row in rows) {
      for (int i = 1; i < colCount && i < row.cells.length; i++) {
        final v = int.tryParse(row.cells[i].replaceAll('%', ''));
        if (v != null) totals[i] += v;
      }
    }
    return header.asMap().entries.map((e) {
      final i = e.key;
      return Expanded(
        child: Text(
          i == 0 ? 'Total (${rows.length})' : (totals[i] > 0 ? '${totals[i]}' : '—'),
          textAlign: i == 0 ? TextAlign.left : TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary),
        ),
      );
    }).toList();
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}