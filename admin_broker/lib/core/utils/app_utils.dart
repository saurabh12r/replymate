import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class AppUtils {
  AppUtils._();

  static const _uuid = Uuid();

  /// Generate a unique ID
  static String generateId() => _uuid.v4();

  /// Generate a broker code
  static String generateBrokerCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return '${AppConstants.brokerCodePrefix}$timestamp';
  }

  /// Format date
  static String formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// Format date with time
  static String formatDateTime(DateTime? date) {
    if (date == null) return '—';
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return '₹${NumberFormat('#,##,##0.00').format(amount)}';
  }

  /// Format compact number
  static String formatCompact(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  /// Calculate subscription end date from start + plan duration
  static DateTime calculateEndDate(DateTime startDate, int durationDays) {
    return startDate.add(Duration(days: durationDays));
  }

  /// Check if subscription is expiring soon (within 7 days)
  static bool isExpiringSoon(DateTime? endDate) {
    if (endDate == null) return false;
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  /// Check if subscription is expired
  static bool isExpired(DateTime? endDate) {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate);
  }

  /// Calculate broker commission from plan price
  static double calculateBrokerCommission(double planPrice, double commissionPercent) {
    return planPrice * commissionPercent / 100;
  }

  /// Calculate admin revenue after broker commission
  static double calculateAdminRevenue(double planPrice, double brokerCommission) {
    return planPrice - brokerCommission;
  }

  /// Convert Firestore timestamp to DateTime
  static DateTime? timestampToDate(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    try {
      return timestamp.toDate();
    } catch (_) {
      return null;
    }
  }

  /// Get days remaining string
  static String getDaysRemaining(DateTime? endDate) {
    if (endDate == null) return 'N/A';
    final diff = endDate.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    return '$diff days left';
  }

  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validate phone
  static bool isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone.replaceAll(' ', ''));
  }

  /// Format relative time (e.g., "2 minutes ago", "1 hour ago")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} week${(diff.inDays / 7).floor() > 1 ? 's' : ''} ago';
    } else {
      return formatDate(date);
    }
  }
}
