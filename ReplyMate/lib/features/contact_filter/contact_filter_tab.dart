import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/contact_filter/contact_filter_mode.dart';
import 'contact_filter_controller.dart';

/// Bottom-nav tab: contact filter / SMS targeting rules.
class ContactFilterTab extends GetView<ContactFilterController> {
  const ContactFilterTab({super.key});

  static const Color _primary = Color(0xFF24389C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          'Contact Control',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          Obx(() {
            if (controller.mode.value == ContactFilterMode.all) {
              return const SizedBox.shrink();
            }
            return IconButton(
              onPressed: () => _showAddContactDialog(context),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add Contact',
            );
          }),
        ],
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
                    sliver: SliverToBoxAdapter(
                      child: _buildModeSection(context),
                    ),
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
              return _permissionCard(context);
            }
            if (controller.loadingContacts.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!controller.hasCachedContacts) {
              return _emptyCard(context);
            }
            return _buildSelectedContactsHeader(context);
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
        final selectedCount = controller.selectedContactsCount;
        if (selectedCount == 0) {
          return SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(child: _emptySelectedCard(context)),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSelectedContactItem(context, index),
              childCount: selectedCount,
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildSelectedContactsHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
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
                Obx(
                  () => Text(
                    '${controller.selectedContactsCount} contact${controller.selectedContactsCount == 1 ? '' : 's'} selected',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showAddContactDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            style: TextButton.styleFrom(foregroundColor: _primary),
          ),
        ],
      ),
    );
  }

  Widget _emptySelectedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No contacts selected',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts to send auto-reply SMS',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddContactDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Contact'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedContactItem(BuildContext context, int index) {
    final selectedContacts = controller.selectedContacts;
    if (index >= selectedContacts.length) return const SizedBox.shrink();

    final contact = selectedContacts[index];
    final theme = Theme.of(context);
    final isLast = index == selectedContacts.length - 1;
    final borderSide = BorderSide(
      color: theme.colorScheme.outlineVariant.withAlpha(100),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          left: borderSide,
          right: borderSide,
          top: borderSide,
          bottom: isLast ? borderSide : BorderSide.none,
        ),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : (index == 0
                  ? const BorderRadius.vertical(top: Radius.circular(16))
                  : null),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _primary.withAlpha(25),
          child: Text(
            contact.displayName.isNotEmpty
                ? contact.displayName[0].toUpperCase()
                : '?',
            style: TextStyle(color: _primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(
          contact.displayName,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          contact.phoneDisplay,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _showRemoveContactDialog(context, contact),
          icon: const Icon(Icons.remove_circle_outline_rounded),
          color: Colors.red,
          tooltip: 'Remove',
        ),
      ),
    );
  }

  void _showRemoveContactDialog(BuildContext context, ContactPhoneRow contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${contact.displayName} from selected contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.toggleSelection(contact.digitsKey);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddContactSheet(controller: controller),
    );
  }

  Widget _buildPhoneListItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final borderSide = BorderSide(
      color: theme.colorScheme.outlineVariant.withAlpha(100),
    );
    if (index == 0) {
      return Obx(() {
        final busy = controller.loadingContacts.value;
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(100),
            ),
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
                      onPressed: busy
                          ? null
                          : () => controller.loadContacts(forceRefresh: true),
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
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF24389C),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                    ),
                  );
                }),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withAlpha(60),
              ),
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
        color: theme.cardColor,
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
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(60),
            ),
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

  Widget _radioRow(
    BuildContext context, {
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
                  color: selected
                      ? _primary
                      : Theme.of(context).colorScheme.outlineVariant,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildModeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
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
              context,
              selected: m == ContactFilterMode.all,
              title: 'Send SMS to All Callers',
              subtitle: 'SMS will be sent to all callers',
              onTap: () => controller.onModeChanged(ContactFilterMode.all),
            ),
            _radioRow(
              context,
              selected: m == ContactFilterMode.onlySelected,
              title: 'Send SMS Only to Selected Contacts',
              subtitle: 'Only selected contacts will receive SMS',
              onTap: () =>
                  controller.onModeChanged(ContactFilterMode.onlySelected),
            ),
            _radioRow(
              context,
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

  Widget _permissionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.contact_page_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Contacts permission needed',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allow access to pick which numbers are included or excluded.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Column(
        children: [
          Text(
            'No phone numbers found',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add contacts with phone numbers, then tap refresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.controller.isSelectedForMode(
      widget.mode,
      widget.row.digitsKey,
    );
  }

  @override
  void didUpdateWidget(covariant _ContactFilterCheckRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.row.digitsKey != widget.row.digitsKey) {
      _checked = widget.controller.isSelectedForMode(
        widget.mode,
        widget.row.digitsKey,
      );
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
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        widget.row.phoneDisplay,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _AddContactSheet extends StatefulWidget {
  final ContactFilterController controller;

  const _AddContactSheet({required this.controller});

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  static const Color _primary = Color(0xFF24389C);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContactPhoneRow> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return widget.controller.allContacts;
    }
    final query = _searchQuery.toLowerCase();
    return widget.controller.allContacts.where((c) {
      return c.displayName.toLowerCase().contains(query) ||
          c.phoneDisplay.toLowerCase().contains(query) ||
          c.digitsKey.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
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
                    'Add Contacts',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _primary,
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
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
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
          Expanded(
            child: _filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No contacts available'
                              : 'No contacts found',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final isSelected = widget.controller.isSelected(
                        contact.digitsKey,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _primary
                                : theme.colorScheme.outlineVariant.withAlpha(
                                    50,
                                  ),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            widget.controller.toggleSelection(
                              contact.digitsKey,
                            );
                            setState(() {});
                          },
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? _primary
                                : _primary.withAlpha(25),
                            child: Icon(
                              isSelected
                                  ? Icons.check_rounded
                                  : Icons.person_rounded,
                              color: isSelected ? Colors.white : _primary,
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
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: _primary,
                                )
                              : null,
                        ),
                      );
                    },
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
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Done',
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
}
