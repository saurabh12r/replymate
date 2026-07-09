import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const BackButtonIcon(),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: May 2026',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: '1. Introduction',
              content:
                  'ReplyMate ("we," "our," or "us") respects your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.\n\nBy using ReplyMate, you consent to the practices described in this policy.',
            ),
            _Section(
              title: '2. Information We Collect',
              content: '''We collect the following types of information:

• Personal Information: Name, phone number, email address when you register
• Account Data: Subscription status, plan details, approval status
• Usage Data: Message logs, reply analytics, feature usage patterns
• Device Information: Device type, OS version, app version''',
            ),
            _Section(
              title: '3. How We Use Your Information',
              content: '''We use your information to:

• Provide and maintain our services
• Process your subscription and manage accounts
• Send you important updates about your account
• Improve and personalize your experience
• Comply with legal obligations
• Prevent fraud and ensure security''',
            ),
            _Section(
              title: '4. Data Sharing & Disclosure',
              content: '''We may share your information with:

• Service Providers: Companies that help us operate our services (e.g., cloud storage, SMS gateways)
• Business Partners: Brokers who refer you to our service (if applicable)
• Legal Authorities: When required by law or to protect our rights

We never sell your personal information to third parties.''',
            ),
            _Section(
              title: '5. Data Security',
              content:
                  'We implement appropriate technical and organizational security measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            _Section(
              title: '6. Data Retention',
              content:
                  'We retain your personal information as long as your account is active or as needed to provide you services. We will delete or anonymize your data when it is no longer necessary for the purposes outlined in this policy.',
            ),
            _Section(
              title: '7. Your Rights',
              content: '''You have the right to:

• Access your personal data
• Correct inaccurate data
• Request deletion of your data
• Object to processing of your data
• Export your data in a portable format

To exercise these rights, please contact us through the app.''',
            ),
            _Section(
              title: '8. Children\'s Privacy',
              content:
                  'Our services are not intended for individuals under the age of 18. We do not knowingly collect personal information from children.',
            ),
            _Section(
              title: '9. Third-Party Services',
              content:
                  'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies.',
            ),
            _Section(
              title: '10. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy on this page and updating the "Last Updated" date. Your continued use of ReplyMate after changes constitutes acceptance of the new policy.',
            ),
            _Section(
              title: '11. Contact Us',
              content:
                  'If you have any questions or concerns about this Privacy Policy, please contact us:\n\nEmail: support@replymate.app\n\nThank you for using ReplyMate!',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 ReplyMate. All rights reserved.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;

  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
