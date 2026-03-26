import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../analytics_nav/analytics_nav_view.dart';
import '../contact_filter/contact_filter_tab.dart';
import '../stores/stores_controller.dart';
import '../stores/stores_list_view.dart';
import 'profile_nav_controller.dart';

/// User Profile Nav View (tab content — no bottom nav of its own)
/// Stitch Screen ID: 51d28699599a41debb374aff662d7311
///
/// Design (from Stitch):
///  - Gradient header with avatar + name + role
///  - Contact info: phone + email
///  - Quick stats: 1.2k Smart Replies · 98% Accuracy · 42 Active Days
///  - Options list: Settings · Help & Support · Logout
class ProfileNavView extends GetView<ProfileNavController> {
  const ProfileNavView({super.key});

  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  static const Color _secondary = Color(0xFF006A6A);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProfile.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!controller.isLoggedIn.value) {
        return _buildInfoState(
          title: 'Login required',
          subtitle: 'Please login to view your profile.',
          actionLabel: 'Go to Login',
          onTap: () => Get.offAllNamed(Routes.login),
        );
      }

      if (controller.profileError.value.isNotEmpty) {
        return _buildInfoState(
          title: 'Profile unavailable',
          subtitle: controller.profileError.value,
          actionLabel: 'Retry',
          onTap: controller.reloadProfile,
        );
      }

      if (!controller.hasProfileData.value) {
        return _buildInfoState(
          title: 'No profile data found',
          subtitle: 'We could not find profile details for this account yet.',
        );
      }

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContactCard(),
                const SizedBox(height: 20),
                _buildSectionLabel('Account'),
                const SizedBox(height: 10),
                _buildOptionsList(),
                const SizedBox(height: 20),
                _buildSectionLabel('Support'),
                const SizedBox(height: 10),
                _buildSupportList(),
                const SizedBox(height: 20),
                _buildLogoutButton(),
                const SizedBox(height: 24),
                _buildVersionFooter(),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      );
    });
  }

  // ── Gradient header ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2980), _primary, _primaryContainer],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: controller.navigateToSettings,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(31),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(40)),
                  ),
                  child: const Icon(Icons.settings_rounded, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Avatar + name
          Obx(() {
            final name = controller.userName.value;
            final role = controller.userRole.value;
            // Derive initials
            final parts = name.trim().split(' ');
            final initials = parts.length >= 2
                ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                : parts[0].substring(0, 2).toUpperCase();
            return Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha(31),
                        border: Border.all(color: Colors.white.withAlpha(100), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 4),
                if (role.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(31),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withAlpha(220)),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Contact info card ──────────────────────────────────────────────────────
  Widget _buildContactCard() {
    return Obx(() {
      final ph = controller.phone.value;
      final em = controller.email.value;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            _ContactRow(icon: Icons.badge_rounded, label: 'Name', value: controller.userName.value, color: _secondary),
            const SizedBox(height: 12),
            Divider(height: 1, color: _outlineVariant.withAlpha(80)),
            const SizedBox(height: 12),
            _ContactRow(icon: Icons.phone_rounded, label: 'Phone Number', value: ph, color: _primary),
            const SizedBox(height: 12),
            Divider(height: 1, color: _outlineVariant.withAlpha(80)),
            const SizedBox(height: 12),
            _ContactRow(icon: Icons.email_rounded, label: 'Email Address', value: em, color: _secondary),
          ],
        ),
      );
    });
  }

  Widget _buildInfoState({
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onTap != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: onTap,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Options list ───────────────────────────────────────────────────────────
  Widget _buildOptionsList() {
    return _OptionGroup(
      items: [
        _OptionItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          subtitle: 'App preferences & configuration',
          color: _primary,
          onTap: controller.navigateToSettings,
        ),
        _OptionItem(
          icon: Icons.filter_alt_rounded,
          label: 'Contacts',
          subtitle: 'Choose who receives auto-replies',
          color: const Color(0xFF1565C0),
          onTap: () => Get.to(() => const ContactFilterTab()),
        ),
        _OptionItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          subtitle: 'Reports & insights',
          color: const Color(0xFF6D28D9),
          onTap: () => Get.to(() => const AnalyticsNavView()),
        ),
        _OptionItem(
          icon: Icons.storefront_rounded,
          label: 'Businesses',
          subtitle: 'SIM lines, messages & reply types',
          color: const Color(0xFF1565C0),
          onTap: () {
            if (!Get.isRegistered<StoresController>()) {
              Get.put(StoresController());
            }
            Get.to(() => const StoresListView());
          },
        ),
      ],
    );
  }

  Widget _buildSupportList() {
    return _OptionGroup(
      items: [
        _OptionItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          subtitle: 'FAQs, guides & contact support',
          color: _primary,
          onTap: () {},
        ),
        _OptionItem(
          icon: Icons.policy_rounded,
          label: 'Privacy Policy',
          subtitle: 'How we handle your data',
          color: _onSurfaceVariant,
          onTap: () {},
        ),
        _OptionItem(
          icon: Icons.star_rate_rounded,
          label: 'Rate ReplyMate',
          subtitle: 'Share your experience',
          color: const Color(0xFFF59E0B),
          onTap: () {},
        ),
      ],
    );
  }

  // ── Logout button ──────────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Obx(() {
      final loading = controller.isLoggingOut.value;
      return GestureDetector(
        onTap: loading ? null : controller.confirmLogout,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _error.withAlpha(10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _error.withAlpha(60), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _error.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                child: loading
                    ? Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _error)))
                    : const Icon(Icons.logout_rounded, size: 20, color: _error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loading ? 'Signing out…' : 'Sign Out',
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: _error),
                    ),
                    Text(
                      'You will be returned to the login screen',
                      style: GoogleFonts.inter(fontSize: 11, color: _error.withAlpha(160)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _error.withAlpha(120)),
            ],
          ),
        ),
      );
    });
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: _onSurfaceVariant, letterSpacing: 0.5),
      ),
    );
  }

  // ── Version footer ─────────────────────────────────────────────────────────
  Widget _buildVersionFooter() {
    return Center(
      child: Column(
        children: [
          Text('ReplyMate', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: _onSurfaceVariant)),
          const SizedBox(height: 2),
          Text('Version 1.0.0 · Build 100', style: GoogleFonts.inter(fontSize: 11, color: _outlineVariant)),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: _onSurfaceVariant)),
              Text(value, style: TextStyle(fontFamily: 'Manrope', fontSize: 13, fontWeight: FontWeight.w700, color: _onSurface)),
            ],
          ),
        ),
        Icon(Icons.copy_rounded, size: 16, color: color.withAlpha(120)),
      ],
    );
  }
}

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({required this.items});

  final List<_OptionItem> items;

  static const Color _outlineVariant = Color(0xFFC5C5D4);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) Divider(height: 1, indent: 56, color: _outlineVariant.withAlpha(80)),
          ],
        ],
      ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  const _OptionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontFamily: 'Manrope', fontSize: 13, fontWeight: FontWeight.w700, color: _onSurface)),
                  Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: _onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: color.withAlpha(160)),
          ],
        ),
      ),
    );
  }
}
