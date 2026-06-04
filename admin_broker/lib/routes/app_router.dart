import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/plans_screen.dart';
import '../screens/admin/users_screen.dart';
import '../screens/admin/pending_approvals_screen.dart';
import '../screens/admin/brokers_screen.dart';
import '../screens/admin/revenue_screen.dart';
import '../screens/admin/logs_screen.dart';
import '../screens/admin/stats_screen.dart';
import '../screens/admin/user_detail_screen.dart';
import '../screens/admin/settings_screen.dart';
import '../screens/admin/expired_users_screen.dart';
import '../screens/admin/notifications_screen.dart';
import '../screens/broker/broker_dashboard_screen.dart';
import '../screens/broker/broker_users_screen.dart';
import '../screens/broker/broker_approvals_screen.dart';
import '../screens/broker/broker_analytics_screen.dart';
import '../screens/broker/broker_expired_users_screen.dart';
import '../screens/shared/campaign_screen.dart';
import '../widgets/common/responsive_shell.dart';

// ✅ FIX: RouterNotifier listens to auth changes and notifies GoRouter
// to re-run its redirect function — without recreating the router itself.
//
// The old pattern (ref.watch inside Provider<GoRouter>) created a brand-new
// GoRouter on every auth emission. GoRouter is a ChangeNotifier — Riverpod
// cannot cast the rebuilt instance to the expected type, causing:
// "type 'minified:mE' is not a subtype of type 'minified:f2'"
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen to auth changes and notify GoRouter to re-evaluate redirect.
    // ref.listen is safe here — it does not rebuild the router object.
    _ref.listen<AsyncValue>(authStateProvider, (_, __) => notifyListeners());
    _ref.listen<AsyncValue>(currentUserProvider, (_, __) => notifyListeners());
  }

  String? redirect(GoRouterState state) {
    // Read (not watch) — we only need current values at redirect time.
    final authState = _ref.read(authStateProvider);
    final currentUserAsync = _ref.read(currentUserProvider);

    final isLoggedIn = authState.valueOrNull != null;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) {
      final user = currentUserAsync.valueOrNull;
      if (user == null) return null; // still loading user doc — wait
      return user.isAdmin ? '/admin' : '/broker';
    }
    return null;
  }
}

// ✅ Router is created ONCE and never recreated.
// Auth changes trigger redirect via refreshListenable, not a new GoRouter.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  // Dispose the notifier when the provider is disposed.
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier, // re-runs redirect() on auth change
    redirect: (context, state) => notifier.redirect(state),
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (ctx, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // Admin shell
      ShellRoute(
        builder: (ctx, state, child) => ResponsiveShell(
          child: child,
          adminItems: adminNavItems,
          brokerItems: brokerNavItems,
          isAdmin: true,
        ),
        routes: [
          GoRoute(path: '/admin',            pageBuilder: (ctx, s) => _buildPage(const AdminDashboardScreen(), s)),
          GoRoute(path: '/admin/plans',      pageBuilder: (ctx, s) => _buildPage(const PlansScreen(), s)),
          GoRoute(path: '/admin/users',      pageBuilder: (ctx, s) => _buildPage(const UsersScreen(), s)),
          GoRoute(path: '/admin/approvals',  pageBuilder: (ctx, s) => _buildPage(const PendingApprovalsScreen(), s)),
          GoRoute(path: '/admin/brokers',    pageBuilder: (ctx, s) => _buildPage(const BrokersScreen(), s)),
          GoRoute(path: '/admin/revenue',    pageBuilder: (ctx, s) => _buildPage(const RevenueScreen(), s)),
          GoRoute(path: '/admin/logs',       pageBuilder: (ctx, s) => _buildPage(const LogsScreen(), s)),
          GoRoute(path: '/admin/stats',      pageBuilder: (ctx, s) => _buildPage(const StatsScreen(), s)),
          GoRoute(path: '/admin/user/:userId', pageBuilder: (ctx, s) => _buildPage(UserDetailScreen(odlId: s.pathParameters['userId']!), s)),
          GoRoute(path: '/admin/settings',   pageBuilder: (ctx, s) => _buildPage(const SettingsScreen(), s)),
          GoRoute(path: '/admin/expired-users', pageBuilder: (ctx, s) => _buildPage(const ExpiredUsersScreen(), s)),
          GoRoute(path: '/admin/campaigns', pageBuilder: (ctx, s) => _buildPage(const CampaignScreen(), s)),
          GoRoute(path: '/admin/notifications', pageBuilder: (ctx, s) => _buildPage(const AdminNotificationsScreen(), s)),
        ],
      ),

      // Broker shell
      ShellRoute(
        builder: (ctx, state, child) => ResponsiveShell(
          child: child,
          adminItems: adminNavItems,
          brokerItems: brokerNavItems,
          isAdmin: false,
        ),
        routes: [
          GoRoute(path: '/broker',           pageBuilder: (ctx, s) => _buildPage(const BrokerDashboardScreen(), s)),
          GoRoute(path: '/broker/users',     pageBuilder: (ctx, s) => _buildPage(const BrokerUsersScreen(), s)),
          GoRoute(path: '/broker/expired-users', pageBuilder: (ctx, s) => _buildPage(const BrokerExpiredUsersScreen(), s)),
          GoRoute(path: '/broker/campaigns', pageBuilder: (ctx, s) => _buildPage(const CampaignScreen(), s)),
          GoRoute(path: '/broker/notifications', pageBuilder: (ctx, s) => _buildPage(const BrokerNotificationsScreen(), s)),
          GoRoute(path: '/broker/approvals', pageBuilder: (ctx, s) => _buildPage(const BrokerApprovalsScreen(), s)),
          GoRoute(path: '/broker/analytics', pageBuilder: (ctx, s) => _buildPage(const BrokerAnalyticsScreen(), s)),
          GoRoute(path: '/broker/user/:userId', pageBuilder: (ctx, s) => _buildPage(UserDetailScreen(odlId: s.pathParameters['userId']!), s)),
        ],
      ),
    ],
  );
});

CustomTransitionPage _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 50),
  );
}