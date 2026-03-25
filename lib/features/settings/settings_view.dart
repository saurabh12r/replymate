import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_controller.dart';

/// Settings View
/// Stitch Screen ID: 85e03ab29e7d4b36b405cd279cd70d9b
///
/// Pushed screen from Profile tab.
///
/// Design (from Stitch):
///  - Gradient header: "Settings" + subtitle + back button
///  - Automation section: Enable Auto Reply toggle
///  - Reply Rules section: missed/incoming/WhatsApp call toggles
///  - Message Configuration: per-event editable messages
///  - Time Range: enable toggle + start/end time pickers
///  - Permissions section: Re-check permissions action
///  - Danger Zone: Logout button
///  - Save Settings floating action
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

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
                        _buildSectionCard(
                          label: 'Automation',
                          icon: Icons.auto_mode_rounded,
                          children: [
                            _buildToggleRow(
                              title: 'Enable Auto Reply',
                              subtitle: 'Activate automated text responses',
                              icon: Icons.reply_rounded,
                              color: _secondary,
                              value: controller.autoReplyEnabled,
                              onToggle: controller.trySetAutoReplyEnabled,
                            ),
                            _sectionDivider(),
                            _buildToggleRow(
                              title: 'Limit auto-replies (1 per hour per contact)',
                              subtitle:
                                  'Prevents sending multiple SMS to the same number within 1 hour',
                              icon: Icons.timer_outlined,
                              color: _primary,
                              value: controller.throttleEnabled,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          label: 'Reply Rules',
                          icon: Icons.rule_rounded,
                          children: [
                            _buildToggleRow(
                              title: 'Reply only on missed calls',
                              subtitle: 'Trigger reply after a call is missed',
                              icon: Icons.phone_missed_rounded,
                              color: _primary,
                              value: controller.replyOnMissedCallOnly,
                            ),
                            _sectionDivider(),
                            _buildToggleRow(
                              title: 'Reply on incoming call',
                              subtitle: 'Auto-reply when a call comes in',
                              icon: Icons.call_rounded,
                              color: _primary,
                              value: controller.replyOnCall,
                            ),
                            _sectionDivider(),
                            _buildToggleRow(
                              title: 'Reply on WhatsApp call',
                              subtitle: 'Also reply for WhatsApp voice calls',
                              icon: Icons.video_call_rounded,
                              color: const Color(0xFF25D366),
                              value: controller.replyOnWhatsappCall,
                            ),
                            _sectionDivider(),
                            _buildToggleRow(
                              title: 'Reply when I’m busy (call waiting)',
                              subtitle: 'Send a busy SMS when another call comes while you’re on a call',
                              icon: Icons.phone_in_talk_rounded,
                              color: const Color(0xFFE65100),
                              value: controller.replyOnBusyCall,
                            ),
                            _sectionDivider(),
                            _buildToggleRow(
                              title: 'Reply on outgoing calls',
                              subtitle: 'Send an SMS when you start an outgoing call',
                              icon: Icons.call_made_rounded,
                              color: const Color(0xFF1565C0),
                              value: controller.replyOnOutgoingCall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildMessageSection(context),
                        const SizedBox(height: 16),
                        _buildPermissionsSection(),
                        const SizedBox(height: 16),
                        _buildDangerZone(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
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
                'Settings',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Configure your automated precision responses.',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withAlpha(190)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section card wrapper ───────────────────────────────────────────────────
  Widget _buildSectionCard({
    required String label,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: _primary, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _sectionDivider() => Divider(height: 1, indent: 62, color: _outlineVariant.withAlpha(80));

  Widget _permStatusRow(String label, bool granted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle_rounded : Icons.warning_rounded,
            size: 16,
            color: granted ? _secondary : _error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: _onSurface),
            ),
          ),
          Text(
            granted ? 'Granted' : 'Missing',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: granted ? _secondary : _error,
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable toggle row ────────────────────────────────────────────────────
  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required RxBool value,
    Future<void> Function(bool nextValue)? onToggle,
  }) {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _onSurface)),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value.value,
                onChanged: (next) async {
                  if (onToggle != null) {
                    await onToggle(next);
                  } else {
                    value.value = next;
                  }
                },
                activeThumbColor: color,
                activeTrackColor: color.withAlpha(60),
              ),
            ],
          ),
        ));
  }

  // ── Message configuration ──────────────────────────────────────────────────
  Widget _buildMessageSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.message_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text('Message Configuration',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: _primary, letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMessageField(
                  label: 'Missed Call Message',
                  hint: "Sorry, I missed your call. I'll call you back.",
                  controller: controller.missedCallMessageController,
                ),
                const SizedBox(height: 12),
                _buildMessageField(
                  label: 'Incoming Call Message',
                  hint: "I'm currently busy, will get back to you soon.",
                  controller: controller.incomingCallMessageController,
                ),
                const SizedBox(height: 12),
                _buildMessageField(
                  label: 'WhatsApp Call Message',
                  hint: 'Sorry, I missed your WhatsApp call.',
                  controller: controller.whatsappCallMessageController,
                ),
                const SizedBox(height: 12),
                _buildMessageField(
                  label: 'Busy Call Message',
                  hint: "I'm on another call right now. I'll call you back.",
                  controller: controller.busyCallMessageController,
                ),
                const SizedBox(height: 12),
                _buildMessageField(
                  label: 'Outgoing Call Message',
                  hint: "I'm currently on a call. I'll get back to you soon.",
                  controller: controller.outgoingCallMessageController,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMessageField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.inter(fontSize: 13, color: _onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: _outlineVariant),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // ── Time range ─────────────────────────────────────────────────────────────
  // ignore: unused_element — time range UI hidden for now
  Widget _buildTimeRangeSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            title: 'Use Time Range',
            subtitle: 'Only reply within a specific window',
            icon: Icons.schedule_rounded,
            color: _primary,
            value: controller.useTimeRange,
          ),
          Obx(() {
            final active = controller.useTimeRange.value;
            final start = controller.startTime.value;
            final end = controller.endTime.value;
            if (!active) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _TimeTile(
                      label: 'Start Time',
                      time: controller.formatTime(start),
                      onTap: () => controller.pickStartTime(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('→', style: GoogleFonts.manrope(fontSize: 18, color: _onSurfaceVariant)),
                  ),
                  Expanded(
                    child: _TimeTile(
                      label: 'End Time',
                      time: controller.formatTime(end),
                      onTap: () => controller.pickEndTime(context),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ignore: unused_element — diagnostics UI hidden for now
  Widget _buildDiagnosticsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.science_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text(
                  'Diagnostics',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: OutlinedButton.icon(
              onPressed: controller.openTestAutoReplyDialog,
              icon: const Icon(Icons.sms_rounded, size: 18, color: _primary),
              label: Text(
                'Send Test Auto Reply',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: _primary.withAlpha(100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permissions ─────────────────────────────────────────────────────────────
  Widget _buildPermissionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text('Permissions', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: _primary, letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _permStatusRow('SMS send', controller.permSmsGranted.value),
                    _permStatusRow(
                      'Phone & call log',
                      controller.permPhoneCallLogsGranted.value,
                    ),
                    _permStatusRow(
                      'Notifications',
                      controller.permPostNotificationsGranted.value,
                    ),
                    _permStatusRow(
                      'Notification listener',
                      controller.permNotificationListenerGranted.value,
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GestureDetector(
              onTap: () => controller.recheckPermissions(),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withAlpha(8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withAlpha(40), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded, size: 18, color: _primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Re-check Permissions',
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
                          Text('Verify call, SMS & notification access',
                              style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _primary.withAlpha(160)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: OutlinedButton.icon(
              onPressed: controller.requestDefaultSmsRole,
              icon: const Icon(Icons.sms_rounded, size: 18, color: _primary),
              label: Text(
                'Set as Default SMS App',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: _primary.withAlpha(100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Danger zone ────────────────────────────────────────────────────────────
  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: _error),
                const SizedBox(width: 8),
                Text('Danger Zone', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: _error, letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: controller.navigateToLogout,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: _error.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.logout_rounded, size: 18, color: _error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sign Out', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _error)),
                        Text('You will be returned to the login screen', style: GoogleFonts.inter(fontSize: 11, color: _error.withAlpha(160))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 20, color: _error.withAlpha(120)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Obx(() {
      final saving = controller.isSaving.value;
      final success = controller.saveSuccess.value;
      return GestureDetector(
        onTap: saving ? null : controller.saveSettings,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: saving
                  ? [Colors.grey.shade400, Colors.grey.shade300]
                  : success
                      ? [_secondary, const Color(0xFF2E7D32)]
                      : [_primary, _primaryContainer],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: saving
                ? []
                : [BoxShadow(color: _primary.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (saving)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else
                Icon(success ? Icons.check_rounded : Icons.save_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                saving ? 'Saving…' : success ? 'Saved!' : 'Save Settings',
                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.time, required this.onTap});

  final String label;
  final String time;
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
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _outlineVariant, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(time, style: TextStyle(fontFamily: 'Manrope', fontSize: 14, fontWeight: FontWeight.w700, color: _onSurface))),
                Icon(Icons.access_time_rounded, size: 15, color: _primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

