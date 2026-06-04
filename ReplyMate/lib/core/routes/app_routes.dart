abstract class Routes {
  Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';

  static const dashboard = '/dashboard';
  static const reports = '/reports';
  static const exportReports = '/export-reports';
  static const settings = '/settings';
  static const privacyPolicy = '/privacy-policy';
  static const helpSupport = '/help-support';
  static const logout = '/logout';
  static const logoutConfirm = '/logout-confirm';

  // Subscription status screens
  static const pendingApproval = '/pending-approval';
  static const subscriptionExpired = '/subscription-expired';
  static const accountBlocked = '/account-blocked';
  
  static const notifications = '/notifications';
}
