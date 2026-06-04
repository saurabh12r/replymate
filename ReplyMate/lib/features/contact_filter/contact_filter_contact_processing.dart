import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/contact_filter/contact_filter_phone_normalize.dart';

/// Minimal row data for isolate sorting (only strings).
typedef ContactRowMap = Map<String, String>;

/// Runs on a background isolate — keep logic pure, no plugins.
@pragma('vm:entry-point')
List<ContactRowMap> contactFilterSortRowMaps(List<ContactRowMap> rows) {
  final sorted = List<ContactRowMap>.from(rows);
  sorted.sort((a, b) {
    final nameA = a['name'] ?? '';
    final nameB = b['name'] ?? '';
    final byName = nameA.toLowerCase().compareTo(nameB.toLowerCase());
    if (byName != 0) return byName;
    final phoneA = a['phone'] ?? '';
    final phoneB = b['phone'] ?? '';
    return phoneA.compareTo(phoneB);
  });
  return sorted;
}

/// Builds deduplicated, validated maps after [FlutterContacts.getAll].
/// Normalization and dedup run once per fetch (not on rebuilds).
List<ContactRowMap> contactFilterMapsFromContacts(List<Contact> contacts) {
  final seen = <String>{};
  final rows = <ContactRowMap>[];

  for (final c in contacts) {
    final displayName = c.displayName?.trim();
    final name = (displayName == null || displayName.isEmpty)
        ? 'Unknown'
        : displayName;

    for (final p in c.phones) {
      final raw = p.normalizedNumber?.trim().isNotEmpty == true
          ? p.normalizedNumber!.trim()
          : p.number.trim();
      if (raw.isEmpty) continue;

      final baseDigits = contactFilterDigitsOnly(raw);
      if (baseDigits.isEmpty) continue;

      final canonical = contactFilterCanonicalPhoneKey(baseDigits);
      if (canonical.length < 10) continue;
      if (seen.contains(canonical)) continue;
      seen.add(canonical);

      rows.add(
        HashMap<String, String>()
          ..['name'] = name
          ..['phone'] = canonical
          ..['digits'] = canonical,
      );
    }
  }
  return rows;
}

Future<List<ContactRowMap>> contactFilterSortRowsAsync(
  List<ContactRowMap> rows,
) {
  if (rows.length < 200) {
    return SynchronousFuture(contactFilterSortRowMaps(rows));
  }
  return compute(contactFilterSortRowMaps, rows);
}
