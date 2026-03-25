/// Analytics dashboard period (Daily / Weekly / Monthly).
enum AnalyticsFilter {
  daily,
  weekly,
  monthly,
}

extension AnalyticsFilterX on AnalyticsFilter {
  String get label {
    switch (this) {
      case AnalyticsFilter.daily:
        return 'Daily';
      case AnalyticsFilter.weekly:
        return 'Weekly';
      case AnalyticsFilter.monthly:
        return 'Monthly';
    }
  }
}
