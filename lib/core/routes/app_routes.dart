abstract class Routes {
  Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const otp = '/otp';
  static const permissionsSetup = '/permissions-setup';
  static const permissionError = '/permission-error';
  static const dashboard = '/dashboard';
  // Deep-push screens (above dashboard)
  static const reports = '/reports';
  static const exportReports = '/export-reports';
  static const settings = '/settings';
  static const logout = '/logout';
  static const logoutConfirm = '/logout-confirm';
}
