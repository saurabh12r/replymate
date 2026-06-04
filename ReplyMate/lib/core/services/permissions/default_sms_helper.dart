import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reply_mate/core/services/auto_reply/auto_reply_bridge.dart';

class DefaultSmsHelper {
  static final AutoReplyBridge _bridge = AutoReplyBridge();

  /// Requests the user to set the app as the default SMS handler,
  /// with a preliminary explanation dialog and proper edge-case handling.
  static Future<bool> requestDefaultSmsAppWithDialog() async {
    // 1. Edge Case: Check if already the default app silently.
    final isAlreadyDefault = await _bridge.isDefaultSmsApp();
    if (isAlreadyDefault) {
      // Already default, just ensure standard SMS permissions are granted.
      return await _ensureSmsPermissions();
    }

    // 2. UX: Show explanation before triggering native intent.
    final userAccepted = await Get.defaultDialog<bool>(
      title: 'Default SMS App',
      middleText:
          'To enable auto-reply and advanced SMS features, this app needs to be set as your default SMS handler.\n\nWould you like to proceed?',
      textConfirm: 'Proceed',
      confirmTextColor: Colors.white,
      textCancel: 'Cancel',
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
      barrierDismissible: false,
    );

    if (userAccepted != true) {
      _showCancellationMessage();
      return false;
    }

    try {
      // 3. Trigger native intent.
      final success = await _bridge.requestDefaultSmsApp();

      if (success) {
        // 4. Ensure SMS permissions after becoming default
        return await _ensureSmsPermissions();
      } else {
        _showCancellationMessage();
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not complete request: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withAlpha(204),
        colorText: Colors.white,
      );
      return false;
    }
  }

  static Future<bool> _ensureSmsPermissions() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      Get.snackbar(
        'Success',
        'App is set as default SMS handler and permissions granted.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withAlpha(204),
        colorText: Colors.white,
      );
      return true;
    } else {
      if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Settings Required',
          'SMS permission is permanently denied. Opening settings...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withAlpha(204),
          colorText: Colors.white,
        );
        await Future.delayed(const Duration(seconds: 2));
        await openAppSettings();
      } else {
        Get.snackbar(
          'Permissions Needed',
          'Please grant SMS permissions to use messaging features.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withAlpha(204),
          colorText: Colors.white,
        );
      }
      return false;
    }
  }

  static void _showCancellationMessage() {
    Get.snackbar(
      'Action Required',
      'SMS features will not work until this app is set as the default SMS app.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withAlpha(204),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      isDismissible: true,
    );
  }
}
