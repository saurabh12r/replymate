import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'scheduled_messages_controller.dart';
import 'scheduled_message_models.dart';
import 'package:uuid/uuid.dart';

class ScheduleMessageFormView extends StatefulWidget {
  const ScheduleMessageFormView({super.key});

  @override
  State<ScheduleMessageFormView> createState() => _ScheduleMessageFormViewState();
}

class _ScheduleMessageFormViewState extends State<ScheduleMessageFormView> {
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  @override
  void dispose() {
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }


  void _save() {
    if (_phoneCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a phone number', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a message', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      Get.snackbar('Error', 'Please select both date and time', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final scheduledTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledTime.isBefore(DateTime.now())) {
      Get.snackbar('Error', 'Cannot schedule a message in the past', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final msg = ScheduledMessage(
      id: const Uuid().v4(),
      phoneNumber: _phoneCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      scheduledTime: scheduledTime,
    );

    Get.find<ScheduledMessagesController>().addMessage(msg);
    Get.back();
    Get.snackbar('Success', 'Message scheduled successfully', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _selectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_selectedDate!);
    final timeStr = _selectedTime == null ? 'Select Time' : _selectedTime!.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Schedule', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+1 234 567 8900',
                prefixIcon: const Icon(Icons.phone_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Message', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Schedule For', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withAlpha(100)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(dateStr, style: GoogleFonts.inter(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withAlpha(100)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(timeStr, style: GoogleFonts.inter(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Schedule Message', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
