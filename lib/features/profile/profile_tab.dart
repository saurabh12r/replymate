import 'package:flutter/material.dart';
import '../profile_nav/profile_nav_view.dart';

/// ProfileTab — backward-compatible alias for ProfileNavView.
/// Real implementation lives in `profile_nav/profile_nav_view.dart`.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) => const ProfileNavView();
}
