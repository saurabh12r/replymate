import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/subscription/subscription_service.dart';

/// Shown when user is registered but not yet approved by admin/broker
class PendingApprovalView extends StatefulWidget {
  const PendingApprovalView({super.key});

  @override
  State<PendingApprovalView> createState() => _PendingApprovalViewState();
}

class _PendingApprovalViewState extends State<PendingApprovalView> {
  BrokerInfo? _brokerInfo;
  bool _loadingBroker = true;
  StreamSubscription? _sub;
  SubscriptionInfo? _subInfo;
  Timer? _scheduledActivationTimer;

  @override
  void initState() {
    super.initState();
    _loadBrokerInfo();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scheduledActivationTimer?.cancel();
    super.dispose();
  }

  void _loadBrokerInfo() {
    _sub = SubscriptionService.instance.stream.listen((subInfo) {
      if (subInfo.status == SubscriptionStatus.active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Get.offAllNamed(Routes.dashboard);
        });
        return;
      }

      if (mounted) {
        setState(() {
          _subInfo = subInfo;
        });
      }

      _scheduledActivationTimer?.cancel();
      if (subInfo.status == SubscriptionStatus.scheduled && subInfo.subscriptionStart != null) {
        final timeToStart = subInfo.subscriptionStart!.difference(DateTime.now());
        if (timeToStart.inMilliseconds > 0) {
          _scheduledActivationTimer = Timer(timeToStart, () {
            if (mounted) {
              Get.offAllNamed(Routes.splash);
            }
          });
        }
      }

      if (subInfo.brokerId != null) {
        SubscriptionService.instance.getBrokerInfo(subInfo.brokerId!).then((
          broker,
        ) {
          if (mounted) {
            setState(() {
              _brokerInfo = broker;
              _loadingBroker = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() => _loadingBroker = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2980).withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _subInfo?.status == SubscriptionStatus.scheduled
                      ? Icons.schedule_rounded
                      : Icons.hourglass_top_rounded,
                  size: 48,
                  color: const Color(0xFF1A2980),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _subInfo?.status == SubscriptionStatus.scheduled
                    ? 'Subscription Scheduled'
                    : 'Pending Approval',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _subInfo?.status == SubscriptionStatus.scheduled && _subInfo?.subscriptionStart != null
                    ? 'Your subscription is approved and scheduled to start on:\n${DateFormat('dd MMM yyyy').format(_subInfo!.subscriptionStart!.toLocal())}\n\nNo functionality will work until the start time is reached.'
                    : 'Your account has been registered successfully.\nYour admin or broker will activate it shortly.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_loadingBroker)
                const Center(child: CircularProgressIndicator())
              else if (_brokerInfo != null) ...[
                _ContactCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Your Broker',
                  name: _brokerInfo!.name,
                  subtitle: _brokerInfo!.brokerCode.isNotEmpty
                      ? 'Code: ${_brokerInfo!.brokerCode}'
                      : null,
                  phone: _brokerInfo!.phone,
                  email: _brokerInfo!.email,
                ),
                const SizedBox(height: 16),
              ] else ...[
                _InfoTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Contact Admin',
                  subtitle: 'Your account was created directly by admin',
                ),
                const SizedBox(height: 16),
              ],
              _InfoTile(
                icon: Icons.access_time_rounded,
                title: 'Usually within 24 hours',
                subtitle: 'Approvals are processed during business hours',
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAllNamed(Routes.login);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the user's subscription has expired
class SubscriptionExpiredView extends StatefulWidget {
  const SubscriptionExpiredView({super.key});

  @override
  State<SubscriptionExpiredView> createState() =>
      _SubscriptionExpiredViewState();
}

class _SubscriptionExpiredViewState extends State<SubscriptionExpiredView> {
  BrokerInfo? _brokerInfo;
  bool _loadingBroker = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadBrokerInfo();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _loadBrokerInfo() {
    _sub = SubscriptionService.instance.stream.listen((subInfo) {
      if (subInfo.brokerId != null) {
        SubscriptionService.instance.getBrokerInfo(subInfo.brokerId!).then((
          broker,
        ) {
          if (mounted) {
            setState(() {
              _brokerInfo = broker;
              _loadingBroker = false;
            });
          }
        });
      } else {
        if (mounted) {
          setState(() => _loadingBroker = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cs.error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.timer_off_rounded, size: 48, color: cs.error),
              ),
              const SizedBox(height: 28),
              Text(
                'Subscription Expired',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _brokerInfo != null
                    ? 'Your subscription has ended. Contact your broker to renew your plan.'
                    : 'Your subscription has ended. Contact your admin to renew your plan.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_loadingBroker)
                const Center(child: CircularProgressIndicator())
              else if (_brokerInfo != null) ...[
                _ContactCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Your Broker',
                  name: _brokerInfo!.name,
                  subtitle: _brokerInfo!.brokerCode.isNotEmpty
                      ? 'Code: ${_brokerInfo!.brokerCode}'
                      : null,
                  phone: _brokerInfo!.phone,
                  email: _brokerInfo!.email,
                ),
                const SizedBox(height: 16),
                _InfoTile(
                  icon: Icons.autorenew_rounded,
                  title: 'New Plan Coming',
                  subtitle: 'Your broker will assign a new plan shortly',
                ),
              ] else ...[
                _InfoTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Contact Admin',
                  subtitle: 'Your account was created directly by admin',
                ),
                const SizedBox(height: 16),
                _InfoTile(
                  icon: Icons.autorenew_rounded,
                  title: 'New Plan Coming',
                  subtitle: 'The admin will assign a new plan shortly',
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAllNamed(Routes.login);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withAlpha(100)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String name;
  final String? subtitle;
  final String? phone;
  final String? email;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.name,
    this.subtitle,
    this.phone,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (phone != null || email != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (phone != null)
              _ContactRow(icon: Icons.phone_outlined, value: phone!),
            if (email != null)
              _ContactRow(icon: Icons.email_outlined, value: email!),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Shown when the user has been blocked
class AccountBlockedView extends StatelessWidget {
  const AccountBlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: cs.error.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block_rounded, size: 48, color: cs.error),
              ),
              const SizedBox(height: 28),
              Text(
                'Account Suspended',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account has been suspended by the admin. Please contact support for assistance.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Get.offAllNamed(Routes.login);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withAlpha(100)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
