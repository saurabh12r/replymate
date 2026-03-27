import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'permissions_setup_controller.dart';

/// Permissions Setup View
/// Stitch Screen ID: 342e2e75ebff4d13a2d9cc153f73f614
/// Project: auto (14054579236203393248)
///
/// Design (from Stitch):
///  - Indigo gradient header with ReplyMate logo
///  - Title: "Connect your data"
///  - Subtitle describing why permissions are needed
///  - 4 permission cards: SMS Access, Call Logs, Notification Access, Contacts
///  - Each card: icon + title + description + granted badge
///  - Privacy guarantee note
///  - "Grant & Continue" full-width gradient button
class PermissionsSetupView extends GetView<PermissionsSetupController> {
  const PermissionsSetupView({super.key});

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _secondaryContainer = Color(0xFF90EFEF);

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
                    const SizedBox(height: 28),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Connect your data',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ReplyMate needs these permissions to intelligently automate your responses and keep your workflow fluid.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Data disclosure banner ───────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFFFB74D).withAlpha(80),
                            width: 1),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: Color(0xFFE65100)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'ReplyMate accesses SMS, call log, and notification data solely to detect incoming calls and send automated SMS replies on your behalf. This data is processed locally on your device and is never shared with third parties. Standard carrier SMS charges may apply.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFBF360C),
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Permission cards ──────────────────────────────────
                    Obx(() => Column(
                          children: [
                            _PermissionCard(
                              icon: Icons.sms_rounded,
                              iconBg: const Color(0xFFDEE0FF),
                              iconColor: _primary,
                              title: 'SMS Access',
                              description:
                                  'Send automated SMS replies to callers on your behalf. SMS data stays on your device.',
                              isGranted: controller.isSmsGranted.value,
                              onTap: controller.requestSms,
                            ),
                            const SizedBox(height: 12),
                            _PermissionCard(
                              icon: Icons.call_rounded,
                              iconBg: const Color(0xFFDEE0FF),
                              iconColor: _primary,
                              title: 'Call Logs',
                              description:
                                  'Detect missed, incoming, and rejected calls to trigger auto-replies. Call data is not uploaded.',
                              isGranted: controller.isCallLogsGranted.value,
                              onTap: controller.requestCallLogs,
                            ),
                            const SizedBox(height: 12),
                            _PermissionCard(
                              icon: Icons.notifications_rounded,
                              iconBg: _secondaryContainer.withAlpha(80),
                              iconColor: _secondary,
                              title: 'Notifications',
                              description:
                                  'Show a persistent notification while auto-reply is active (Android 13+).',
                              isGranted:
                                  controller.isNotificationGranted.value,
                              onTap: controller.requestNotification,
                            ),
                            const SizedBox(height: 12),
                            _PermissionCard(
                              icon: Icons.contacts_rounded,
                              iconBg: _secondaryContainer.withAlpha(80),
                              iconColor: _secondary,
                              title: 'Contacts',
                              description:
                                  'Match caller names for contact-based filtering rules. Contact data stays on device.',
                              isGranted: controller.isContactsGranted.value,
                              onTap: controller.requestContacts,
                            ),
                          ],
                        )),

                    const SizedBox(height: 20),

                    // ── Privacy guarantee note ────────────────────────────
                    _buildPrivacyNote(),

                    const SizedBox(height: 28),

                    // ── Grant & Continue button ───────────────────────────
                    _buildContinueButton(),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    Obx(() {
                      if (controller.permanentlyDeniedPermission.value == null) {
                        return const SizedBox.shrink();
                      }
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: controller.openAppSettingsForPermanentlyDenied,
                          child: const Text('Open Settings'),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
          Text(
            'ReplyMate',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Privacy note ──────────────────────────────────────────────────────────
  Widget _buildPrivacyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _secondary.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _secondary.withAlpha(40), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 18, color: _secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your data is encrypted and never shared. We only use these permissions to power the automation logic on your device.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _secondary,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── "Grant & Continue" button ─────────────────────────────────────────────
  Widget _buildContinueButton() {
    return Obx(() {
      final loading = controller.isLoading.value;
      return GestureDetector(
        onTap:
            (loading || !controller.allGranted) ? null : controller.onContinue,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: controller.allGranted
                ? const LinearGradient(
                    colors: [_primary, _primaryContainer],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: controller.allGranted
                ? null
                : const Color(0xFFC5C5D4),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withAlpha(51),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Obx(() => Text(
                      controller.allGranted ? 'Continue' : 'Grant all to continue',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: controller.allGranted
                            ? Colors.white
                            : const Color(0xFF454652),
                        letterSpacing: 0.3,
                      ),
                    )),
          ),
        ),
      );
    });
  }
}

// ── Permission Card widget ────────────────────────────────────────────────────
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isGranted,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String description;
  final bool isGranted;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF24389C);
  static const Color _surfaceLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLowest,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isGranted ? _secondary : _error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isGranted ? 'Granted' : 'Not Granted',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isGranted ? _secondary : _error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: isGranted
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _secondary.withAlpha(18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: _secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Granted',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _secondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Allow',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _primary,
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
