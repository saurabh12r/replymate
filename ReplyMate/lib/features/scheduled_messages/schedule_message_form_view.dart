import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'scheduled_messages_controller.dart';
import 'scheduled_message_models.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../core/contact_filter/contact_filter_sms_policy.dart';
import '../../core/contact_filter/contact_filter_phone_normalize.dart';

enum RecipientMode { selectedContacts, contactControl }

class ScheduleMessageFormView extends StatefulWidget {
  const ScheduleMessageFormView({super.key});

  @override
  State<ScheduleMessageFormView> createState() =>
      _ScheduleMessageFormViewState();
}

class _ScheduleMessageFormViewState extends State<ScheduleMessageFormView> {
  final _phoneCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  RecipientMode _recipientMode = RecipientMode.selectedContacts;
  final _selectedContactDigits = <String>{};
  List<_ContactPhoneRow> _allContacts = [];
  bool _loadingContacts = false;

  static const Color _primary = Color(0xFF24389C);

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _messageCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (_allContacts.isNotEmpty) return;
    setState(() => _loadingContacts = true);
    try {
      await FlutterContacts.permissions.request(PermissionType.read);
      final hasPermission = await FlutterContacts.permissions.has(
        PermissionType.read,
      );
      if (!hasPermission) {
        Get.snackbar(
          'Permission Required',
          'Please grant contacts permission',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _loadingContacts = false);
        return;
      }
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      if (contacts.isEmpty) {
        Get.snackbar(
          'No Contacts',
          'No contacts found on device',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      final rows = <_ContactPhoneRow>[];
      final seen = <String>{};
      for (final c in contacts) {
        for (final p in c.phones) {
          final digits = contactFilterNormalizeRawToCanonical(p.number);
          if (digits.length >= 10) {
            if (seen.contains(digits)) continue;
            seen.add(digits);
            rows.add(
              _ContactPhoneRow(
                displayName: c.displayName != null && c.displayName!.isNotEmpty
                    ? c.displayName!
                    : 'Unknown',
                phoneDisplay: p.number,
                digitsKey: digits,
              ),
            );
          }
        }
      }
      rows.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      _allContacts = rows;
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }
    setState(() => _loadingContacts = false);
  }

  void _toggleContact(_ContactPhoneRow contact) {
    setState(() {
      final digits = contact.digitsKey;
      if (_selectedContactDigits.contains(digits)) {
        _selectedContactDigits.remove(digits);
      } else {
        _selectedContactDigits.add(digits);
        if (!_allContacts.any((c) => c.digitsKey == digits)) {
          _allContacts.add(contact);
        }
      }
    });
  }

  void _showContactPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ContactPickerSheet(
        allContacts: _allContacts,
        selectedDigits: _selectedContactDigits,
        loading: _loadingContacts,
        onToggle: _toggleContact,
        onLoadContacts: _loadContacts,
        primary: _primary,
      ),
    );
  }

  List<String> _getSelectedPhoneNumbers() {
    return _allContacts
        .where((c) => _selectedContactDigits.contains(c.digitsKey))
        .map((c) => c.phoneDisplay)
        .toList();
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

  void _save() async {
    if (_messageCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a message',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      Get.snackbar(
        'Error',
        'Please select both date and time',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      Get.snackbar(
        'Error',
        'Cannot schedule a message in the past',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    List<String> targetNumbers = [];

    if (_recipientMode == RecipientMode.selectedContacts) {
      targetNumbers = _getSelectedPhoneNumbers();
      if (targetNumbers.isEmpty) {
        Get.snackbar(
          'Error',
          'Please select at least one contact',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } else {
      await FlutterContacts.permissions.request(PermissionType.read);
      if (!await FlutterContacts.permissions.has(PermissionType.read)) {
        Get.snackbar(
          'Error',
          'Contacts permission required to use contact settings',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      for (final c in contacts) {
        for (final p in c.phones) {
          if (ContactFilterSmsPolicy.instance.shouldSendSMS(p.number)) {
            targetNumbers.add(p.number);
          }
        }
      }
      targetNumbers = targetNumbers.toSet().toList(); // Remove duplicates

      Get.back(); // close dialog

      if (targetNumbers.isEmpty) {
        Get.snackbar(
          'Error',
          'No contacts match the Contact Control settings',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    if (targetNumbers.isEmpty) {
      Get.snackbar(
        'Error',
        'Please provide valid phone numbers',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final msgs = targetNumbers
        .map(
          (num) => ScheduledMessage(
            id: const Uuid().v4(),
            phoneNumber: num,
            message: _messageCtrl.text.trim(),
            scheduledTime: scheduledTime,
          ),
        )
        .toList();

    Get.find<ScheduledMessagesController>().addMessages(msgs);
    Get.back();
    Get.snackbar(
      'Success',
      '${msgs.length} message(s) scheduled successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _selectedDate == null
        ? 'Select Date'
        : DateFormat('MMM d, yyyy').format(_selectedDate!);
    final timeStr = _selectedTime == null
        ? 'Select Time'
        : _selectedTime!.format(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Schedule',
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
            Text(
              'Recipient',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(100),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  RadioListTile<RecipientMode>(
                    title: Text(
                      'Select specific contacts',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Choose contacts to send message to',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    value: RecipientMode.selectedContacts,
                    groupValue: _recipientMode,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _recipientMode = val);
                        _loadContacts();
                      }
                    },
                    activeColor: _primary,
                  ),
                  RadioListTile<RecipientMode>(
                    title: Text(
                      'Use Contact Control settings',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Applies your global auto-reply rules',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    value: RecipientMode.contactControl,
                    groupValue: _recipientMode,
                    onChanged: (val) {
                      if (val != null) setState(() => _recipientMode = val);
                    },
                    activeColor: _primary,
                  ),
                ],
              ),
            ),
            if (_recipientMode == RecipientMode.selectedContacts) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_rounded, color: _primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Contacts',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                          Text(
                            _loadingContacts
                                ? 'Loading contacts...'
                                : '${_selectedContactDigits.length} contact${_selectedContactDigits.length == 1 ? '' : 's'} selected',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _showContactPicker,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedContactDigits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _selectedContactDigits.length,
                    itemBuilder: (ctx, i) {
                      final contact = _allContacts.firstWhere(
                        (c) =>
                            c.digitsKey == _selectedContactDigits.toList()[i],
                        orElse: () => _ContactPhoneRow(
                          displayName: 'Unknown',
                          phoneDisplay: '',
                          digitsKey: '',
                        ),
                      );
                      if (contact.digitsKey.isEmpty)
                        return const SizedBox.shrink();
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: _primary.withAlpha(25),
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                        subtitle: Text(
                          contact.phoneDisplay,
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        trailing: GestureDetector(
                          onTap: () => _toggleContact(contact),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
            const SizedBox(height: 24),
            Text(
              'Message',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Schedule For',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(100),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withAlpha(100),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timeStr,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Schedule Message',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactPhoneRow {
  final String displayName;
  final String phoneDisplay;
  final String digitsKey;
  _ContactPhoneRow({
    required this.displayName,
    required this.phoneDisplay,
    required this.digitsKey,
  });
}

class _ContactPickerSheet extends StatefulWidget {
  final List<_ContactPhoneRow> allContacts;
  final Set<String> selectedDigits;
  final bool loading;
  final Function(_ContactPhoneRow) onToggle;
  final Future<void> Function() onLoadContacts;
  final Color primary;
  const _ContactPickerSheet({
    required this.allContacts,
    required this.selectedDigits,
    required this.loading,
    required this.onToggle,
    required this.onLoadContacts,
    required this.primary,
  });
  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  late TabController _tabController;
  List<_ContactPhoneRow> _callLogContacts = [];
  bool _loadingCallLog = false;

  List<_ContactPhoneRow> get _filteredContacts {
    if (_query.isEmpty) return widget.allContacts;
    final q = _query.toLowerCase();
    return widget.allContacts
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(q) ||
              c.phoneDisplay.contains(q) ||
              c.digitsKey.contains(q),
        )
        .toList();
  }

  List<_ContactPhoneRow> get _filteredCallLog {
    if (_query.isEmpty) return _callLogContacts;
    final q = _query.toLowerCase();
    return _callLogContacts
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(q) ||
              c.phoneDisplay.contains(q) ||
              c.digitsKey.contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.onLoadContacts();
    _loadCallLog();
  }

  Future<void> _loadCallLog() async {
    setState(() => _loadingCallLog = true);
    try {
      const platform = MethodChannel('replymate/call_log');
      final isGranted = await platform.invokeMethod<bool>('requestCallLogPermission');
      if (isGranted != true) {
        Get.snackbar(
          'Permission Required',
          'Call log permission is required to access your call log.',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _loadingCallLog = false);
        return;
      }
      final result = await platform.invokeMethod<List<dynamic>>(
        'getRecentCalls',
      );
      if (result != null) {
        final seen = <String>{};
        final rows = <_ContactPhoneRow>[];
        for (final item in result) {
          final map = Map<String, dynamic>.from(item);
          final number = map['number'] as String?;
          if (number == null || number.isEmpty) continue;
          final digits = contactFilterNormalizeRawToCanonical(number);
          if (digits.length < 10) continue;
          if (seen.contains(digits)) continue;
          seen.add(digits);
          rows.add(
            _ContactPhoneRow(
              displayName: map['name'] as String? ?? number,
              phoneDisplay: number,
              digitsKey: digits,
            ),
          );
        }
        _callLogContacts = rows;
      }
    } catch (e) {
      debugPrint('Error loading call log: $e');
    }
    setState(() => _loadingCallLog = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Contacts',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: widget.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: widget.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: widget.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: const [
                Tab(text: 'Contacts'),
                Tab(text: 'Call Log'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildContactsList(), _buildCallLogList()],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Done (${widget.selectedDigits.length} selected)',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    final theme = Theme.of(context);
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Text(
          _query.isEmpty ? 'No contacts available' : 'No contacts found',
          style: GoogleFonts.manrope(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = widget.selectedDigits.contains(contact.digitsKey);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? widget.primary
                  : theme.colorScheme.outlineVariant.withAlpha(50),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              widget.onToggle(contact);
              setState(() {});
            },
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? widget.primary
                  : widget.primary.withAlpha(25),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.person_rounded,
                color: isSelected ? Colors.white : widget.primary,
                size: 20,
              ),
            ),
            title: Text(
              contact.displayName,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              contact.phoneDisplay,
              style: GoogleFonts.inter(fontSize: 13),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: widget.primary)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCallLogList() {
    final theme = Theme.of(context);
    if (_loadingCallLog) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredCallLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              _query.isEmpty ? 'No recent calls' : 'No calls found',
              style: GoogleFonts.manrope(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredCallLog.length,
      itemBuilder: (context, index) {
        final contact = _filteredCallLog[index];
        final isSelected = widget.selectedDigits.contains(contact.digitsKey);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? widget.primary
                  : theme.colorScheme.outlineVariant.withAlpha(50),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            onTap: () {
              widget.onToggle(contact);
              setState(() {});
            },
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? widget.primary
                  : widget.primary.withAlpha(25),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.phone_rounded,
                color: isSelected ? Colors.white : widget.primary,
                size: 20,
              ),
            ),
            title: Text(
              contact.displayName,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              contact.phoneDisplay,
              style: GoogleFonts.inter(fontSize: 13),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: widget.primary)
                : null,
          ),
        );
      },
    );
  }
}
