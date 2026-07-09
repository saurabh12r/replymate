import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scheduled_messages_controller.dart';
import 'schedule_message_form_view.dart';
import 'scheduled_message_detail_view.dart';
import 'package:intl/intl.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/activity/event_type.dart';

class ScheduledMessagesView extends StatelessWidget {
  const ScheduledMessagesView({super.key});

  bool _isMessageSent(String msgId) {
    if (!ActivityLogService.instance.isBoxReady) return false;
    return ActivityLogService.instance.box.values.any(
      (l) => l.type == EventType.scheduledSms && l.id.startsWith(msgId) && l.replied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduledMessagesController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scheduled Messages',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 80,
                  color: theme.colorScheme.primary.withAlpha(50),
                ),
                const SizedBox(height: 16),
                Text(
                  'No scheduled messages',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to schedule one.',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final msg = controller.messages[index];
            final dateStr = DateFormat(
              'MMM d, yyyy - h:mm a',
            ).format(msg.scheduledTime);
            final isPast = msg.scheduledTime.isBefore(DateTime.now());

            return GestureDetector(
              onTap: () => Get.to(() => ScheduledMessageDetailView(message: msg)),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.label_important_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg.title.isNotEmpty ? msg.title : '(No Title)',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isPast)
                            Builder(
                              builder: (context) {
                                final sent = _isMessageSent(msg.id);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sent
                                        ? Colors.green.withAlpha(40)
                                        : Colors.red.withAlpha(40),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    sent ? 'Sent' : 'Failed',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: sent
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            GestureDetector(
                              onTap: () {
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
                                          controller.removeMessage(msg.id);
                                          Get.back();
                                          Get.snackbar(
                                            'Deleted',
                                            'Scheduled message cancelled successfully',
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        },
                                        child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: theme.colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        msg.message,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const ScheduleMessageFormView()),
        icon: const Icon(Icons.add),
        label: Text(
          'New Schedule',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
