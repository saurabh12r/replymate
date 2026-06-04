/// Phone normalization for contact deduplication and SMS filter matching.
library;

/// Strips everything except 0–9.
String contactFilterDigitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

/// Produces one stable key per subscriber number across formatting variants.
/// Call with **digits-only** input (use [contactFilterDigitsOnly] on raw strings first).
///
/// Handles common cases:
/// - India: strips leading `91` when the number includes country code (e.g. 12+ digits starting with `91`)
/// - US/Canada: strips leading `1` for 11-digit NANP numbers
/// - Trims repeated leading `0` when length would otherwise exceed typical national mobile length
String contactFilterCanonicalPhoneKey(String digitsOnly) {
  var x = digitsOnly;
  if (x.isEmpty) return '';

  while (x.startsWith('0') && x.length > 10) {
    x = x.substring(1);
  }

  if (x.startsWith('91') && x.length >= 12) {
    x = x.substring(2);
  } else if (x.startsWith('91') && x.length == 11) {
    x = x.substring(2);
  }

  if (x.length == 11 && x.startsWith('1')) {
    x = x.substring(1);
  }

  return x;
}

/// Raw string → canonical key (digits extract + normalize).
String contactFilterNormalizeRawToCanonical(String raw) {
  return contactFilterCanonicalPhoneKey(contactFilterDigitsOnly(raw));
}
