import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../stores/stores_list_view.dart';
import '../stores/stores_controller.dart';
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
  static const Color _success = Color(0xFF2E7D32);
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
                              color: _success,
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
                        _buildBusinessesCard(context),
                        const SizedBox(height: 16),
                        _buildPermissionsSection(),
                        const SizedBox(height: 16),
                        _buildLegalSection(),
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

  Widget _buildBusinessesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (!Get.isRegistered<StoresController>()) {
              Get.put(StoresController());
            }
            Get.to(() => const StoresListView());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFF1565C0)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Businesses & SIM lines',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add businesses, link each to a SIM, and set custom reply messages.',
                        style: GoogleFonts.inter(fontSize: 11, color: _onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Legal section ──────────────────────────────────────────────────────────
  Widget _buildLegalSection() {
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
                const Icon(Icons.description_rounded, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text('Legal', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: _primary, letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _buildLegalRow(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => _launchUrl('https://replymate.app/privacy'),
          ),
          _sectionDivider(),
          _buildLegalRow(
            icon: Icons.article_outlined,
            title: 'Terms of Service',
            subtitle: 'Usage terms and conditions',
            onTap: () => _launchUrl('https://replymate.app/terms'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildLegalRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: _primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: _primary),
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
            Icon(Icons.open_in_new_rounded, size: 16, color: _primary.withAlpha(160)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          _sectionDivider(),
          InkWell(
            onTap: controller.confirmDeleteAccount,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: _error.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.delete_forever_rounded, size: 18, color: _error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Account', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _error)),
                        Text('Permanently remove your account and data', style: GoogleFonts.inter(fontSize: 11, color: _error.withAlpha(160))),
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
