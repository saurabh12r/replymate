import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_guide_controller.dart';

/// Notification Guide View
/// Stitch Screen ID: 7d3dca8e4eb24eebb6c32371bbab60a2
/// Project: auto (14054579236203393248)
///
/// Design (from Stitch):
///  - Indigo gradient header with ReplyMate logo
///  - Progress indicator: "Step 1 of 3: Permissions Setup"
///  - Title: "Enable Smart Replies"
///  - Subtitle: "To provide instant AI responses, ReplyMate needs access to your notifications."
///  - 3 numbered step cards:
///      1. Open Settings  — tap button to jump to notification settings
///      2. Find ReplyMate — scroll app list to find ReplyMate
///      3. Toggle Access  — switch "Allow Notification Access" ON
///  - "Open Notification Settings" outline button
///  - "Continue" gradient button → SMS Config
class NotificationGuideView extends GetView<NotificationGuideController> {
  const NotificationGuideView({super.key});

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
                    const SizedBox(height: 24),

                    // ── Progress pill ─────────────────────────────────────
                    _buildProgressPill(),

                    const SizedBox(height: 24),

                    // ── Illustration ──────────────────────────────────────
                    _buildIllustration(),

                    const SizedBox(height: 28),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      'Enable Smart Replies',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Subtitle ──────────────────────────────────────────
                    Text(
                      'To provide instant AI responses, ReplyMate needs access to your notifications.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── 3 Step cards ──────────────────────────────────────
                    _StepCard(
                      stepNumber: 1,
                      title: 'Open Settings',
                      description:
                          'Tap the button below to jump directly to your device\'s notification settings.',
                      icon: Icons.settings_rounded,
                    ),
                    const SizedBox(height: 12),
                    _StepCard(
                      stepNumber: 2,
                      title: 'Find ReplyMate',
                      description:
                          'Scroll through the list of installed applications to locate the ReplyMate app entry.',
                      icon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 12),
                    _StepCard(
                      stepNumber: 3,
                      title: 'Toggle Access',
                      description:
                          'Switch the "Allow Notification Access" toggle to the ON position to finish.',
                      icon: Icons.toggle_on_rounded,
                    ),

                    const SizedBox(height: 32),

                    // ── Open Settings (outline) ───────────────────────────
                    _buildOpenSettingsButton(),

                    const SizedBox(height: 12),

                    // ── Continue (gradient) ───────────────────────────────
                    _buildContinueButton(),

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

  // ── Gradient header ───────────────────────────────────────────────────────
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
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress pill: "Step 1 of 3: Permissions Setup" ───────────────────────
  Widget _buildProgressPill() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
                    'Step 1 of 3 · Permissions Setup',
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
          ],
        ),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1 / 3,
            backgroundColor: _primary.withAlpha(18),
            valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  // ── Notification bell illustration ────────────────────────────────────────
  Widget _buildIllustration() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _secondaryContainer.withAlpha(60),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _secondaryContainer.withAlpha(120),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _secondary.withAlpha(200),
                  _secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          // Signal arcs (top-right)
          Positioned(
            top: 12,
            right: 22,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primary,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Open Notification Settings (outline) ──────────────────────────────────
  Widget _buildOpenSettingsButton() {
    return Obx(() {
      final loading = controller.isOpeningSettings.value;
      return GestureDetector(
        onTap: loading ? null : controller.openNotificationSettings,
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
                        'Open Notification Settings',
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

  // ── Continue (gradient) ───────────────────────────────────────────────────
  Widget _buildContinueButton() {
    return Obx(() {
      final loading = controller.isLoading.value;
      return GestureDetector(
        onTap: loading ? null : controller.onContinue,
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
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}

// ── Step card widget ──────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;

  static const Color _primary = Color(0xFF24389C);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2980), _primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    const Spacer(),
                    Icon(icon, size: 18, color: _primary.withAlpha(150)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
