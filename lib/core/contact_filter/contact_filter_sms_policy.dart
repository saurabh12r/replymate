import 'contact_filter_mode.dart';
import 'contact_filter_phone_normalize.dart';
import 'contact_filter_preferences.dart';

bool _matchesCanonical(Set<String> stored, String incomingDigitsOnly) {
  final canon = contactFilterCanonicalPhoneKey(incomingDigitsOnly);
  if (canon.length < 10) return false;
  return stored.contains(canon);
}

/// In-memory policy synced from [SharedPreferences]. Call [hydrate] on startup and after [apply].
class ContactFilterSmsPolicy {
  ContactFilterSmsPolicy._();

  static final ContactFilterSmsPolicy instance = ContactFilterSmsPolicy._();

  final ContactFilterPreferences _prefs = ContactFilterPreferences();

  ContactFilterMode _mode = ContactFilterMode.all;
  Set<String> _selectedDigits = {};

  ContactFilterMode get mode => _mode;

  Set<String> get selectedPhoneDigits => Set.unmodifiable(_selectedDigits);

  static Set<String> _normalizeSelectedSet(Iterable<String> raw) {
    final out = <String>{};
    for (final e in raw) {
      final d = contactFilterDigitsOnly(e);
      if (d.isEmpty) continue;
      final k = contactFilterCanonicalPhoneKey(d);
      if (k.length >= 10) out.add(k);
    }
    return out;
  }

  /// Load from disk into memory (e.g. in [main]).
  Future<void> hydrate() async {
    _mode = await _prefs.getMode();
    final raw = await _prefs.getSelectedPhoneDigits();
    _selectedDigits = _normalizeSelectedSet(raw);
  }

  /// Update memory without writing disk (after save, or for tests).
  void apply({
    required ContactFilterMode mode,
    required Set<String> selectedPhoneDigits,
  }) {
    _mode = mode;
    _selectedDigits = _normalizeSelectedSet(selectedPhoneDigits);
  }

  /// Whether an auto-reply SMS should be sent for this caller number.
  bool shouldSendSMS(String number) {
    final d = contactFilterDigitsOnly(number);
    switch (_mode) {
      case ContactFilterMode.all:
        return true;
      case ContactFilterMode.onlySelected:
        if (_selectedDigits.isEmpty) return false;
        return _matchesCanonical(_selectedDigits, d);
      case ContactFilterMode.excludeSelected:
        if (_selectedDigits.isEmpty) return true;
        return !_matchesCanonical(_selectedDigits, d);
    }
  }
}

/// Global helper for auto-reply integration (uses hydrated in-memory policy).
bool shouldSendSMS(String number) =>
    ContactFilterSmsPolicy.instance.shouldSendSMS(number);
