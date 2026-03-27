import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum AppPermissionType {
  sms,
  callLogs,
  contacts,
  notifications,
}

class PermissionService {
  Future<bool> isGranted(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.sms:
        return _isSmsGranted();
      case AppPermissionType.callLogs:
        return _isCallLogsGranted();
      case AppPermissionType.contacts:
        return Permission.contacts.isGranted;
      case AppPermissionType.notifications:
        return _isNotificationPermissionGranted();
    }
  }

  Future<PermissionStatus> request(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.sms:
        return _requestSmsPermissions();
      case AppPermissionType.callLogs:
        return _requestCallLogPermissions();
      case AppPermissionType.contacts:
        return Permission.contacts.request();
      case AppPermissionType.notifications:
        return _requestNotificationPermission();
    }
  }

  Future<bool> isPermanentlyDenied(AppPermissionType type) async {
    switch (type) {
      case AppPermissionType.sms:
        return Permission.sms.isPermanentlyDenied;
      case AppPermissionType.callLogs:
        return await Permission.phone.isPermanentlyDenied;
      case AppPermissionType.contacts:
        return Permission.contacts.isPermanentlyDenied;
      case AppPermissionType.notifications:
        if (!Platform.isAndroid) return false;
        return Permission.notification.isPermanentlyDenied;
    }
  }

  Future<bool> checkAllPermissions() async {
    final sms = await isGranted(AppPermissionType.sms);
    final callLogs = await isGranted(AppPermissionType.callLogs);
    final contacts = await isGranted(AppPermissionType.contacts);
    final notifications = await isGranted(AppPermissionType.notifications);
    return sms && callLogs && contacts && notifications;
  }

  Future<bool> _isSmsGranted() async {
    return Permission.sms.isGranted;
  }

  Future<bool> _isCallLogsGranted() async {
    final readCallLogs = await Permission.phone.isGranted;
    final phoneState = await Permission.phone.isGranted;
    return readCallLogs && phoneState;
  }

  Future<PermissionStatus> _requestSmsPermissions() async {
    return Permission.sms.request();
  }

  Future<PermissionStatus> _requestCallLogPermissions() async {
    final phoneStatus = await Permission.phone.request();
    if (phoneStatus.isGranted) return PermissionStatus.granted;
    if (phoneStatus.isPermanentlyDenied) {
      return PermissionStatus.permanentlyDenied;
    }
    return PermissionStatus.denied;
  }

  Future<bool> _isNotificationPermissionGranted() async {
    if (!Platform.isAndroid) return true;
    return Permission.notification.isGranted;
  }

  Future<PermissionStatus> _requestNotificationPermission() async {
    if (!Platform.isAndroid) return PermissionStatus.granted;
    return Permission.notification.request();
  }
}
