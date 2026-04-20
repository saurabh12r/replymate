import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/stores/reply_store_models.dart';
import 'stores_controller.dart';

class StoreEditView extends StatefulWidget {
  const StoreEditView({
    super.key,
    required this.store,
    this.isNew = false,
  });

  final ReplyStore store;

  /// When true, [store] is not yet in persisted list; [Save] appends it.
  final bool isNew;

  @override
  State<StoreEditView> createState() => _StoreEditViewState();
}

class _StoreEditViewState extends State<StoreEditView> {
  late TextEditingController _nameCtrl;
  late Map<String, TextEditingController> _msgCtrls;
  late Map<String, String> _eventTemplateIds;
  late bool _active;
  late bool _tMissed;
  late bool _tIncoming;
  late bool _tWa;
  late bool _tBusy;
  late bool _tRejected;
  late bool _tOutAns;
  late bool _tOutUnans;
  late bool _enableDaysSetup;
  late List<int> _selectedDays;
  late bool _vacationMode;
  late TextEditingController _vacationMsgCtrl;
  int? _subscriptionId;
  final Set<String> _groupKeys = {};
  final TextEditingController _groupTextCtrl = TextEditingController();
  String? _imagePath; // local file path for the business image

  StoresController get _c => Get.find<StoresController>();

  static const Color _primary = Color(0xFF24389C);
  static const Color _success = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _nameCtrl = TextEditingController(text: s.name);
    _eventTemplateIds = Map<String, String>.from(s.eventTemplateIds);
    _active = s.active;
    _tMissed = s.replyMissedCall;
    _tIncoming = s.replyIncomingCall;
    _tWa = s.replyWhatsappCall;
    _tBusy = s.replyBusyCall;
    _tRejected = s.replyRejectedCall;
    _tOutAns = s.replyOutgoingAnswered;
    _tOutUnans = s.replyOutgoingUnanswered;
    _enableDaysSetup = s.enableDaysSetup;
    _selectedDays = List<int>.from(s.selectedDays);
    _vacationMode = s.vacationMode;
    _vacationMsgCtrl = TextEditingController(text: s.vacationMessage);
    _subscriptionId = s.subscriptionId;
    _imagePath = s.imagePath;
    _msgCtrls = {
      for (final k in ReplyStoreEventKeys.all)
        k: TextEditingController(text: s.messageForEventKey(k) ?? ''),
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vacationMsgCtrl.dispose();
    for (final c in _msgCtrls.values) {
      c.dispose();
    }
    _groupTextCtrl.dispose();
    super.dispose();
  }

  void _applyGroupMessage() {
    final text = _groupTextCtrl.text.trim();
    if (text.isEmpty || _groupKeys.isEmpty) {
      Get.snackbar('Select types', 'Choose at least one type and enter a message.');
      return;
    }
    final newId = StoresController.generateId();
    setState(() {
      for (final k in _groupKeys) {
        _eventTemplateIds[k] = newId;
        _msgCtrls[k]!.text = text;
      }
    });
    Get.snackbar('Applied', 'Message linked to selected types.');
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: _primary),
                title: Text('Choose from gallery', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: _primary),
                title: Text('Take a photo', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: Text('Remove image', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _saved = false;

  Future<void> _save({bool pop = true}) async {
    if (_saved) return;
    _saved = true;
    final infos = _c.subscriptionInfos;
    int? sid = _subscriptionId;
    if (sid != null &&
        !infos.any((e) => e['subscriptionId'] == sid)) {
      sid = null;
    }

    final templateTexts = <String, String>{};
    for (final k in ReplyStoreEventKeys.all) {
      final tid = _eventTemplateIds[k];
      if (tid == null || tid.isEmpty) continue;
      templateTexts[tid] = _msgCtrls[k]!.text.trim();
    }
    final templates = templateTexts.entries
        .map((e) => ReplyTemplate(id: e.key, text: e.value))
        .toList();

    String? conflict;
    final others = _c.stores.where((x) => x.id != widget.store.id).toList();
    if (sid != null) {
      for (final o in others) {
        if (o.subscriptionId == sid) {
          conflict = o.name;
          break;
        }
      }
    }

    final updatedOthers = others.map((o) {
      if (sid != null && o.subscriptionId == sid) {
        return o.copyWith(clearSubscriptionId: true);
      }
      return o;
    }).toList();

    final updated = ReplyStore(
      id: widget.store.id,
      name: _nameCtrl.text.trim().isEmpty ? 'Business' : _nameCtrl.text.trim(),
      subscriptionId: sid,
      active: _active,
      replyMissedCall: _tMissed,
      replyIncomingCall: _tIncoming,
      replyWhatsappCall: _tWa,
      replyBusyCall: _tBusy,
      replyRejectedCall: _tRejected,
      replyOutgoingAnswered: _tOutAns,
      replyOutgoingUnanswered: _tOutUnans,
      enableDaysSetup: _enableDaysSetup,
      selectedDays: _selectedDays,
      vacationMode: _vacationMode,
      vacationMessage: _vacationMsgCtrl.text.trim(),
      templates: templates,
      eventTemplateIds: Map<String, String>.from(_eventTemplateIds),
      imagePath: _imagePath,
    );

    final byId = <String, ReplyStore>{for (final s in _c.stores) s.id: s};
    for (final o in updatedOthers) {
      byId[o.id] = o;
    }
    byId[updated.id] = updated;
    final List<ReplyStore> ordered;
    if (widget.isNew) {
      ordered = [
        ..._c.stores.map((s) => byId[s.id] ?? s),
        updated,
      ];
    } else {
      ordered = _c.stores.map((s) => byId[s.id] ?? s).toList();
    }

    await _c.saveAll(ordered, reassignedFromStoreName: conflict);
    if (pop && mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        _save(pop: false);
      },
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          widget.isNew ? 'Add business' : 'Edit business',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel(context, 'Business'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Column(
              children: [
                // ── Business image (optional) ──────────────────────────
                GestureDetector(
                  onTap: _showImagePickerSheet,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    height: _imagePath != null ? 160 : 72,
                    decoration: BoxDecoration(
                      color: _imagePath != null
                          ? Colors.transparent
                          : _primary.withAlpha(14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _primary.withAlpha(_imagePath != null ? 60 : 40),
                        width: 1.5,
                      ),
                    ),
                    child: _imagePath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_rounded,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: _showImagePickerSheet,
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  color: _primary.withAlpha(180), size: 28),
                              const SizedBox(height: 6),
                              Text(
                                'Add business image (optional)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _primary.withAlpha(160),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Business name ─────────────────────────────────────
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Business name',
                    prefixIcon: const Icon(Icons.storefront_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(90)),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.power_settings_new_rounded),
                    title: Text('Active', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      'When off, no auto-replies for this SIM',
                      style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    activeThumbColor: _success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, 'SIM'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Obx(() {
              final infos = _c.subscriptionInfos;
              final valid = _subscriptionId != null &&
                  infos.any((e) => e['subscriptionId'] == _subscriptionId);
              final value = valid ? _subscriptionId : null;
              return DropdownButtonFormField<int?>(
                // ignore: deprecated_member_use
                value: value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  labelText: 'Linked SIM',
                  prefixIcon: const Icon(Icons.sim_card_rounded),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...infos.map((info) {
                    final id = info['subscriptionId'] as int?;
                    if (id == null) return null;
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text(_c.formatSimLabel(info)),
                    );
                  }).whereType<DropdownMenuItem<int?>>(),
                ],
                onChanged: (v) => setState(() => _subscriptionId = v),
              );
            }),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, 'Days setup'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.calendar_month_rounded, color: _primary),
                  title: Text('Enable specific days', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    'When on, replies are sent only on selected days.',
                    style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  value: _enableDaysSetup,
                  onChanged: (v) => setState(() => _enableDaysSetup = v),
                  activeThumbColor: _primary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_enableDaysSetup) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _dayChip(context, 1, 'Mon'),
                      _dayChip(context, 2, 'Tue'),
                      _dayChip(context, 3, 'Wed'),
                      _dayChip(context, 4, 'Thu'),
                      _dayChip(context, 5, 'Fri'),
                      _dayChip(context, 6, 'Sat'),
                      _dayChip(context, 7, 'Sun'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, 'Vacation mode'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.beach_access_rounded, color: _primary),
                  title: Text('Enable vacation mode', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    'Overrides all standard messages with a single vacation message.',
                    style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  value: _vacationMode,
                  onChanged: (v) => setState(() => _vacationMode = v),
                  activeThumbColor: _primary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _vacationMsgCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Vacation message',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, 'Reply types'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Column(
              children: [
                _toggle(context, 'Missed call', _tMissed, (v) => setState(() => _tMissed = v), icon: Icons.call_missed_rounded),
                _toggle(context, 'Incoming call (answered)', _tIncoming, (v) => setState(() => _tIncoming = v), icon: Icons.call_rounded),
                _toggle(context, 'Busy (call waiting)', _tBusy, (v) => setState(() => _tBusy = v), icon: Icons.call_end_rounded),
                _toggle(context, 'Rejected call', _tRejected, (v) => setState(() => _tRejected = v), icon: Icons.phone_disabled_rounded),
                _toggle(context, 'Outgoing (answered)', _tOutAns, (v) => setState(() => _tOutAns = v), icon: Icons.call_made_rounded),
                _toggle(context, 'Outgoing (no answer)', _tOutUnans, (v) => setState(() => _tOutUnans = v), icon: Icons.phone_callback_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel(context, 'Messages'),
          const SizedBox(height: 10),
          ...ReplyStoreEventKeys.all.map((k) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _card(
                context,
                padding: const EdgeInsets.all(14),
                child: TextField(
                  controller: _msgCtrls[k],
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: ReplyStoreEventKeys.label(k),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          _sectionLabel(context, 'Bulk apply'),
          const SizedBox(height: 10),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Same text for multiple types', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ReplyStoreEventKeys.all.map((k) {
                    final sel = _groupKeys.contains(k);
                    return FilterChip(
                      label: Text(ReplyStoreEventKeys.label(k), style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface)),
                      selected: sel,
                      selectedColor: _primary.withAlpha(18),
                      checkmarkColor: _primary,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _groupKeys.add(k);
                          } else {
                            _groupKeys.remove(k);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _groupTextCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Message for selected types',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _applyGroupMessage,
                    icon: const Icon(Icons.done_all_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: Text('Apply to selected types', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
    );
  }

  Widget _card(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: child,
    );
  }

  Widget _toggle(
    BuildContext context,
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: _primary),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
      value: value,
      onChanged: onChanged,
      dense: true,
      activeThumbColor: _primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _dayChip(BuildContext context, int day, String label) {
    final sel = _selectedDays.contains(day);
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
      selected: sel,
      selectedColor: _primary.withAlpha(20),
      checkmarkColor: _primary,
      onSelected: (v) {
        setState(() {
          if (v) {
            _selectedDays.add(day);
          } else {
            _selectedDays.remove(day);
          }
        });
      },
    );
  }
}
