import 'package:flutter/material.dart';
import '../logs_nav/logs_nav_view.dart';

/// LogsTab — backward-compatible alias for LogsNavView.
/// The real implementation lives in `logs_nav/logs_nav_view.dart`.
/// This file is kept so any cached reference doesn't break.
class LogsTab extends StatelessWidget {
  const LogsTab({super.key});

  @override
  Widget build(BuildContext context) => const LogsNavView();
}
