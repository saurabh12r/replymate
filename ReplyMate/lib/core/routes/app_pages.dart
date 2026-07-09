import 'package:get/get.dart';
import '../../features/splash/splash_view.dart';
import '../../features/splash/splash_binding.dart';
import '../../features/login/login_view.dart';
import '../../features/login/login_binding.dart';
import '../../features/signup/signup_view.dart';
import '../../features/signup/signup_binding.dart';
import '../../features/otp/otp_view.dart';
import '../../features/otp/otp_binding.dart';

import '../../features/dashboard_nav/dashboard_nav_view.dart';
import '../../features/dashboard_nav/dashboard_nav_binding.dart';
import '../../features/reports/reports_view.dart';
import '../../features/reports/reports_binding.dart';
import '../../features/export/export_view.dart';
import '../../features/export/export_binding.dart';
import '../../features/settings/settings_view.dart';
import '../../features/settings/settings_binding.dart';
import '../../features/privacy_policy/privacy_policy_view.dart';
import '../../features/help_support/help_support_view.dart';
import '../../features/logout/logout_view.dart';
import '../../features/logout/logout_binding.dart';
import '../../features/subscription/subscription_status_views.dart';
import '../../features/notifications/notifications_view.dart';
import '../../features/notifications/notifications_binding.dart';
import '../../features/permissions/permissions_view.dart';
import '../../features/permissions/permissions_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.signup,
      page: () => const SignupView(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.otp,
      page: () => const OtpView(),
      binding: OtpBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // Dashboard entry point — DashboardNavView owns bottom nav + IndexedStack
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardNavView(),
      binding: DashboardNavBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    // Reports Summary — pushed from Analytics tab
    GetPage(
      name: Routes.reports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Export Reports — pushed from Reports Summary
    GetPage(
      name: Routes.exportReports,
      page: () => const ExportView(),
      binding: ExportBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Settings — pushed from Profile tab
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Privacy Policy — pushed from Profile tab
    GetPage(
      name: Routes.privacyPolicy,
      page: () => const PrivacyPolicyView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Help & Support — pushed from Profile tab
    GetPage(
      name: Routes.helpSupport,
      page: () => const HelpSupportView(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    // Logout Confirmation — from Settings or Profile
    GetPage(
      name: Routes.logout,
      page: () => const LogoutView(),
      binding: LogoutBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 350),
    ),
    // Alias: logoutConfirm → same view
    GetPage(
      name: Routes.logoutConfirm,
      page: () => const LogoutView(),
      binding: LogoutBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 350),
    ),

    // ── Subscription status screens ──────────────────────────────────────────
    GetPage(
      name: Routes.pendingApproval,
      page: () => const PendingApprovalView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.subscriptionExpired,
      page: () => const SubscriptionExpiredView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.accountBlocked,
      page: () => const AccountBlockedView(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: Routes.permissions,
      page: () => const PermissionsView(),
      binding: PermissionsBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
  ];
}
