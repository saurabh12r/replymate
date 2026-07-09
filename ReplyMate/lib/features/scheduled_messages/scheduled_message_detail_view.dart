import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/contact_filter/contact_filter_phone_normalize.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/activity/event_type.dart';
import 'scheduled_message_models.dart';
import 'scheduled_messages_controller.dart';
import 'schedule_message_form_view.dart';

class ScheduledMessageDetailView extends StatefulWidget {
  final ScheduledMessage message;
  const ScheduledMessageDetailView({super.key, required this.message});

  @override
  State<ScheduledMessageDetailView> createState() => _ScheduledMessageDetailViewState();
}

class _ScheduledMessageDetailViewState extends State<ScheduledMessageDetailView> {
  final Map<String, String> _contactNames = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final hasPerm = await FlutterContacts.permissions.has(PermissionType.read);
      if (!hasPerm) {
        await FlutterContacts.permissions.request(PermissionType.read);
        final stillHasPerm = await FlutterContacts.permissions.has(PermissionType.read);
        if (!stillHasPerm) return;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final map = <String, String>{};
      for (final c in contacts) {
        final name = c.displayName?.trim() ?? '';
        if (name.isEmpty) continue;
        for (final p in c.phones) {
          final digits = contactFilterNormalizeRawToCanonical(p.number);
          if (digits.isNotEmpty) {
            map[digits] = name;
          }
        }
      }
      if (mounted) {
        setState(() {
          _contactNames.addAll(map);
        });
      }
    } catch (_) {}
  }

  bool _isMessageSent(String msgId) {
    if (!ActivityLogService.instance.isBoxReady) return false;
    return ActivityLogService.instance.box.values.any(
      (l) => l.type == EventType.scheduledSms && l.id.startsWith(msgId) && l.replied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<ScheduledMessagesController>();
    final isPast = widget.message.scheduledTime.isBefore(DateTime.now());
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(widget.message.scheduledTime);
    final timeStr = DateFormat('h:mm a').format(widget.message.scheduledTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Schedule Details',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Builder(
              builder: (context) {
                final sent = isPast ? _isMessageSent(widget.message.id) : false;
                final statusColor = !isPast 
                    ? theme.colorScheme.primary 
                    : (sent ? Colors.green : Colors.red);
                final statusBgColor = !isPast
                    ? theme.colorScheme.primary.withAlpha(20)
                    : (sent ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20));
                final statusBorderColor = !isPast
                    ? theme.colorScheme.primary.withAlpha(80)
                    : (sent ? Colors.green.withAlpha(80) : Colors.red.withAlpha(80));
                
                final statusTitle = !isPast
                    ? 'Scheduled'
                    : (sent ? 'Sent' : 'Failed');
                final statusSubtitle = !isPast
                    ? 'Upcoming message queued for delivery'
                    : (sent ? 'This message was successfully dispatched' : 'This message failed to send or auto-reply was disabled');
                final statusIcon = !isPast
                    ? Icons.schedule_rounded
                    : (sent ? Icons.check_circle_rounded : Icons.cancel_rounded);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusBorderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusTitle,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: !isPast 
                                    ? theme.colorScheme.primary 
                                    : (sent ? Colors.green.shade900 : Colors.red.shade900),
                              ),
                            ),
                            Text(
                              statusSubtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title section
            Text(
              'Title',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.message.title.isNotEmpty ? widget.message.title : '(No Title)',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),

            // Message text section
            Text(
              'Message Content',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
              ),
              child: Text(
                widget.message.message,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.4,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Time & Date section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recipients list
            Text(
              'Recipients (${widget.message.phoneNumbers.length})',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.message.phoneNumbers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final phone = widget.message.phoneNumbers[index];
                  final canonical = contactFilterNormalizeRawToCanonical(phone);
                  final name = _contactNames[canonical];
                  final hasName = name != null && name.isNotEmpty;

                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: theme.colorScheme.secondary.withAlpha(20),
                      child: Icon(
                        Icons.phone_rounded,
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(
                      hasName ? name : phone,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: hasName
                        ? Text(
                            phone,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (!isPast) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            title: const Text('Delete Schedule'),
                            content: const Text('Are you sure you want to cancel and delete this scheduled message?'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Keep'),
                              ),
                              TextButton(
                                onPressed: () {
                                  controller.removeMessage(widget.message.id);
                                  Get.back(); // close dialog
                                  Get.back(); // return to list screen
                                  Get.snackbar(
                                    'Deleted',
                                    'Scheduled message successfully deleted',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                },
                                child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Get.to(() => ScheduleMessageFormView(messageToEdit: widget.message));
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Schedule'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
