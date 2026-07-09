import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/permissions/permission_service.dart';
import 'permissions_controller.dart';

class PermissionsView extends GetView<PermissionsController> {
  const PermissionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Permissions',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading Info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.security_rounded,
                              size: 48,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Permissions Setup',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ReplyMate needs these permissions to run call auto-replies and background sms services successfully.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Permissions Checklist Cards
                    Obx(() => Column(
                          children: [
                            _buildPermissionCard(
                              context: context,
                              icon: Icons.sms_rounded,
                              title: 'SMS Permission',
                              description: 'Required to automatically send template responses.',
                              isGranted: controller.smsGranted.value,
                              onRequest: () => controller.requestPermission(AppPermissionType.sms),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard(
                              context: context,
                              icon: Icons.phone_android_rounded,
                              title: 'Phone & Call Logs',
                              description: 'Detects incoming calls to trigger auto-reply engines.',
                              isGranted: controller.callLogsGranted.value,
                              onRequest: () => controller.requestPermission(AppPermissionType.callLogs),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard(
                              context: context,
                              icon: Icons.contacts_rounded,
                              title: 'Contacts Permission',
                              description: 'Checks filters and contact settings policies.',
                              isGranted: controller.contactsGranted.value,
                              onRequest: () => controller.requestPermission(AppPermissionType.contacts),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard(
                              context: context,
                              icon: Icons.notifications_active_rounded,
                              title: 'Notifications Permission',
                              description: 'Shows status alerts and foreground logs activity.',
                              isGranted: controller.notificationsGranted.value,
                              onRequest: () => controller.requestPermission(AppPermissionType.notifications),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard(
                              context: context,
                              icon: Icons.battery_saver_rounded,
                              title: 'Ignore Battery Optimizations',
                              description: 'Ensures the OS does not kill auto-replies in the background.',
                              isGranted: controller.batteryOptimizationGranted.value,
                              onRequest: controller.requestBatteryOptimization,
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),

            // Navigation Actions Deck
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withAlpha(80),
                  ),
                ),
              ),
              child: Obx(() {
                final allOk = controller.areAllPermissionsGranted;
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.goToDashboard,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: cs.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          allOk ? 'Dashboard' : 'Skip Setup',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.goToDashboard,
                        style: FilledButton.styleFrom(
                          backgroundColor: allOk ? cs.primary : cs.secondary.withAlpha(120),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: allOk ? Colors.white : Colors.white.withAlpha(200),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGranted ? Colors.green.withAlpha(60) : cs.outlineVariant.withAlpha(60),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isGranted ? Colors.green.withAlpha(20) : cs.primary.withAlpha(15),
            child: Icon(
              icon,
              size: 20,
              color: isGranted ? Colors.green.shade700 : cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isGranted ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGranted ? Icons.check_circle_rounded : Icons.warning_rounded,
                            size: 12,
                            color: isGranted ? Colors.green.shade700 : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGranted ? 'Granted' : 'Required',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isGranted ? Colors.green.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!isGranted)
                      TextButton(
                        onPressed: onRequest,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Grant',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: cs.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
