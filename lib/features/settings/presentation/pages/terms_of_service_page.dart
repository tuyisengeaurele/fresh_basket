import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Header(
            icon: Icons.article_rounded,
            title: 'Terms of Service',
            subtitle: 'Last updated: May 2026',
          ),
          const SizedBox(height: 24),
          _Section(
            title: '1. Acceptance of Terms',
            body:
                'By accessing or using FreshBasket, you agree to be bound by these Terms of Service. '
                'If you do not agree to all the terms, you may not use our services.',
          ),
          _Section(
            title: '2. Use of Service',
            body:
                'FreshBasket provides an online marketplace connecting buyers with fresh produce sellers '
                'in Rwanda. You agree to use the service only for lawful purposes and in a manner that '
                'does not infringe the rights of others.',
          ),
          _Section(
            title: '3. Seller Obligations',
            body:
                'Sellers must provide accurate product descriptions, prices, and stock levels. '
                'Products must meet Rwandan food safety standards. FreshBasket reserves the right to '
                'remove listings that violate these terms.',
          ),
          _Section(
            title: '4. Orders and Payments',
            body:
                'All transactions are conducted in Rwandan Francs (RWF). FreshBasket currently '
                'supports Cash on Delivery (CoD) only. Orders are binding once confirmed.',
          ),
          _Section(
            title: '5. Delivery',
            body:
                'Delivery times are estimates and may vary. FreshBasket is not liable for delays '
                'caused by factors outside our control, including traffic, weather, or seller delays.',
          ),
          _Section(
            title: '6. Returns and Refunds',
            body:
                'If you receive damaged or incorrect products, please contact our support team within '
                '24 hours of delivery at freshbasketrw@gmail.com or +250 780 605 880.',
          ),
          _Section(
            title: '7. Account Termination',
            body:
                'FreshBasket reserves the right to suspend or terminate accounts that violate these '
                'terms, engage in fraudulent activity, or harm other users.',
          ),
          _Section(
            title: '8. Changes to Terms',
            body:
                'We may update these terms at any time. Continued use of the service after changes '
                'constitutes acceptance of the new terms.',
          ),
          _Section(
            title: '9. Contact',
            body:
                'For questions about these terms, contact us at:\n'
                'Email: freshbasketrw@gmail.com\n'
                'Phone: +250 780 605 880',
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Header({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

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
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
