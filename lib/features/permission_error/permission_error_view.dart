import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'permission_error_controller.dart';

/// Permission Error View
/// Stitch Screen ID: 18951caf69644594bfd89849c34b3150
/// Project: auto (14054579236203393248)
///
/// Design (from Stitch):
///  - Indigo gradient header with ReplyMate logo
///  - Large animated warning illustration (shield + exclamation)
///  - Title: "Permissions required for auto reply"
///  - Description: why notification channel is needed
///  - Which permissions are missing (visual list)
///  - Two CTAs: "Open Settings" (outline) + "Try Again" (gradient)
class PermissionErrorView extends GetView<PermissionErrorController> {
  const PermissionErrorView({super.key});

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _error = Color(0xFFBA1A1A);
  static const Color _errorContainer = Color(0xFFFFDAD6);
  static const Color _onErrorContainer = Color(0xFF93000A);

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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ── Warning Illustration ──────────────────────────────
                    _buildIllustration(),

                    const SizedBox(height: 32),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Permissions required\nfor auto reply',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Description ───────────────────────────────────────
                    Text(
                      'ReplyMate needs access to your notification channel to detect incoming messages and generate smart responses automatically.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Missing permissions list ───────────────────────────
                    _buildMissingPermissionsList(),

                    const SizedBox(height: 36),

                    // ── Open Settings button (outline) ─────────────────────
                    _buildOpenSettingsButton(),

                    const SizedBox(height: 12),

                    // ── Try Again button (gradient) ────────────────────────
                    _buildTryAgainButton(),

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

  // ── Warning shield illustration ───────────────────────────────────────────
  Widget _buildIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _errorContainer.withAlpha(100),
          ),
        ),
        // Middle ring
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _errorContainer.withAlpha(160),
          ),
        ),
        // Core circle
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _errorContainer,
          ),
          child: const Icon(
            Icons.shield_rounded,
            size: 44,
            color: _error,
          ),
        ),
        // Exclamation badge (top-right)
        Positioned(
          top: 8,
          right: 24,
          child: Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _error,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ── Missing permissions visual list ──────────────────────────────────────
  Widget _buildMissingPermissionsList() {
    final permissions = [
      (Icons.sms_rounded, 'SMS Access'),
      (Icons.notifications_rounded, 'Notification Access'),
      (Icons.call_rounded, 'Call Logs'),
      (Icons.contacts_rounded, 'Contacts'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _errorContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _error.withAlpha(40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Missing permissions',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _onErrorContainer,
            ),
          ),
          const SizedBox(height: 10),
          ...permissions.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _error.withAlpha(15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(p.$1, size: 16, color: _error),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    p.$2,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _onErrorContainer,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.cancel_rounded,
                    size: 16,
                    color: _error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Open Settings (outline button) ────────────────────────────────────────
  Widget _buildOpenSettingsButton() {
    return Obx(() {
      final loading = controller.isOpeningSettings.value;
      return GestureDetector(
        onTap: loading ? null : controller.openSettings,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary, width: 1.8),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.settings_rounded,
                        size: 18,
                        color: _primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Open Settings',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }

  // ── Try Again (gradient button) ───────────────────────────────────────────
  Widget _buildTryAgainButton() {
    return GestureDetector(
      onTap: controller.retry,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryContainer],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Try Again',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
