/// Local storage values: ALL, ONLY, EXCLUDE.
enum ContactFilterMode {
  all,
  onlySelected,
  excludeSelected;

  String get storageValue => switch (this) {
        ContactFilterMode.all => 'ALL',
        ContactFilterMode.onlySelected => 'ONLY',
        ContactFilterMode.excludeSelected => 'EXCLUDE',
      };

  static ContactFilterMode fromStorage(String? raw) {
    switch (raw) {
      case 'ONLY':
        return ContactFilterMode.onlySelected;
      case 'EXCLUDE':
        return ContactFilterMode.excludeSelected;
      default:
        return ContactFilterMode.all;
    }
  }
}
