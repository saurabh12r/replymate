import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';

import '../../core/contact_filter/contact_filter_mode.dart';
import '../../core/contact_filter/contact_filter_preferences.dart';
import '../../core/contact_filter/contact_filter_sms_policy.dart';
import '../../core/contact_filter/contact_filter_phone_normalize.dart';
import 'contact_filter_contact_processing.dart';

/// One selectable row: a single phone line (minimal fields).
class ContactPhoneRow {
  ContactPhoneRow({
    required this.displayName,
    required this.phoneDisplay,
    required this.digitsKey,
  });

  final String displayName;
  final String phoneDisplay;
  final String digitsKey;

  factory ContactPhoneRow.fromMap(ContactRowMap m) {
    return ContactPhoneRow(
      displayName: m['name'] ?? 'Unknown',
      phoneDisplay: m['phone'] ?? '',
      digitsKey: m['digits'] ?? '',
    );
  }
}

class ContactFilterController extends GetxController {
  ContactFilterController({
    ContactFilterPreferences? preferences,
  }) : _preferences = preferences ?? ContactFilterPreferences();

  final ContactFilterPreferences _preferences;

  static const int _pageSize = 48;
  static const double _loadMoreScrollExtent = 320;

  final Rx<ContactFilterMode> mode = ContactFilterMode.all.obs;
  // Separate selection sets per mode so switching modes doesn't mirror checks.
  final Rx<Set<String>> onlySelectedDigits = Rx<Set<String>>(<String>{});
  final Rx<Set<String>> excludeSelectedDigits = Rx<Set<String>>(<String>{});

  // UI-only search. When query is empty, we restrict the visible list to the
  // current mode's selection set.
  final RxString searchQuery = ''.obs;
  final TextEditingController searchTextController = TextEditingController();
  final RxBool contactPermissionGranted = false.obs;
  final RxBool loadingContacts = false.obs;
  final RxBool saving = false.obs;

  /// Bumps when cache or visible window changes (list UI listens to this only).
  final RxInt listRevision = 0.obs;

  final ScrollController contactListScrollController = ScrollController();

  // Full OS contact list (deduped/sorted).
  List<ContactPhoneRow> _allRowsCache = [];
  // Filtered view of [_allRowsCache] for current search/mode.
  List<ContactPhoneRow> _rowCache = [];
  int _visibleEnd = 0;

  bool _permissionResolved = false;
  DateTime? _lastLoadMoreAt;

  int get visibleItemCount => _visibleEnd;

  bool get hasMoreRows => _visibleEnd < _rowCache.length;

  bool get hasCachedContacts => _allRowsCache.isNotEmpty;

  ContactPhoneRow rowAt(int index) => _rowCache[index];

  bool isSelected(String digitsKey) => isSelectedForMode(mode.value, digitsKey);

  bool isSelectedForMode(ContactFilterMode m, String digitsKey) {
    switch (m) {
      case ContactFilterMode.all:
        return false;
      case ContactFilterMode.onlySelected:
        return onlySelectedDigits.value.contains(digitsKey);
      case ContactFilterMode.excludeSelected:
        return excludeSelectedDigits.value.contains(digitsKey);
    }
  }

  @override
  void onInit() {
    super.onInit();
    contactListScrollController.addListener(_onContactScroll);
    _loadFromDisk();
  }

  @override
  void onClose() {
    contactListScrollController.removeListener(_onContactScroll);
    contactListScrollController.dispose();
    searchTextController.dispose();
    super.onClose();
  }

  Future<void> _loadFromDisk() async {
    mode.value = await _preferences.getMode();
    onlySelectedDigits.value = await _preferences.getOnlySelectedPhoneDigits();
    excludeSelectedDigits.value =
        await _preferences.getExcludeSelectedPhoneDigits();
    ContactFilterSmsPolicy.instance.apply(
      mode: mode.value,
      selectedPhoneDigits: _selectionSetForMode(mode.value),
    );
    await refreshPermissionState();
    if (mode.value != ContactFilterMode.all && contactPermissionGranted.value) {
      _scheduleContactLoad();
    }
  }

  Set<String> _selectionSetForMode(ContactFilterMode m) {
    switch (m) {
      case ContactFilterMode.all:
        return <String>{};
      case ContactFilterMode.onlySelected:
        return onlySelectedDigits.value;
      case ContactFilterMode.excludeSelected:
        return excludeSelectedDigits.value;
    }
  }

  /// Loads after the first frame so the shell paints before heavy work.
  void _scheduleContactLoad() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      loadContacts(forceRefresh: false);
    });
  }

  void _onContactScroll() {
    if (!contactListScrollController.hasClients) return;
    final pos = contactListScrollController.position;
    if (!pos.hasContentDimensions) return;
    if (pos.pixels < pos.maxScrollExtent - _loadMoreScrollExtent) return;
    _throttledLoadMore();
  }

  void _throttledLoadMore() {
    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) <
            const Duration(milliseconds: 200)) {
      return;
    }
    _lastLoadMoreAt = now;
    loadMoreVisible();
  }

  /// Cached permission after first resolve; refreshed explicitly after requests/settings.
  Future<void> ensurePermissionResolved() async {
    if (_permissionResolved) return;
    await refreshPermissionState();
  }

  Future<void> refreshPermissionState() async {
    final ok = await FlutterContacts.permissions.has(PermissionType.read);
    contactPermissionGranted.value = ok;
    _permissionResolved = true;
  }

  Future<void> requestContactPermission() async {
    await FlutterContacts.permissions.request(PermissionType.read);
    await refreshPermissionState();
    if (contactPermissionGranted.value) {
      _scheduleContactLoad();
    }
  }

  Future<void> openContactSettings() async {
    await FlutterContacts.permissions.openSettings();
    _permissionResolved = false;
  }

  Future<void> onModeChanged(ContactFilterMode next) async {
    mode.value = next;
    if (next == ContactFilterMode.all) {
      _rowCache = [];
      _visibleEnd = 0;
      listRevision.value++;
      return;
    }

    // Restrict visible list for the new mode.
    _recomputeFilteredCache();

    await ensurePermissionResolved();
    if (contactPermissionGranted.value) {
      if (_allRowsCache.isEmpty) {
        _scheduleContactLoad();
      }
    } else {
      _allRowsCache = [];
      _rowCache = [];
      _visibleEnd = 0;
      listRevision.value++;
    }
  }

  void _applyNewAllCache(List<ContactPhoneRow> rows) {
    _allRowsCache = rows;
    _recomputeFilteredCache();
  }

  /// [forceRefresh] clears memory cache and reloads from the OS.
  Future<void> loadContacts({bool forceRefresh = false}) async {
    if (!contactPermissionGranted.value) return;
    if (!forceRefresh && _allRowsCache.isNotEmpty) {
      return;
    }
    if (forceRefresh) {
      _allRowsCache = [];
      _rowCache = [];
      _visibleEnd = 0;
      listRevision.value++;
    }
    loadingContacts.value = true;
    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );
      final maps = contactFilterMapsFromContacts(contacts);
      final sortedMaps = await contactFilterSortRowsAsync(maps);
      final rows =
          sortedMaps.map(ContactPhoneRow.fromMap).toList(growable: false);
      _applyNewAllCache(rows);
    } finally {
      loadingContacts.value = false;
    }
  }

  void loadMoreVisible() {
    if (_visibleEnd >= _rowCache.length) return;
    _visibleEnd = min(_visibleEnd + _pageSize, _rowCache.length);
    listRevision.value++;
  }

  void toggleSelection(String digitsKey) {
    toggleSelectionForMode(mode.value, digitsKey);
  }

  void toggleSelectionForMode(ContactFilterMode m, String digitsKey) {
    switch (m) {
      case ContactFilterMode.all:
        return;
      case ContactFilterMode.onlySelected:
        _toggleSetValue(onlySelectedDigits, digitsKey);
        break;
      case ContactFilterMode.excludeSelected:
        _toggleSetValue(excludeSelectedDigits, digitsKey);
        break;
    }

    // When search is empty, the visible list is restricted to the current
    // selection set, so it must be recomputed after a toggle.
    if (searchQuery.value.trim().isEmpty) {
      _recomputeFilteredCache();
    }
  }

  void _toggleSetValue(Rx<Set<String>> target, String digitsKey) {
    final next = Set<String>.from(target.value);
    if (next.contains(digitsKey)) {
      next.remove(digitsKey);
    } else {
      next.add(digitsKey);
    }
    target.value = next;
  }

  void onSearchQueryChanged(String query) {
    // Keep Rx query in sync with the text field.
    if (query == searchQuery.value) return;
    searchQuery.value = query;
    _recomputeFilteredCache();
  }

  void clearSearch() {
    if (searchQuery.value.isEmpty) return;
    searchTextController.clear();
    searchQuery.value = '';
    _recomputeFilteredCache();
  }

  bool _matchesSearch(ContactPhoneRow row, String q) {
    final queryTrim = q.trim();
    if (queryTrim.isEmpty) return true;

    final qLower = queryTrim.toLowerCase();
    if (row.displayName.toLowerCase().contains(qLower)) return true;
    if (row.phoneDisplay.toLowerCase().contains(qLower)) return true;

    final digitsOnly = contactFilterDigitsOnly(qLower);
    if (digitsOnly.isNotEmpty && row.digitsKey.contains(digitsOnly)) {
      return true;
    }
    return false;
  }

  void _recomputeFilteredCache() {
    final qTrim = searchQuery.value.trim();

    if (mode.value == ContactFilterMode.all) {
      _rowCache = [];
      _visibleEnd = 0;
      listRevision.value++;
      return;
    }

    if (_allRowsCache.isEmpty) {
      _rowCache = [];
      _visibleEnd = 0;
      listRevision.value++;
      return;
    }

    Iterable<ContactPhoneRow> base = _allRowsCache;

    if (qTrim.isEmpty) {
      // UX: when search is empty, show ALL contacts, but bubble the currently
      // selected/excluded ones to the top.
      final digitsSet = _selectionSetForMode(mode.value);
      final selected = base.where((r) => digitsSet.contains(r.digitsKey)).toList(growable: false);
      final others = base.where((r) => !digitsSet.contains(r.digitsKey)).toList(growable: false);
      base = <ContactPhoneRow>[...selected, ...others];
    } else {
      base = base.where((r) => _matchesSearch(r, qTrim));
    }

    _rowCache = base.toList(growable: false);
    _visibleEnd = min(_pageSize, _rowCache.length);
    listRevision.value++;
  }

  /// App resumed: reload filter prefs + in-memory policy + permission bit
  /// without re-querying the full OS contact list.
  Future<void> syncPolicyFromDisk() async {
    try {
      mode.value = await _preferences.getMode();
      onlySelectedDigits.value =
          await _preferences.getOnlySelectedPhoneDigits();
      excludeSelectedDigits.value =
          await _preferences.getExcludeSelectedPhoneDigits();
      ContactFilterSmsPolicy.instance.apply(
        mode: mode.value,
        selectedPhoneDigits: _selectionSetForMode(mode.value),
      );
      await refreshPermissionState();
    } catch (_) {}
  }

  Future<void> save(BuildContext context) async {
    final activeSelected = _selectionSetForMode(mode.value);
    if (mode.value == ContactFilterMode.onlySelected && activeSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one contact, or choose “All callers”.',
          ),
        ),
      );
      return;
    }
    saving.value = true;
    try {
      await _preferences.save(
        mode: mode.value,
        selectedPhoneDigits: activeSelected,
      );
      ContactFilterSmsPolicy.instance.apply(
        mode: mode.value,
        selectedPhoneDigits: activeSelected,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact filter saved')),
      );
    } finally {
      saving.value = false;
    }
  }
}
