/// Application-wide constants for admin_broker
class AppConstants {
  AppConstants._();

  // Firestore collections
  static const String usersCollection = 'admin_users';        // Admin & Broker portal accounts
  static const String replymetUsersCollection = 'users';       // ReplyMet end-users (existing collection)
  static const String plansCollection = 'plans';
  static const String brokersCollection = 'brokers';
  static const String approvalsCollection = 'approvals';
  static const String logsCollection = 'activity_logs';
  static const String dailyStatsCollection = 'daily_stats';
  static const String monthlyStatsCollection = 'monthly_stats';
  static const String userStatsCollection = 'user_stats';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleBroker = 'broker';

  // User statuses
  static const String statusPending = 'pending';
  static const String statusActive = 'active';
  static const String statusExpired = 'expired';
  static const String statusSuspended = 'suspended';

  // Approval roles
  static const String approvedByAdmin = 'admin';
  static const String approvedByBroker = 'broker';

  // Pagination
  static const int pageSize = 20;

  // Date formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // Broker code prefix
  static const String brokerCodePrefix = 'BRK';

  // Sidebar width
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 72.0;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
}
