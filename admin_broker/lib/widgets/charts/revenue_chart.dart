import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';

/// Monthly revenue bar chart
class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const RevenueChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    if (data.isEmpty) {
      return const Center(
        child: Text('No revenue data yet', style: TextStyle(color: AppTheme.darkTextSecondary)),
      );
    }

    final maxY = data.map((d) => (d['revenue'] as double)).reduce((a, b) => a > b ? a : b);
    final spots = data.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: (e.value['revenue'] as double),
            gradient: AppTheme.primaryGradient,
            width: 28,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppTheme.darkCard : AppTheme.lightCard,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                AppUtils.formatCurrency(rod.toY),
                TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= data.length) return const Text('');
                final month = data[index]['month'] as String;
                final parts = month.split('-');
                final months = [
                  '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                final m = int.tryParse(parts.last) ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    months[m],
                    style: TextStyle(color: textSecondary, fontSize: 11),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${AppUtils.formatCompact(value)}',
                  style: TextStyle(color: textSecondary, fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: spots,
      ),
    );
  }
}

/// Donut chart for user status breakdown
class UserStatusDonut extends StatelessWidget {
  final int active;
  final int pending;
  final int expired;
  final int suspended;

  const UserStatusDonut({
    super.key,
    required this.active,
    required this.pending,
    required this.expired,
    required this.suspended,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    final total = active + pending + expired + suspended;
    if (total == 0) {
      return const Center(child: Text('No user data'));
    }

    final sections = [
      if (active > 0)
        PieChartSectionData(
          value: active.toDouble(),
          color: AppTheme.successColor,
          title: '$active',
          radius: 60,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      if (pending > 0)
        PieChartSectionData(
          value: pending.toDouble(),
          color: AppTheme.warningColor,
          title: '$pending',
          radius: 60,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      if (expired > 0)
        PieChartSectionData(
          value: expired.toDouble(),
          color: AppTheme.errorColor,
          title: '$expired',
          radius: 60,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      if (suspended > 0)
        PieChartSectionData(
          value: suspended.toDouble(),
          color: AppTheme.darkTextSecondary,
          title: '$suspended',
          radius: 60,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 48,
              sectionsSpace: 3,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Legend(color: AppTheme.successColor, label: 'Active', count: active),
            const SizedBox(height: 10),
            _Legend(color: AppTheme.warningColor, label: 'Pending', count: pending),
            const SizedBox(height: 10),
            _Legend(color: AppTheme.errorColor, label: 'Expired', count: expired),
            const SizedBox(height: 10),
            _Legend(color: AppTheme.darkTextSecondary, label: 'Suspended', count: suspended),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
