import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sms_config_controller.dart';

/// SMS Configuration View
/// Stitch Screen ID: 53c349aca01c48a582c0b153cecb49d2
/// Project: auto (14054579236203393248)
///
/// Design (from Stitch):
///  - Indigo gradient header with "Step 2 of 3" progress
///  - Title: "Configure Auto-Reply"
///  - Subtitle: set up custom SMS response
///  - Auto-Reply master toggle card
///  - Reply triggers toggle list: On Call / Missed Call / WhatsApp Call
///  - Active hours time range (start–end) when enabled
///  - Message text area with char counter
///  - 3 quick-select template chips
///  - "Save & Continue" gradient button → Dashboard
class SmsConfigView extends GetView<SmsConfigController> {
  const SmsConfigView({super.key});

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF24389C);
  static const Color _success = Color(0xFF2E7D32);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _secondary = Color(0xFF006A6A);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildProgressPill(),
                    const SizedBox(height: 24),
                    Text(
                      'Configure Auto-Reply',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up your custom response for incoming SMS messages when you\'re away. Use placeholders to personalize the experience.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── SMS fee notice ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD54F).withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFFF57F17),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Auto-replies are sent as standard SMS. Normal carrier messaging rates apply.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFF57F17),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Master Auto-Reply toggle ──────────────────────────
                    _buildMasterToggle(),
                    const SizedBox(height: 16),

                    // ── Reply triggers section ────────────────────────────
                    _buildSectionLabel('Reply Triggers'),
                    const SizedBox(height: 10),
                    _buildTogglesCard(),
                    const SizedBox(height: 16),

                    // ── Active Hours ──────────────────────────────────────
                    _buildSectionLabel('Active Hours'),
                    const SizedBox(height: 10),
                    _buildActiveHoursCard(context),
                    const SizedBox(height: 16),

                    // ── Reply message ─────────────────────────────────────
                    _buildSectionLabel('Default Reply Message'),
                    const SizedBox(height: 10),
                    _buildMessageField(),
                    const SizedBox(height: 14),

                    // ── Template chips ────────────────────────────────────
                    _buildSectionLabel('Quick Templates'),
                    const SizedBox(height: 10),
                    _buildTemplateChips(),
                    const SizedBox(height: 32),

                    // ── Save & Continue ───────────────────────────────────
                    _buildSaveButton(),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (controller.errorMessage.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        controller.errorMessage.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFBA1A1A),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2980), _primary, _primaryContainer],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(31),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(51), width: 1),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ReplyMate',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Setup Guide',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withAlpha(179),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress pill: Step 2 of 3 ────────────────────────────────────────────
  Widget _buildProgressPill() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primary.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Step 2 of 3 · SMS Configuration',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 2 / 3,
            backgroundColor: _primary.withAlpha(18),
            valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _onSurface,
        letterSpacing: 0.1,
      ),
    );
  }

  // ── Master Auto-Reply toggle ───────────────────────────────────────────────
  Widget _buildMasterToggle() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: autoReplyEnabled.value
              ? LinearGradient(
                  colors: [
                    _primary.withAlpha(20),
                    _primaryContainer.withAlpha(10),
                  ],
                )
              : null,
          color: autoReplyEnabled.value ? null : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: autoReplyEnabled.value
                ? _primary.withAlpha(80)
                : _outlineVariant,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: autoReplyEnabled.value
                    ? _primary.withAlpha(25)
                    : _outlineVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 22,
                color: autoReplyEnabled.value ? _primary : _onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable Auto-Reply',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  Text(
                    'Activate SMS responder now',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: autoReplyEnabled.value,
              onChanged: (v) => controller.autoReplyEnabled.value = v,
              activeThumbColor: _success,
              activeTrackColor: _success.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reply triggers card ────────────────────────────────────────────────────
  Widget _buildTogglesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _ToggleRow(
            icon: Icons.call_rounded,
            iconColor: _primary,
            title: 'Reply on Answered Call',
            subtitle: 'Auto-reply when you pick up a call',
            value: controller.replyOnCall,
            isFirst: true,
          ),
          Divider(height: 1, color: _outlineVariant.withAlpha(80), indent: 64),
          _ToggleRow(
            icon: Icons.phone_missed_rounded,
            iconColor: _secondary,
            title: 'Reply on Missed Call',
            subtitle: 'Send reply after missing a call',
            value: controller.replyOnMissedCall,
          ),
          Divider(height: 1, color: _outlineVariant.withAlpha(80), indent: 64),
          _ToggleRow(
            icon: Icons.phone_disabled_rounded,
            iconColor: const Color(0xFFD32F2F),
            title: 'Reply on Rejected Call',
            subtitle: 'Send reply when you reject a call',
            value: controller.replyOnRejectedCall,
          ),
          Divider(height: 1, color: _outlineVariant.withAlpha(80), indent: 64),
          _ToggleRow(
            icon: Icons.phone_in_talk_rounded,
            iconColor: const Color(0xFFE65100),
            title: 'Reply on Busy Call',
            subtitle: 'Reply when busy on another call',
            value: controller.replyOnBusyCall,
          ),
          Divider(height: 1, color: _outlineVariant.withAlpha(80), indent: 64),
          _ToggleRow(
            icon: Icons.call_made_rounded,
            iconColor: const Color(0xFF1565C0),
            title: 'Reply on Outgoing (Answered)',
            subtitle: 'Follow-up SMS after they pick up',
            value: controller.replyOnOutgoingAnswered,
          ),
          Divider(height: 1, color: _outlineVariant.withAlpha(80), indent: 64),
          _ToggleRow(
            icon: Icons.phone_missed_rounded,
            iconColor: const Color(0xFF6A1B9A),
            title: 'Reply on Outgoing (No Answer)',
            subtitle: 'SMS when they don\'t pick up your call',
            value: controller.replyOnOutgoingUnanswered,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Active hours card ────────────────────────────────────────────────────
  Widget _buildActiveHoursCard(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: _secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Active Hours',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _onSurface,
                        ),
                      ),
                      Text(
                        'Only auto-reply within these hours',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.useTimeRange.value,
                  onChanged: (v) => controller.useTimeRange.value = v,
                  activeThumbColor: _secondary,
                  activeTrackColor: _secondary.withAlpha(80),
                ),
              ],
            ),
            if (controller.useTimeRange.value) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Start Time',
                      time: controller.formatTime(controller.startTime.value),
                      onTap: () => controller.pickStartTime(context),
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'End Time',
                      time: controller.formatTime(controller.endTime.value),
                      onTap: () => controller.pickEndTime(context),
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Message text field ────────────────────────────────────────────────────
  Widget _buildMessageField() {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outlineVariant, width: 1.2),
        ),
        child: Column(
          children: [
            TextField(
              controller: controller.messageController,
              maxLines: 4,
              maxLength: 160,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _onSurface,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'Type your auto-reply message here…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: _onSurfaceVariant.withAlpha(128),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterText: '',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
                border: Border(
                  top: BorderSide(
                    color: _outlineVariant.withAlpha(100),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Characters used',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                    ),
                  ),
                  Text(
                    controller.charCount.value,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: controller.defaultReplyMessage.value.length > 140
                          ? const Color(0xFFBA1A1A)
                          : _onSurfaceVariant,
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

  // ── Template quick-select chips ───────────────────────────────────────────
  Widget _buildTemplateChips() {
    return Column(
      children: SmsConfigController.templates.map((t) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => controller.applyTemplate(t),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _outlineVariant, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: _primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurface,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: _onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Save & Continue button ────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(() {
      final canSave =
          controller.defaultReplyMessage.value.trim().isNotEmpty &&
          !controller.isSaving.value;
      return GestureDetector(
        onTap: canSave ? controller.saveAndContinue : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: canSave
                ? const LinearGradient(
                    colors: [_primary, _primaryContainer],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canSave ? null : _outlineVariant,
            borderRadius: BorderRadius.circular(16),
            boxShadow: canSave
                ? [
                    BoxShadow(
                      color: _primary.withAlpha(51),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: controller.isSaving.value
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Save & Continue',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: canSave ? Colors.white : _onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: canSave ? Colors.white : _onSurfaceVariant,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  // Shortcut getters to avoid typing controller. everywhere in static context
  RxBool get autoReplyEnabled => controller.autoReplyEnabled;
}

// ── Toggle row widget ─────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final RxBool value;
  final bool isFirst;
  final bool isLast;

  static const Color _success = Color(0xFF2E7D32);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Switch(
                value: value.value,
                onChanged: (v) => value.value = v,
                activeThumbColor: _success,
                activeTrackColor: _success.withAlpha(80),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Time picker button ────────────────────────────────────────────────────────
class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
    required this.color,
  });

  final String label;
  final String time;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  time,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
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
