import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/activity/activity_log.dart';
import '../../core/activity/activity_log_service.dart';
import '../../core/activity/event_type.dart';
import '../../core/contact_filter/contact_filter_phone_normalize.dart';

class ActivityLogHistoryView extends StatelessWidget {
  final String phoneNumber;
  final String name;

  const ActivityLogHistoryView({
    super.key,
    required this.phoneNumber,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetDigits = contactFilterNormalizeRawToCanonical(phoneNumber);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contact History',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ValueListenableBuilder<Box<ActivityLog>>(
        valueListenable: ActivityLogService.instance.box.listenable(),
        builder: (context, box, _) {
          final matchingLogs = box.values
              .where((e) {
                final digits = contactFilterNormalizeRawToCanonical(e.phoneNumber);
                return digits == targetDigits && e.type != EventType.scheduledSms;
              })
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (matchingLogs.isEmpty) {
            return Center(
              child: Text(
                'No activity logs found for this number.',
                style: GoogleFonts.inter(),
              ),
            );
          }

          // Count type frequencies
          var missed = 0;
          var answeredIncoming = 0;
          var outgoing = 0;
          var rejected = 0;

          for (final log in matchingLogs) {
            switch (log.type) {
              case EventType.incomingCall:
                answeredIncoming++;
                break;
              case EventType.missedCall:
                missed++;
                break;
              case EventType.outgoingAnswered:
              case EventType.outgoingUnanswered:
                outgoing++;
                break;
              case EventType.rejectedCall:
              case EventType.busyCall:
                rejected++;
                break;
              case EventType.whatsappCall:
                answeredIncoming++;
                break;
              case EventType.scheduledSms:
                break;
            }
          }

          final displayName = name.isNotEmpty
              ? name
              : (matchingLogs.first.name.isNotEmpty
                  ? matchingLogs.first.name
                  : 'Unknown Number');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Info Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withAlpha(20),
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phoneNumber,
                            style: GoogleFonts.inter(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Missed', missed, Colors.red, Icons.phone_missed_rounded),
                      _buildStatItem('Answered', answeredIncoming, Colors.green, Icons.call_received_rounded),
                      _buildStatItem('Outgoing', outgoing, Colors.blue, Icons.call_made_rounded),
                      _buildStatItem('Rejected', rejected, Colors.orange, Icons.phone_disabled_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Call Log History',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Call logs list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: matchingLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = matchingLogs[index];
                    final dateStr = DateFormat('MMM d, yyyy').format(log.timestamp.toLocal());
                    final timeStr = DateFormat('h:mm:ss a').format(log.timestamp.toLocal());

                    Color typeColor;
                    IconData typeIcon;
                    String label;

                    switch (log.type) {
                      case EventType.incomingCall:
                        typeColor = theme.colorScheme.primary;
                        typeIcon = Icons.call_received_rounded;
                        label = 'Incoming Call';
                        break;
                      case EventType.missedCall:
                        typeColor = theme.colorScheme.error;
                        typeIcon = Icons.call_missed_rounded;
                        label = 'Missed Call';
                        break;
                      case EventType.whatsappCall:
                        typeColor = const Color(0xFF25D366);
                        typeIcon = Icons.chat_rounded;
                        label = 'WhatsApp Call';
                        break;
                      case EventType.busyCall:
                        typeColor = const Color(0xFFE65100);
                        typeIcon = Icons.phone_in_talk_rounded;
                        label = 'Busy Call';
                        break;
                      case EventType.rejectedCall:
                        typeColor = const Color(0xFFD32F2F);
                        typeIcon = Icons.phone_disabled_rounded;
                        label = 'Rejected Call';
                        break;
                      case EventType.outgoingAnswered:
                        typeColor = const Color(0xFF1565C0);
                        typeIcon = Icons.call_made_rounded;
                        label = 'Outgoing (Answered)';
                        break;
                      case EventType.outgoingUnanswered:
                        typeColor = const Color(0xFF6A1B9A);
                        typeIcon = Icons.phone_missed_rounded;
                        label = 'Outgoing (No Answer)';
                        break;
                      case EventType.scheduledSms:
                        typeColor = Colors.orange;
                        typeIcon = Icons.schedule_rounded;
                        label = 'Scheduled SMS';
                        break;
                    }

                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withAlpha(40),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: typeColor.withAlpha(20),
                                  child: Icon(typeIcon, size: 14, color: typeColor),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      log.replied ? 'Auto-replied' : 'No reply',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: log.replied ? Colors.green.shade700 : theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (log.messageSent.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log.messageSent,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
