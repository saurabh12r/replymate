import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/contact_filter/contact_filter_mode.dart';
import 'contact_filter_controller.dart';

/// Bottom-nav tab: contact filter / SMS targeting rules.
class ContactFilterTab extends GetView<ContactFilterController> {
  const ContactFilterTab({super.key});

  static const Color _primary = Color(0xFF24389C);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);
  static const Color _surface = Color(0xFFF8F9FA);
  static const Color _outlineVariant = Color(0xFFC5C5D4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Contact Control',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(() {
              final showContact =
                  controller.mode.value != ContactFilterMode.all;
              return CustomScrollView(
                controller: controller.contactListScrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(child: _buildModeSection()),
                  ),
                  if (showContact) ..._contactSlivers(context),
                ],
              );
            }),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Obx(() {
                final busy = controller.saving.value;
                return FilledButton(
                  onPressed: busy ? null : () => controller.save(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _contactSlivers(BuildContext context) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        sliver: SliverToBoxAdapter(
          child: Obx(() {
            if (!controller.contactPermissionGranted.value) {
              return _permissionCard();
            }
            if (controller.loadingContacts.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!controller.hasCachedContacts) {
              return _emptyCard();
            }
            return const SizedBox.shrink();
          }),
        ),
      ),
      Obx(() {
        if (!controller.contactPermissionGranted.value ||
            controller.loadingContacts.value ||
            !controller.hasCachedContacts) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final _ = controller.listRevision.value;
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPhoneListItem(context, index),
              childCount: 1 + controller.visibleItemCount,
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildPhoneListItem(BuildContext context, int index) {
    final borderSide = BorderSide(color: _outlineVariant.withAlpha(100));
    if (index == 0) {
      return Obx(() {
        final busy = controller.loadingContacts.value;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(color: _outlineVariant.withAlpha(100)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select numbers',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: busy ? null : () => controller.loadContacts(forceRefresh: true),
                      icon: const Icon(Icons.refresh_rounded),
                      color: _primary,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Obx(() {
                  final q = controller.searchQuery.value;
                  return TextField(
                    controller: controller.searchTextController,
                    onChanged: controller.onSearchQueryChanged,
                    decoration: InputDecoration(
                      hintText: 'Search contacts',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: q.isNotEmpty
                          ? IconButton(
                              onPressed: controller.clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFF24389C), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  );
                }),
              ),
              Divider(height: 1, color: _outlineVariant.withAlpha(60)),
            ],
          ),
        );
      });
    }
    final rowIndex = index - 1;
    final row = controller.rowAt(rowIndex);
    final isLast =
        rowIndex == controller.visibleItemCount - 1 && !controller.hasMoreRows;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: borderSide,
          right: borderSide,
          bottom: isLast ? borderSide : BorderSide.none,
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rowIndex > 0)
            Divider(height: 1, color: _outlineVariant.withAlpha(60)),
          _ContactFilterCheckRow(
            key: ValueKey<String>(row.digitsKey),
            row: row,
            controller: controller,
            mode: controller.mode.value,
          ),
        ],
      ),
    );
  }

  Widget _radioRow({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? _primary : _outlineVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant.withAlpha(100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final m = controller.mode.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Who receives auto-reply SMS',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
            const SizedBox(height: 8),
            _radioRow(
              selected: m == ContactFilterMode.all,
              title: 'Send SMS to All Callers',
              subtitle: 'SMS will be sent to all callers',
              onTap: () => controller.onModeChanged(ContactFilterMode.all),
            ),
            _radioRow(
              selected: m == ContactFilterMode.onlySelected,
              title: 'Send SMS Only to Selected Contacts',
              subtitle: 'Only selected contacts will receive SMS',
              onTap: () =>
                  controller.onModeChanged(ContactFilterMode.onlySelected),
            ),
            _radioRow(
              selected: m == ContactFilterMode.excludeSelected,
              title: 'Send SMS to All Except Selected Contacts',
              subtitle: 'Selected contacts will NOT receive SMS',
              onTap: () =>
                  controller.onModeChanged(ContactFilterMode.excludeSelected),
            ),
          ],
        );
      }),
    );
  }

  Widget _permissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.contact_page_outlined, size: 48, color: _outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Contacts permission needed',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allow access to pick which numbers are included or excluded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controller.requestContactPermission,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Grant contacts access',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: controller.openContactSettings,
            child: Text(
              'Open system settings',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            'No phone numbers found',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: _onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts with phone numbers, then tap refresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _onSurfaceVariant,
            ),
          ),
          TextButton.icon(
            onPressed: () => controller.loadContacts(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

/// Local checkbox state so the rest of the list does not rebuild on tap.
class _ContactFilterCheckRow extends StatefulWidget {
  const _ContactFilterCheckRow({
    super.key,
    required this.row,
    required this.controller,
    required this.mode,
  });

  final ContactPhoneRow row;
  final ContactFilterController controller;
  final ContactFilterMode mode;

  @override
  State<_ContactFilterCheckRow> createState() => _ContactFilterCheckRowState();
}

class _ContactFilterCheckRowState extends State<_ContactFilterCheckRow> {
  static const Color _primary = Color(0xFF24389C);
  static const Color _onSurface = Color(0xFF191C1D);
  static const Color _onSurfaceVariant = Color(0xFF454652);

  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.controller.isSelectedForMode(widget.mode, widget.row.digitsKey);
  }

  @override
  void didUpdateWidget(covariant _ContactFilterCheckRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode || oldWidget.row.digitsKey != widget.row.digitsKey) {
      _checked = widget.controller.isSelectedForMode(widget.mode, widget.row.digitsKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _checked,
      onChanged: (_) {
        setState(() {
          widget.controller.toggleSelectionForMode(
            widget.mode,
            widget.row.digitsKey,
          );
          _checked = widget.controller.isSelectedForMode(
            widget.mode,
            widget.row.digitsKey,
          );
        });
      },
      checkColor: Colors.white,
      activeColor: _primary,
      title: Text(
        widget.row.displayName,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: _onSurface,
        ),
      ),
      subtitle: Text(
        widget.row.phoneDisplay,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: _onSurfaceVariant,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
