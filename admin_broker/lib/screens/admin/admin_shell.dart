import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

/// Admin shell with persistent sidebar layout
class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          const AdminSidebar(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final isDarkMode = ref.watch(themeModeProvider);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: textSecondary, size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Theme toggle
          IconButton(
            onPressed: () =>
                ref.read(themeModeProvider.notifier).state = !isDarkMode,
            icon: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: textSecondary,
              size: 20,
            ),
            tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
