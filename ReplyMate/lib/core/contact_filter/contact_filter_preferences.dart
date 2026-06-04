import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/auto_reply/auto_reply_bridge.dart';
import 'contact_filter_mode.dart';
import 'contact_filter_phone_normalize.dart';

/// Persists contact filter mode and selected phone numbers (digits-only strings).
class ContactFilterPreferences {
  static const String _keyMode = 'contact_filter_mode';
  // Legacy key (pre vNext): stored a single selection list.
  static const String _keyPhonesJson = 'contact_filter_phones_json';

  static const String _keyOnlySelectedPhonesJson =
      'contact_filter_only_selected_phones_json';
  static const String _keyExcludeSelectedPhonesJson =
      'contact_filter_exclude_selected_phones_json';

  Future<ContactFilterMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return ContactFilterMode.fromStorage(prefs.getString(_keyMode));
  }

  static Set<String> _decodePhoneDigitsFromJson(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final out = <String>{};
      for (final e in list) {
        final d = contactFilterDigitsOnly(e.toString());
        if (d.isEmpty) continue;
        final k = contactFilterCanonicalPhoneKey(d);
        if (k.length >= 10) out.add(k);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> getOnlySelectedPhoneDigits() async {
    final prefs = await SharedPreferences.getInstance();
    final onlyRaw = prefs.getString(_keyOnlySelectedPhonesJson);
    if (onlyRaw != null && onlyRaw.trim().isNotEmpty) {
      return _decodePhoneDigitsFromJson(onlyRaw);
    }

    // Migration: fall back to legacy single list if present.
    final legacyRaw = prefs.getString(_keyPhonesJson);
    if (legacyRaw == null || legacyRaw.trim().isEmpty) return {};
    return _decodePhoneDigitsFromJson(legacyRaw);
  }

  Future<Set<String>> getExcludeSelectedPhoneDigits() async {
    final prefs = await SharedPreferences.getInstance();
    final excludeRaw = prefs.getString(_keyExcludeSelectedPhonesJson);
    if (excludeRaw != null && excludeRaw.trim().isNotEmpty) {
      return _decodePhoneDigitsFromJson(excludeRaw);
    }

    // Migration: fall back to legacy single list if present.
    final legacyRaw = prefs.getString(_keyPhonesJson);
    if (legacyRaw == null || legacyRaw.trim().isEmpty) return {};
    return _decodePhoneDigitsFromJson(legacyRaw);
  }

  /// Returns the active mode's selection set.
  Future<Set<String>> getSelectedPhoneDigits() async {
    final mode = await getMode();
    switch (mode) {
      case ContactFilterMode.all:
        return {};
      case ContactFilterMode.onlySelected:
        return getOnlySelectedPhoneDigits();
      case ContactFilterMode.excludeSelected:
        return getExcludeSelectedPhoneDigits();
    }
  }

  Future<void> save({
    required ContactFilterMode mode,
    required Set<String> selectedPhoneDigits,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMode, mode.storageValue);
    final normalized = <String>{};
    for (final e in selectedPhoneDigits) {
      final d = contactFilterDigitsOnly(e);
      if (d.isEmpty) continue;
      final k = contactFilterCanonicalPhoneKey(d);
      if (k.length >= 10) normalized.add(k);
    }
    final sorted = normalized.toList()..sort();
    final encoded = jsonEncode(sorted);

    // Persist into the mode-specific selection key.
    switch (mode) {
      case ContactFilterMode.all:
        await prefs.setString(_keyOnlySelectedPhonesJson, '[]');
        await prefs.setString(_keyExcludeSelectedPhonesJson, '[]');
        break;
      case ContactFilterMode.onlySelected:
        await prefs.setString(_keyOnlySelectedPhonesJson, encoded);
        break;
      case ContactFilterMode.excludeSelected:
        await prefs.setString(_keyExcludeSelectedPhonesJson, encoded);
        break;
    }

    try {
      final phonesJson = (mode == ContactFilterMode.all) ? '[]' : encoded;
      await AutoReplyBridge().syncContactFilterNative(
        filterMode: mode.storageValue,
        phonesJson: phonesJson,
      );
    } catch (_) {}
  }

  /// Pushes current prefs to native [ContactFilterNativeStore] (e.g. on app resume).
  Future<void> syncToNative() async {
    try {
      final mode = await getMode();
      final selectedDigits = switch (mode) {
        ContactFilterMode.all => <String>{},
        ContactFilterMode.onlySelected => await getOnlySelectedPhoneDigits(),
        ContactFilterMode.excludeSelected =>
          await getExcludeSelectedPhoneDigits(),
      };

      final encoded = jsonEncode(selectedDigits.toList()..sort());

      await AutoReplyBridge().syncContactFilterNative(
        filterMode: mode.storageValue,
        phonesJson: encoded,
      );
    } catch (_) {}
  }
}
