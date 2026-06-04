import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'logout_controller.dart';

class LogoutView extends GetView<LogoutController> {
  const LogoutView({super.key});

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildLogoutCard(),
                    const SizedBox(height: 32),
                    _buildActions(),
                    const SizedBox(height: 24),
                    _buildFooterNote(),
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
            onPressed: controller.cancel,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
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
                'Manage your account and preferences',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withAlpha(190),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Obx(() {
      final name = controller.userName.value;
      final email = controller.userEmail.value;
      final parts = name.trim().split(' ');
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : parts[0].substring(0, 2).toUpperCase();

      return Container(
        padding: const EdgeInsets.all(18),
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_primary, _primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _secondary.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _secondary.withAlpha(50), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _secondary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _secondary,
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

  // ── Logout warning card ────────────────────────────────────────────────────
  Widget _buildLogoutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Warning icon container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _error.withAlpha(10),
              shape: BoxShape.circle,
              border: Border.all(color: _error.withAlpha(30), width: 1.5),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 26,
                  color: _error,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Section label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _error.withAlpha(10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _error.withAlpha(40), width: 1),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _error,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Are you sure?',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'You will need to re-authenticate to access your workspace.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Info bullets
          ..._infoBullets(),
        ],
      ),
    );
  }

  List<Widget> _infoBullets() {
    const items = [
      (Icons.lock_outline_rounded, 'Session will be terminated immediately'),
      (Icons.cloud_off_rounded, 'Sync will stop until you log back in'),
      (Icons.reply_outlined, 'Auto-replies will be paused'),
    ];
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _error.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.$1, size: 14, color: _error.withAlpha(180)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.$2,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Obx(() {
      final loading = controller.isLoggingOut.value;
      return Column(
        children: [
          // Confirm Logout button
          GestureDetector(
            onTap: loading ? null : controller.confirmLogout,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: loading
                      ? [Colors.grey.shade400, Colors.grey.shade300]
                      : [_error, const Color(0xFF8B0000)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: loading
                    ? []
                    : [
                        BoxShadow(
                          color: _error.withAlpha(60),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
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
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Text(
                    loading ? 'Signing out…' : 'Yes, Sign Out',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          GestureDetector(
            onTap: loading ? null : controller.cancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _outlineVariant, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    color: _onSurface.withAlpha(180),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel, go back',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  // ── Footer note ────────────────────────────────────────────────────────────
  Widget _buildFooterNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_outlined,
          size: 14,
          color: _onSurfaceVariant.withAlpha(120),
        ),
        const SizedBox(width: 6),
        Text(
          'Your data is safe — nothing will be deleted',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: _onSurfaceVariant.withAlpha(160),
          ),
        ),
      ],
    );
  }
}
