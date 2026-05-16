import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _PolicyHeader(),
          SizedBox(height: 24),
          _PolicySection(
            title: '1. Information We Collect',
            content:
                'We collect information you provide directly to us when you create an account, '
                'place an order, or contact support. This includes:\n\n'
                '• Name, email address, and phone number\n'
                '• Delivery addresses and location data (when you use location features)\n'
                '• Order history and product preferences\n'
                '• Device information and usage data',
          ),
          _PolicySection(
            title: '2. How We Use Your Information',
            content:
                'We use the information we collect to:\n\n'
                '• Process and deliver your orders\n'
                '• Send order confirmations and delivery updates\n'
                '• Improve our platform and personalise your experience\n'
                '• Respond to your comments and questions\n'
                '• Send promotional communications (you may opt out at any time)',
          ),
          _PolicySection(
            title: '3. Information Sharing',
            content:
                'We do not sell or rent your personal information to third parties. '
                'We may share your information with:\n\n'
                '• Delivery drivers to complete your orders\n'
                '• Sellers to fulfil the items you purchased\n'
                '• Service providers who assist in our operations\n'
                '• Law enforcement when required by law',
          ),
          _PolicySection(
            title: '4. Location Data',
            content:
                'We request location permission to help you find nearby sellers, '
                'detect your delivery address automatically, and show accurate delivery estimates. '
                'Location data is used only while the app is in use and is never sold to third parties.',
          ),
          _PolicySection(
            title: '5. Data Security',
            content:
                'We implement industry-standard security measures to protect your personal '
                'information, including encryption in transit (HTTPS/TLS) and at rest. '
                'However, no method of transmission over the Internet is 100% secure.',
          ),
          _PolicySection(
            title: '6. Data Retention',
            content:
                'We retain your account information for as long as your account is active. '
                'You may request deletion of your account and associated data by contacting '
                'support@freshbasket.rw. Order records may be retained for legal and tax purposes.',
          ),
          _PolicySection(
            title: '7. Your Rights',
            content:
                'You have the right to:\n\n'
                '• Access the personal data we hold about you\n'
                '• Correct inaccurate information\n'
                '• Request deletion of your account\n'
                '• Opt out of marketing communications\n\n'
                'To exercise these rights, contact us at support@freshbasket.rw.',
          ),
          _PolicySection(
            title: '8. Changes to This Policy',
            content:
                'We may update this Privacy Policy from time to time. We will notify you '
                'of significant changes via the app or email. Continued use of FreshBasket '
                'after changes constitutes acceptance of the updated policy.',
          ),
          _PolicySection(
            title: '9. Contact Us',
            content:
                'If you have questions about this Privacy Policy, please contact us:\n\n'
                'FreshBasket Rwanda\n'
                'Email: freshbasketrw@gmail.com\n'
                'Phone: +250 780 605 880\n'
                'Address: KG 123 St, Gasabo, Kigali, Rwanda',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Last updated: May 2026',
          style: TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
        const SizedBox(height: 12),
        const Text(
          'FreshBasket ("we", "us", or "our") is committed to protecting your privacy. '
          'This policy explains how we collect, use, and safeguard your personal information '
          'when you use our app.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
