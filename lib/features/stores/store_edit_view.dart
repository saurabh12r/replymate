import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int? _subscriptionId;
  final Set<String> _groupKeys = {};
  final TextEditingController _groupTextCtrl = TextEditingController();

  StoresController get _c => Get.find<StoresController>();

  static const Color _primary = Color(0xFF24389C);
  static const Color _success = Color(0xFF2E7D32);
  static const Color _outlineVariant = Color(0xFFC5C5D4);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _surface = Colors.white;

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
    _subscriptionId = s.subscriptionId;
    _msgCtrls = {
      for (final k in ReplyStoreEventKeys.all)
        k: TextEditingController(text: s.messageForEventKey(k) ?? ''),
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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

  Future<void> _save() async {
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
      templates: templates,
      eventTemplateIds: Map<String, String>.from(_eventTemplateIds),
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
    if (mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
          _sectionLabel('Business'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
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
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _outlineVariant.withAlpha(90)),
                  ),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.power_settings_new_rounded),
                    title: Text('Active', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      'When off, no auto-replies for this SIM',
                      style: GoogleFonts.inter(color: _onSurfaceVariant),
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
          _sectionLabel('SIM'),
          const SizedBox(height: 10),
          _card(
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
          _sectionLabel('Reply types'),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                _toggle('Missed call', _tMissed, (v) => setState(() => _tMissed = v), icon: Icons.call_missed_rounded),
                _toggle('Incoming call (answered)', _tIncoming, (v) => setState(() => _tIncoming = v), icon: Icons.call_rounded),
                _toggle('WhatsApp missed call', _tWa, (v) => setState(() => _tWa = v), icon: Icons.chat_bubble_rounded),
                _toggle('Busy (call waiting)', _tBusy, (v) => setState(() => _tBusy = v), icon: Icons.call_end_rounded),
                _toggle('Rejected call', _tRejected, (v) => setState(() => _tRejected = v), icon: Icons.phone_disabled_rounded),
                _toggle('Outgoing (answered)', _tOutAns, (v) => setState(() => _tOutAns = v), icon: Icons.call_made_rounded),
                _toggle('Outgoing (no answer)', _tOutUnans, (v) => setState(() => _tOutUnans = v), icon: Icons.phone_callback_rounded),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'WhatsApp replies use your default SIM business.',
                    style: GoogleFonts.inter(fontSize: 12, color: _onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionLabel('Messages'),
          const SizedBox(height: 10),
          ...ReplyStoreEventKeys.all.map((k) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _card(
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
          _sectionLabel('Bulk apply'),
          const SizedBox(height: 10),
          _card(
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
                      label: Text(ReplyStoreEventKeys.label(k), style: const TextStyle(fontSize: 11)),
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
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _outlineVariant.withAlpha(60)),
      ),
      child: child,
    );
  }

  Widget _toggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged, {
    required IconData icon,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: _primary),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      onChanged: onChanged,
      dense: true,
      activeThumbColor: _primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}
