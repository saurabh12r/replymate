import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'export_controller.dart';

/// Export Reports View
/// Stitch Screen ID: 89e50d2e95d24c19b3a75220080b3f0e
///
/// Pushed screen. Navigate back to Reports Summary via Get.back().
///
/// Design (from Stitch):
///  - Gradient header "Export Data" + back button
///  - Select Timeframe section (chips)
///  - Custom date range (shown only when 'Custom Range' is selected)
///  - Report Format section (PDF / CSV / Excel selector cards)
///  - Include options (toggles: Charts / Raw Data / Call Breakdown / Insights)
///  - Report preview card: reply count, widget count, AI processed badge, last-saved
///  - Generate Export CTA button (animated loading state)
class ExportView extends GetView<ExportController> {
  const ExportView({super.key});

  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionLabel('Select Timeframe'),
                        const SizedBox(height: 12),
                        _buildTimeframeChips(),
                        const SizedBox(height: 8),
                        _buildCustomDateRange(context),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Report Format'),
                        const SizedBox(height: 12),
                        _buildFormatCards(),
                        const SizedBox(height: 24),
                        _buildSectionLabel('Include in Report'),
                        const SizedBox(height: 12),
                        _buildIncludeOptions(),
                        const SizedBox(height: 24),
                        _buildPreviewCard(),
                        const SizedBox(height: 24),
                        _buildGenerateButton(),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient header ────────────────────────────────────────────────────────
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
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Data',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Generate & download your reports',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withAlpha(190)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: _onSurface),
    );
  }

  // ── Timeframe chips ────────────────────────────────────────────────────────
  Widget _buildTimeframeChips() {
    return Obx(() {
      final selected = controller.selectedTimeframe.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: controller.timeframes.map((tf) {
          final isSelected = selected == tf;
          return GestureDetector(
            onTap: () => controller.selectTimeframe(tf),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _primary : _outlineVariant,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: _primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Text(
                tf,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // ── Custom date range (conditional) ───────────────────────────────────────
  Widget _buildCustomDateRange(BuildContext context) {
    return Obx(() {
      final show = controller.showCustomRange;
      if (!show) return const SizedBox.shrink();
      final start = controller.startDate.value;
      final end = controller.endDate.value;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: _DatePickerTile(
                label: 'Start Date',
                date: controller.formatDate(start),
                onTap: () => controller.pickStartDate(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('→', style: GoogleFonts.manrope(fontSize: 18, color: _onSurfaceVariant)),
            ),
            Expanded(
              child: _DatePickerTile(
                label: 'End Date',
                date: controller.formatDate(end),
                onTap: () => controller.pickEndDate(context),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Report format cards ────────────────────────────────────────────────────
  Widget _buildFormatCards() {
    return Obx(() {
      final selected = controller.selectedFormat.value;
      return Row(
        children: controller.formats.map((fmt) {
          final label = fmt['label'] as String;
          final icon = fmt['icon'] as IconData;
          final desc = fmt['desc'] as String;
          final isSelected = selected == label;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.selectFormat(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: label != controller.formats.last['label'] ? 10 : 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _primary : _outlineVariant,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _primary.withAlpha(50), blurRadius: 10, offset: const Offset(0, 3))]
                      : [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 26, color: isSelected ? Colors.white : _primary),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : _onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: isSelected ? Colors.white.withAlpha(200) : _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // ── Include toggles ────────────────────────────────────────────────────────
  Widget _buildIncludeOptions() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            label: 'Charts & Graphs',
            subtitle: 'Visual analytics charts',
            icon: Icons.bar_chart_rounded,
            value: controller.includeCharts,
          ),
          _divider(),
          _buildToggleRow(
            label: 'Raw Data',
            subtitle: 'Unformatted data tables',
            icon: Icons.table_rows_rounded,
            value: controller.includeRawData,
          ),
          _divider(),
          _buildToggleRow(
            label: 'Call Breakdown',
            subtitle: 'Missed, WhatsApp, Incoming',
            icon: Icons.call_rounded,
            value: controller.includeCallBreakdown,
          ),
          _divider(),
          _buildToggleRow(
            label: 'AI Insights',
            subtitle: 'Automated tips & analysis',
            icon: Icons.auto_awesome_rounded,
            value: controller.includeInsights,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, color: _outlineVariant.withAlpha(80));

  Widget _buildToggleRow({
    required String label,
    required String subtitle,
    required IconData icon,
    required RxBool value,
  }) {
    return Obx(() => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),
          title: Text(
            label,
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _onSurface),
          ),
          subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant)),
          trailing: Switch.adaptive(
            value: value.value,
            onChanged: (_) => value.toggle(),
            activeThumbColor: _primary,
          ),
        ));
  }

  // ── Report preview card ────────────────────────────────────────────────────
  Widget _buildPreviewCard() {
    return Obx(() {
      final reply = controller.repliesCount.value;
      final widgets = controller.widgetsCount.value;
      final saved = controller.lastSaved.value;
      final ready = controller.isReady.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary.withAlpha(12), _secondary.withAlpha(8)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primary.withAlpha(40), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_rounded, size: 20, color: _primary),
                const SizedBox(width: 8),
                Text(
                  'Report Preview',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: _primary),
                ),
                const Spacer(),
                // Ready badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ready ? _secondary.withAlpha(20) : Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ready ? _secondary : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ready ? _secondary : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        ready ? 'Ready to Generate' : 'Processing…',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ready ? _secondary : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Your report will include $reply replies and $widgets analytics widgets processed by AI.',
              style: GoogleFonts.inter(fontSize: 13, color: _onSurface, height: 1.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 13, color: _onSurfaceVariant),
                const SizedBox(width: 5),
                Text(saved, style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant)),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Generate export button ─────────────────────────────────────────────────
  Widget _buildGenerateButton() {
    return Obx(() {
      final exporting = controller.isExporting.value;
      final success = controller.exportSuccess.value;

      Color startColor = exporting ? Colors.grey.shade400 : (success ? _secondary : _primary);
      Color endColor = exporting ? Colors.grey.shade300 : (success ? const Color(0xFF2E7D32) : _primaryContainer);

      return GestureDetector(
        onTap: exporting ? null : controller.generateExport,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [startColor, endColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: exporting
                ? []
                : [BoxShadow(color: startColor.withAlpha(60), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (exporting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else
                Icon(
                  success ? Icons.check_circle_rounded : Icons.file_download_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              const SizedBox(width: 10),
              Text(
                exporting
                    ? 'Generating Report…'
                    : success
                        ? 'Export Complete!'
                        : 'Generate & Export',
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Date picker tile ──────────────────────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.label, required this.date, required this.onTap});

  final String label;
  final String date;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF24389C);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _outlineVariant, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: _onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _onSurface),
                  ),
                ),
                Icon(Icons.calendar_month_rounded, size: 16, color: _primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
