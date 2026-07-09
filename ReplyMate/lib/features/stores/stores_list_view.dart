import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/stores/reply_store_models.dart';
import 'stores_controller.dart';
import 'store_edit_view.dart';

class StoresListView extends StatelessWidget {
  const StoresListView({super.key, this.showBack = true});

  static const Color _primary = Color(0xFF24389C);
  static const Color _primaryContainer = Color(0xFF3F51B5);
  final bool showBack;

  static bool _effectiveActive(ReplyStore s) =>
      s.active && s.subscriptionId != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = Get.isRegistered<StoresController>()
        ? Get.find<StoresController>()
        : Get.put(StoresController());
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final draft = StoresController.createEmptyStore();
          await Get.to<void>(() => StoreEditView(store: draft, isNew: true));
          await c.refreshAll();
        },
        backgroundColor: _primary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add business',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() {
                if (c.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.stores.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No businesses yet. Add one and link a SIM to enable auto-replies for that line.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: c.stores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = c.stores[i];
                    return _StoreCard(
                      store: s,
                      controller: c,
                      effectiveActive: _effectiveActive(s),
                      statusLabel: _statusLabel(c, s),
                      onOpenEdit: () async {
                        await Get.to<void>(() => StoreEditView(store: s));
                        await c.refreshAll();
                      },
                      onToggle: (wantOn) =>
                          _onToggleActive(context, c, s, wantOn),
                      onDelete: () async {
                        final ok = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Delete business?'),
                            content: Text('Remove “${s.name}”?'),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await c.deleteStore(s.id);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2980), _primary, _primaryContainer],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              icon: const BackButtonIcon(),
              color: Colors.white,
              onPressed: Get.back,
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Businesses',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(StoresController c, ReplyStore s) {
    if (!_effectiveActive(s)) return 'Inactive';
    return 'Active (${c.simSlotLabelForSubscription(s.subscriptionId!)})';
  }

  static Future<void> _onToggleActive(
    BuildContext context,
    StoresController c,
    ReplyStore s,
    bool wantOn,
  ) async {
    if (!wantOn) {
      await c.deactivateStore(s.id);
      return;
    }
    if (s.subscriptionId != null) {
      await c.setStoreActive(s.id, true);
      return;
    }
    final sims = c.orderedSubscriptionInfos;
    if (sims.isEmpty) {
      Get.snackbar(
        'Cannot activate',
        'No SIM cards detected. Add a SIM card to choose a line for this business.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _SimSelectDialog(sims: sims, controller: c),
    );
    if (picked == null || !context.mounted) return;
    await c.activateStoreWithSubscription(s.id, picked);
  }
}

class _SimSelectDialog extends StatefulWidget {
  const _SimSelectDialog({required this.sims, required this.controller});

  final List<Map<String, dynamic>> sims;
  final StoresController controller;

  @override
  State<_SimSelectDialog> createState() => _SimSelectDialogState();
}

class _SimSelectDialogState extends State<_SimSelectDialog> {
  late int? _selectedSub;

  @override
  void initState() {
    super.initState();
    _selectedSub = widget.sims.isEmpty
        ? null
        : widget.sims.first['subscriptionId'] is int
        ? widget.sims.first['subscriptionId'] as int
        : (widget.sims.first['subscriptionId'] as num?)?.toInt();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select SIM for this business'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.sims.map((info) {
            final sub = info['subscriptionId'];
            final id = sub is int ? sub : (sub as num?)?.toInt();
            if (id == null) return const SizedBox.shrink();
            final label = widget.controller.formatSimLabel(info);
            final selected = _selectedSub == id;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(label, style: GoogleFonts.inter(fontSize: 15)),
              onTap: () => setState(() => _selectedSub = id),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedSub == null
              ? null
              : () => Navigator.of(context).pop(_selectedSub),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.controller,
    required this.effectiveActive,
    required this.statusLabel,
    required this.onOpenEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ReplyStore store;
  final StoresController controller;
  final bool effectiveActive;
  final String statusLabel;
  final VoidCallback onOpenEdit;
  final Future<void> Function(bool wantOn) onToggle;
  final VoidCallback onDelete;

  static const Color _activeGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onOpenEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              effectiveActive
                                  ? Icons.check_circle_rounded
                                  : Icons.pause_circle_rounded,
                              size: 18,
                              color: effectiveActive
                                  ? _activeGreen
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: effectiveActive
                                      ? _activeGreen
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (store.subscriptionId != null &&
                            !effectiveActive) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Linked: ${controller.simSlotLabelForSubscription(store.subscriptionId!)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withAlpha(150),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.beach_access_rounded,
                      color: store.vacationMode
                          ? _activeGreen
                          : theme.colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                    tooltip: store.vacationMode
                        ? 'Vacation Mode: ON'
                        : 'Vacation Mode: OFF',
                    onPressed: () {
                      controller.toggleVacationMode(
                        store.id,
                        !store.vacationMode,
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_rounded,
                      color: store.vacationMessage.isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                    tooltip: 'Edit Vacation Message',
                    onPressed: () =>
                        _editVacationMessage(context, controller, store),
                  ),
                ],
              ),
              Switch(
                value: effectiveActive,
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _activeGreen.withAlpha(114);
                  }
                  return theme.colorScheme.outlineVariant;
                }),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected))
                    return _activeGreen;
                  return theme.colorScheme.onSurfaceVariant;
                }),
                onChanged: (v) => onToggle(v),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editVacationMessage(
    BuildContext context,
    StoresController controller,
    ReplyStore store,
  ) {
    final theme = Theme.of(context);
    final textController = TextEditingController(text: store.vacationMessage);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Vacation Message',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your vacation auto-reply...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {
                controller.setVacationMessage(
                  store.id,
                  textController.text.trim(),
                );
                Navigator.of(ctx).pop();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
