import 'package:flutter/material.dart';
import '../analytics_nav/analytics_nav_view.dart';

/// AnalyticsTab — backward-compatible alias for AnalyticsNavView.
/// Real implementation lives in `analytics_nav/analytics_nav_view.dart`.
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) => const AnalyticsNavView();
}
