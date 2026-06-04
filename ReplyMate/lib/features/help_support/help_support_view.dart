import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/subscription/subscription_service.dart';

class HelpSupportView extends StatefulWidget {
  const HelpSupportView({super.key});

  @override
  State<HelpSupportView> createState() => _HelpSupportViewState();
}

class _HelpSupportViewState extends State<HelpSupportView> {
  BrokerInfo? _brokerInfo;
  AdminSettings? _adminSettings;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final subInfo = await SubscriptionService.instance.stream.first;

    if (subInfo.brokerId != null) {
      final broker = await SubscriptionService.instance.getBrokerInfo(
        subInfo.brokerId!,
      );
      if (mounted) setState(() => _brokerInfo = broker);
    }

    final adminSettings = await SubscriptionService.instance.getAdminSettings();
    if (mounted) {
      setState(() {
        _adminSettings = adminSettings;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help you?',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a topic below or contact us directly',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _TopicCard(
                    icon: Icons.help_outline_rounded,
                    title: 'FAQs',
                    subtitle: 'Find answers to common questions',
                    color: const Color(0xFF24389C),
                    onTap: () => _showFaqDialog(context),
                  ),

                  const SizedBox(height: 32),

                  if (_brokerInfo != null) ...[
                    _ContactSection(
                      title: 'Your Broker',
                      subtitle: 'Contact your broker for quick assistance',
                      icon: Icons.person_outline_rounded,
                      name: _brokerInfo!.name,
                      phone: _brokerInfo!.phone,
                      email: _brokerInfo!.email,
                      brokerCode: _brokerInfo!.brokerCode,
                    ),
                    const SizedBox(height: 20),
                  ],

                  _ContactSection(
                    title: _brokerInfo != null ? 'Admin Support' : 'Admin',
                    subtitle: _brokerInfo != null
                        ? 'Contact admin for additional help'
                        : 'Contact admin for assistance',
                    icon: Icons.admin_panel_settings_outlined,
                    name: 'ReplyMate Admin',
                    email: _adminSettings?.supportEmail,
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primaryContainer,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Our support team typically responds within 24 hours on business days.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showFaqDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Frequently Asked Questions',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: const [
                  _FaqItem(
                    question: 'How do I activate my account?',
                    answer:
                        'Your account will be activated by your admin or broker after registration. Contact them if you haven\'t received activation within 24 hours.',
                  ),
                  _FaqItem(
                    question: 'How does the auto-reply work?',
                    answer:
                        'When enabled, ReplyMate automatically replies to incoming messages based on your configured filters and keywords.',
                  ),
                  _FaqItem(
                    question: 'Can I change my plan?',
                    answer:
                        'Contact your admin or broker to upgrade or change your subscription plan.',
                  ),
                  _FaqItem(
                    question: 'What happens when my subscription expires?',
                    answer:
                        'You\'ll see an expiration screen. Contact your broker or admin to renew your subscription.',
                  ),
                  _FaqItem(
                    question: 'How do I add contacts for auto-reply?',
                    answer:
                        'Go to Profile → Contacts to configure who should receive auto-replies.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TopicCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String name;
  final String? phone;
  final String? email;
  final String? brokerCode;

  const _ContactSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.name,
    this.phone,
    this.email,
    this.brokerCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF24389C).withAlpha(15),
            const Color(0xFF1A2980).withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF24389C).withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF24389C), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF24389C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (brokerCode != null) ...[
            const SizedBox(height: 4),
            Text(
              'Code: $brokerCode',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (phone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Color(0xFF24389C),
                ),
                const SizedBox(width: 6),
                Text(phone!, style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
          ],
          if (email != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: Color(0xFF24389C),
                ),
                const SizedBox(width: 6),
                Text(email!, style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
