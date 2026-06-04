import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/common/app_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Settings',
            subtitle: 'Account and application settings',
            icon: Icons.settings_rounded,
          ),
          const SizedBox(height: 24),

          // Profile Card
          AppCard(
            title: 'Profile Information',
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                      child: Text(
                        (currentUser?.name.isNotEmpty == true)
                            ? currentUser!.name[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser?.name ?? 'Admin',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(currentUser?.email ?? '',
                              style: TextStyle(color: textSecondary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (currentUser?.role ?? 'admin').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Appearance
          AppCard(
            title: 'Appearance',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: 'Toggle between dark and light theme',
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) =>
                        ref.read(themeModeProvider.notifier).state = v,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Security
          AppCard(
            title: 'Security',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.lock_reset_rounded,
                  title: 'Reset Password',
                  subtitle: 'Send password reset email',
                  trailing: OutlinedButton(
                    onPressed: () => _resetPassword(context, ref),
                    child: const Text('Send Email'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Danger Zone
          AppCard(
            title: 'Session',
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    try {
      await ref.read(authServiceProvider).resetPassword(user.email);
      if (context.mounted) {
        showSnack(context, 'Password reset email sent to ${user.email}');
      }
    } catch (e) {
      if (context.mounted) showSnack(context, 'Error: $e', isError: true);
    }
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(color: textSecondary, fontSize: 12)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
