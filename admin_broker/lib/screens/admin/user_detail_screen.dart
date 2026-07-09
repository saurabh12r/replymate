import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/replymet_user.dart';
import '../../models/subscription_history_model.dart';
import '../../providers/data_providers.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_widgets.dart';

class UserDetailScreen extends ConsumerWidget {
  final String odlId;
  const UserDetailScreen({super.key, required this.odlId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider(odlId));
    final statsAsync = ref.watch(userStatsSummaryProvider(odlId));
    final dailyAsync = ref.watch(userDailyStatsProvider(odlId));
    final monthlyAsync = ref.watch(userMonthlyStatsProvider(odlId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('User Not Found')),
            body: const Center(child: Text('User not found')),
          );
        }
        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Text('User Details',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile header ───────────────────────────────────────────
                _ProfileCard(user: user, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary),
                const SizedBox(height: 16),

                // ── Subscription + all-time SMS ──────────────────────────────
                statsAsync.when(
                  data: (s) => _SubscriptionSection(stats: s, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary),
                  loading: () => const _SectionShimmer(),
                  error: (e, _) => _ErrorTile('$e'),
                ),
                const SizedBox(height: 16),

                // ── Subscription History ─────────────────────────────────────
                _SubscriptionHistorySection(
                  userId: odlId,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),

                // ── Daily activity (with date picker) ────────────────────────
                _DailyStatsSection(
                  userId: odlId,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),

                // ── Last 7 days bar chart ────────────────────────────────────
                dailyAsync.when(
                  data: (d) => _DailyBarChart(daily: d, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary),
                  loading: () => const _SectionShimmer(height: 160),
                  error: (e, _) => _ErrorTile('$e'),
                ),
                const SizedBox(height: 16),

                // ── Monthly breakdown ────────────────────────────────────────
                monthlyAsync.when(
                  data: (m) => _MonthlySection(monthly: m, cardBg: cardBg, textPrimary: textPrimary, textSecondary: textSecondary),
                  loading: () => const _SectionShimmer(height: 160),
                  error: (e, _) => _ErrorTile('$e'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends ConsumerWidget {
  final ReplymetUser user;
  final Color cardBg, textPrimary, textSecondary;
  const _ProfileCard({required this.user, required this.cardBg, required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(user.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.primaryColor.withAlpha(30),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardBg, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
                const SizedBox(height: 2),
                Text(user.phone, style: GoogleFonts.inter(fontSize: 13, color: textSecondary)),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: textSecondary)),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.status.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                    if (user.brokerId != null && user.brokerId!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BROKER: ${user.brokerId}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'Move to Admin',
                            content: 'Are you sure you want to move "${user.name}" to direct Admin management? They will no longer be associated with this broker.',
                            confirmText: 'Move to Admin',
                            confirmColor: AppTheme.primaryColor,
                            onConfirm: () async {
                              await ref.read(firestoreServiceProvider).moveUserToAdmin(user.uid);
                              if (context.mounted) {
                                showSnack(context, 'User moved to Admin management successfully');
                              }
                            },
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 12),
                        label: const Text('Move to Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.accentColor,
                          side: const BorderSide(color: AppTheme.accentColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NO BROKER (DIRECT)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showAssignBrokerDialog(context, ref, user);
                        },
                        icon: const Icon(Icons.handshake_rounded, size: 12),
                        label: const Text('Assign to Broker', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppTheme.successColor;
      case 'expired': return AppTheme.warningColor;
      case 'suspended': return AppTheme.errorColor;
      default: return AppTheme.infoColor;
    }
  }
}

// ─── Subscription section ─────────────────────────────────────────────────────

class _SubscriptionSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  final Color cardBg, textPrimary, textSecondary;
  const _SubscriptionSection({required this.stats, required this.cardBg, required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    final sent = stats['smsSent'] as int? ?? 0;
    final failed = stats['smsFailed'] as int? ?? 0;
    final total = sent + failed;
    final rate = total > 0 ? (sent / total * 100).round() : 0;

    return Column(
      children: [
        // SMS all-time row
        Row(children: [
          Expanded(child: _MiniCard(label: 'Total SMS Sent', value: '$sent', icon: Icons.send_rounded, color: AppTheme.successColor, cardBg: cardBg)),
          const SizedBox(width: 12),
          Expanded(child: _MiniCard(label: 'Total Failed', value: '$failed', icon: Icons.sms_failed_rounded, color: AppTheme.errorColor, cardBg: cardBg)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MiniCard(label: 'Success Rate', value: '$rate%', icon: Icons.verified_rounded, color: AppTheme.accentColor, cardBg: cardBg)),
          const SizedBox(width: 12),
          Expanded(child: _MiniCard(label: 'Plan', value: stats['currentPlan'] ?? 'None', icon: Icons.card_membership_rounded, color: AppTheme.primaryColor, cardBg: cardBg)),
        ]),
        const SizedBox(height: 12),
        // Subscription dates
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(
              child: _DateInfo(
                label: 'Started',
                icon: Icons.play_circle_outline_rounded,
                color: AppTheme.successColor,
                timestamp: stats['subscriptionStart'],
              ),
            ),
            Container(width: 1, height: 36, color: textSecondary.withAlpha(40)),
            Expanded(
              child: _DateInfo(
                label: 'Expires',
                icon: Icons.event_rounded,
                color: AppTheme.warningColor,
                timestamp: stats['subscriptionEnd'],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final dynamic timestamp;
  const _DateInfo({required this.label, required this.icon, required this.color, this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(_fmt(timestamp), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ]),
    );
  }

  String _fmt(dynamic ts) {
    if (ts == null) return 'N/A';
    try {
      if (ts is Timestamp) {
        final d = ts.toDate();
        return '${d.day}/${d.month}/${d.year}';
      }
      final str = ts.toString();
      final m = RegExp(r'seconds=(\d+)').firstMatch(str);
      if (m != null) {
        final d = DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(1)!) * 1000);
        return '${d.day}/${d.month}/${d.year}';
      }
    } catch (_) {}
    return 'N/A';
  }
}

// ─── Daily section ────────────────────────────────────────────────────────────

class _DailyStatsSection extends ConsumerStatefulWidget {
  final String userId;
  final Color cardBg, textPrimary, textSecondary;
  const _DailyStatsSection({
    required this.userId,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  ConsumerState<_DailyStatsSection> createState() => _DailyStatsSectionState();
}

class _DailyStatsSectionState extends ConsumerState<_DailyStatsSection> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: AppTheme.darkSurface,
                    onSurface: AppTheme.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: AppTheme.lightSurface,
                    onSurface: AppTheme.lightTextPrimary,
                  ),
            dialogTheme: DialogThemeData(backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          ),
          child: child!,
        );
      },
    );
    if (date != null && date != _selectedDate) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(userStatsForDateProvider((userId: widget.userId, date: _selectedDate)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withAlpha(20), AppTheme.accentColor.withAlpha(10)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Text("Daily Activity",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.textPrimary)),
              ]),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: AppTheme.primaryColor.withAlpha(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            data: (stats) {
              final sent = stats['smsSent'] as int? ?? 0;
              final failed = stats['smsFailed'] as int? ?? 0;
              final calls = stats['callsReceived'] as int? ?? 0;
              final missed = stats['missedCalls'] as int? ?? 0;
              return Row(children: [
                Expanded(child: _TodayStat(label: 'SMS Sent', value: sent, color: AppTheme.successColor, icon: Icons.send_rounded)),
                Expanded(child: _TodayStat(label: 'SMS Failed', value: failed, color: AppTheme.errorColor, icon: Icons.sms_failed_rounded)),
                Expanded(child: _TodayStat(label: 'Calls', value: calls, color: AppTheme.infoColor, icon: Icons.call_rounded)),
                Expanded(child: _TodayStat(label: 'Missed', value: missed, color: AppTheme.warningColor, icon: Icons.call_missed_rounded)),
              ]);
            },
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.errorColor))),
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _TodayStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 6),
      Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    ]);
  }
}

// ─── Daily bar chart ──────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> daily;
  final Color cardBg, textPrimary, textSecondary;
  const _DailyBarChart({required this.daily, required this.cardBg, required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    final last7 = daily.take(7).toList().reversed.toList();
    final hasData = last7.any((d) => (d['smsSent'] as int? ?? 0) > 0 || (d['smsFailed'] as int? ?? 0) > 0);
    final maxVal = last7.fold<int>(0, (prev, d) {
      final t = (d['smsSent'] as int? ?? 0) + (d['smsFailed'] as int? ?? 0);
      return t > prev ? t : prev;
    });
    final totalSent = last7.fold<int>(0, (s, d) => s + (d['smsSent'] as int? ?? 0));
    final totalFailed = last7.fold<int>(0, (s, d) => s + (d['smsFailed'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Last 7 Days', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
            Row(children: [
              _Legend(color: AppTheme.successColor, label: '$totalSent sent'),
              const SizedBox(width: 10),
              _Legend(color: AppTheme.errorColor, label: '$totalFailed failed'),
            ]),
          ]),
          const SizedBox(height: 16),
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No SMS in the last 7 days', style: TextStyle(color: textSecondary)),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: last7.map((d) {
                  final sent = d['smsSent'] as int? ?? 0;
                  final failed = d['smsFailed'] as int? ?? 0;
                  final total = sent + failed;
                  final barH = maxVal > 0 ? (total / maxVal * 72).clamp(4.0, 72.0) : 4.0;
                  final sentH = total > 0 ? barH * sent / total : 0.0;
                  final failH = barH - sentH;
                  final label = d['date']?.toString().length == 10
                      ? d['date'].toString().substring(5)
                      : '';
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (total > 0)
                          Text('$total', style: TextStyle(fontSize: 8, color: textSecondary)),
                        const SizedBox(height: 2),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (failH > 0)
                              Container(
                                width: 18, height: failH,
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            if (sentH > 0)
                              Container(
                                width: 18, height: sentH,
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor,
                                  borderRadius: failH > 0
                                      ? BorderRadius.zero
                                      : const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(label, style: TextStyle(fontSize: 9, color: textSecondary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Monthly breakdown ────────────────────────────────────────────────────────

class _MonthlySection extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  final Color cardBg, textPrimary, textSecondary;
  const _MonthlySection({required this.monthly, required this.cardBg, required this.textPrimary, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    final withData = monthly.where((m) =>
      (m['smsSent'] as int? ?? 0) > 0 || (m['smsFailed'] as int? ?? 0) > 0).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 14),
          if (withData.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No monthly data yet', style: TextStyle(color: textSecondary)),
            ))
          else
            ...withData.take(6).map((m) {
              final sent = m['smsSent'] as int? ?? 0;
              final failed = m['smsFailed'] as int? ?? 0;
              final total = sent + failed;
              final rate = total > 0 ? sent / total : 0.0;
              final monthId = m['monthId']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(monthId.length >= 7 ? monthId.substring(0, 7) : monthId,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                      Row(children: [
                        Text('$sent', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.successColor)),
                        Text(' sent  ', style: TextStyle(fontSize: 11, color: textSecondary)),
                        Text('$failed', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.errorColor)),
                        Text(' failed', style: TextStyle(fontSize: 11, color: textSecondary)),
                      ]),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(children: [
                        Container(height: 8, color: AppTheme.errorColor.withAlpha(50)),
                        FractionallySizedBox(
                          widthFactor: rate,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppTheme.successColor, AppTheme.accentColor]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ─── Mini stat card ───────────────────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, cardBg;
  const _MiniCard({required this.label, required this.value, required this.icon, required this.color, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionShimmer extends StatelessWidget {
  final double height;
  const _SectionShimmer({this.height = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.errorColor, fontSize: 12)),
    );
  }
}

// ─── Subscription History Section ─────────────────────────────────────────────

class _SubscriptionHistorySection extends ConsumerWidget {
  final String userId;
  final Color cardBg, textPrimary, textSecondary;
  const _SubscriptionHistorySection({
    required this.userId,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(subscriptionHistoryProvider(userId));

    return historyAsync.when(
      data: (history) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Subscription History',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No subscription history found for this user.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final isLast = index == history.length - 1;

                    return _TimelineItem(
                      entry: entry,
                      isLast: isLast,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const _SectionShimmer(height: 120),
      error: (e, _) => _ErrorTile('$e'),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final SubscriptionHistoryModel entry;
  final bool isLast;
  final Color textPrimary, textSecondary;

  const _TimelineItem({
    required this.entry,
    required this.isLast,
    required this.textPrimary,
    required this.textSecondary,
  });

  IconData _getActionIcon() {
    switch (entry.action) {
      case 'approved':
        return Icons.verified_user_rounded;
      case 'assigned':
        return Icons.add_circle_rounded;
      case 'queued':
        return Icons.hourglass_top_rounded;
      case 'expired':
        return Icons.timer_off_rounded;
      case 'suspended':
        return Icons.block_rounded;
      case 'activated':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getActionColor() {
    switch (entry.action) {
      case 'approved':
      case 'activated':
        return AppTheme.successColor;
      case 'assigned':
        return AppTheme.primaryColor;
      case 'queued':
        return Colors.amber;
      case 'expired':
        return AppTheme.warningColor;
      case 'suspended':
        return AppTheme.errorColor;
      default:
        return AppTheme.infoColor;
    }
  }

  String _getActionTitle() {
    switch (entry.action) {
      case 'approved':
        return 'Approved & Activated';
      case 'assigned':
        return 'New Plan Assigned';
      case 'queued':
        return 'Plan Queued';
      case 'expired':
        return 'Subscription Expired';
      case 'suspended':
        return 'Subscription Suspended';
      case 'activated':
        return 'Subscription Re-activated';
      default:
        return entry.action.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _getActionColor();
    final actionIcon = _getActionIcon();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(actionIcon, color: actionColor, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark
                        ? AppTheme.darkBorder.withOpacity(0.4)
                        : AppTheme.lightBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getActionTitle(),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      _formatDateTime(entry.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (entry.planName.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        entry.planName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: textPrimary,
                        ),
                      ),
                      if (entry.amount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ₹${entry.amount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (entry.startDate != null && entry.endDate != null) ...[
                  Text(
                    'Validity: ${_formatDate(entry.startDate!)} to ${_formatDate(entry.endDate!)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Text(
                      'By: ',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                    _RoleBadge(role: entry.performedByRole),
                    const SizedBox(width: 6),
                    Text(
                      entry.performedBy,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (role) {
      case 'admin':
        badgeColor = Colors.deepPurple;
        break;
      case 'broker':
        badgeColor = Colors.teal;
        break;
      case 'system':
      default:
        badgeColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: badgeColor,
        ),
      ),
    );
  }
}

void _showAssignBrokerDialog(BuildContext context, WidgetRef ref, ReplymetUser user) {
  showDialog(
    context: context,
    builder: (_) => _AssignBrokerDialog(user: user),
  );
}

class _AssignBrokerDialog extends ConsumerStatefulWidget {
  final ReplymetUser user;
  const _AssignBrokerDialog({required this.user});

  @override
  ConsumerState<_AssignBrokerDialog> createState() => _AssignBrokerDialogState();
}

class _AssignBrokerDialogState extends ConsumerState<_AssignBrokerDialog> {
  String? _selectedBrokerId;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final brokersAsync = ref.watch(brokersStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return AlertDialog(
      title: Text('Assign "${widget.user.name}" to Broker'),
      content: SizedBox(
        width: 400,
        child: brokersAsync.when(
          data: (brokers) {
            final activeBrokers = brokers.where((b) => b.isActive).toList();
            if (activeBrokers.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No active brokers found.'),
              );
            }

            return DropdownButtonFormField<String>(
              value: _selectedBrokerId,
              hint: const Text('Select a Broker'),
              decoration: const InputDecoration(
                labelText: 'Broker',
                prefixIcon: Icon(Icons.handshake_rounded),
              ),
              dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
              items: activeBrokers.map((b) {
                return DropdownMenuItem<String>(
                  value: b.brokerId,
                  child: Text(
                    '${b.name} (${b.brokerCode})',
                    style: TextStyle(color: textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedBrokerId = val;
                });
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Text('Error loading brokers: $err', style: const TextStyle(color: AppTheme.errorColor)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading || _selectedBrokerId == null
              ? null
              : () async {
                  setState(() => _loading = true);
                  try {
                    await ref.read(firestoreServiceProvider).assignUserToBroker(
                          widget.user.uid,
                          _selectedBrokerId!,
                        );
                    if (mounted) {
                      Navigator.of(context).pop();
                      showSnack(context, 'User successfully assigned to broker');
                    }
                  } catch (e) {
                    if (mounted) {
                      showSnack(context, e.toString().replaceAll('Exception: ', ''), isError: true);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _loading = false);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }
}