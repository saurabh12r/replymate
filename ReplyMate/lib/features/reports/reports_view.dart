import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reports_controller.dart';
import '../../core/theme/upcoming_feature_dialog.dart';

/// Reports Summary View
/// Stitch Screen ID: c69c1fd624e8483b9e12bc7a94f6a823
///
/// Pushed screen (not bottom-nav tab). Has back navigation.
///
/// Design (from Stitch):
///  - Gradient header: "Reports · Overview" + back button
///  - Period selector: Daily / Weekly / Monthly
///  - Activity Summary: Total Messages + Response Rate KPIs
///  - Message Classification: 3 categories with progress bars (Stitch exact values)
///  - Automated Insight card (AI tip)
///  - Call breakdown stat row
///  - "Export Data" CTA button
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  _buildActivitySummary(),
                  const SizedBox(height: 20),
                  _buildMessageClassification(),
                  const SizedBox(height: 20),
                  _buildInsightCard(),
                  const SizedBox(height: 20),
                  _buildCallBreakdown(context),
                  const SizedBox(height: 24),
                  _buildExportButton(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient header with back button ───────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 24),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          IconButton(
            onPressed: Get.back,
            icon: const BackButtonIcon(),
            color: Colors.white,
            iconSize: 20,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Overview',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withAlpha(190),
                ),
              ),
            ],
          ),
          const Spacer(),
          _IconBtn(icon: Icons.filter_list_rounded, onTap: () {}),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.refresh_rounded, onTap: () {}),
        ],
      ),
    );
  }

  // ── Period selector ────────────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Obx(() {
      final selected = controller.selectedPeriod.value;
      return Row(
        children: controller.periods.map((p) {
          final isSelected = selected == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setPeriod(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: p != controller.periods.last ? 8 : 0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _primary : _outlineVariant,
                    width: 1.2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primary.withAlpha(40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  p,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : _onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // ── Activity summary KPIs ──────────────────────────────────────────────────
  Widget _buildActivitySummary() {
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
            'Activity Summary',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final total = controller.totalMessages.value;
            final rate = controller.responseRate.value;
            return Row(
              children: [
                _SummaryKpi(
                  value: total >= 1000
                      ? '${(total / 1000).toStringAsFixed(1)}k'
                      : '$total',
                  label: 'Total Messages',
                  icon: Icons.chat_bubble_rounded,
                  color: _primary,
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: _outlineVariant.withAlpha(80),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _SummaryKpi(
                  value: rate,
                  label: 'Response Rate',
                  icon: Icons.speed_rounded,
                  color: _secondary,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Message classification ─────────────────────────────────────────────────
  Widget _buildMessageClassification() {
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
            'Message Classification',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            // ✅ Observables captured at top of Obx callback
            final cats = controller.categories.toList();
            return Column(
              children: [
                for (int i = 0; i < cats.length; i++) ...[
                  _CategoryRow(category: cats[i]),
                  if (i < cats.length - 1) const SizedBox(height: 14),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── AI Insight card ────────────────────────────────────────────────────────
  Widget _buildInsightCard() {
    return Obx(() {
      final text = controller.insightText.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary.withAlpha(15), _secondary.withAlpha(10)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withAlpha(40), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: _primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automated Insight',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onSurface,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Call breakdown row ─────────────────────────────────────────────────────
  Widget _buildCallBreakdown(BuildContext context) {
    return Obx(() {
      final total = controller.totalCalls.value;
      final missed = controller.missedCalls.value;
      final whatsapp = controller.whatsappCalls.value;
      final auto = controller.autoRepliesSent.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Breakdown',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                icon: Icons.call_rounded,
                label: 'Total Calls',
                value: '$total',
                color: _primary,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.phone_missed_rounded,
                label: 'Missed',
                value: '$missed',
                color: _error,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.forum_rounded,
                label: 'WhatsApp',
                value: '$whatsapp',
                color: const Color(0xFF25D366),
                onTap: () => showUpcomingFeatureDialog(context, featureName: 'WhatsApp Call Reports'),
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.send_rounded,
                label: 'Replies',
                value: '$auto',
                color: _secondary,
              ),
            ],
          ),
        ],
      );
    });
  }

  // ── Export button ──────────────────────────────────────────────────────────
  Widget _buildExportButton() {
    return Obx(() {
      final exporting = controller.isExporting.value;
      return GestureDetector(
        onTap: exporting ? null : controller.exportReport,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: exporting
                  ? [Colors.grey.shade400, Colors.grey.shade300]
                  : [_primary, _primaryContainer],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: exporting
                ? []
                : [
                    BoxShadow(
                      color: _primary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (exporting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              else
                const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                exporting ? 'Preparing export…' : 'Export Data',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

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

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _onSurface,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final MessageCategory category;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);

  @override
  Widget build(BuildContext context) {
    final pct = '${(category.fraction * 100).toInt()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: category.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
              ],
            ),
            Text(
              pct,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: category.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          category.subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: _outlineVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: category.fraction,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _onSurface,
                height: 1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 9, color: _onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
}
