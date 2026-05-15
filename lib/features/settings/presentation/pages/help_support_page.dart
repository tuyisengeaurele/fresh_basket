import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent_rounded, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our support team is available Mon–Sat, 8 AM – 6 PM (CAT)',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const _SectionLabel(text: 'Contact Us'),
          const SizedBox(height: 12),

          _ContactTile(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'freshbasketrw@gmail.com',
            onTap: () => launchUrl(Uri.parse('mailto:freshbasketrw@gmail.com')),
          ),
          _ContactTile(
            icon: Icons.phone_outlined,
            title: 'Call Us',
            subtitle: '+250 780 605 880',
            onTap: () => launchUrl(Uri.parse('tel:+250780605880')),
          ),
          _ContactTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'WhatsApp',
            subtitle: 'Chat with us on WhatsApp',
            onTap: () => launchUrl(Uri.parse('https://wa.me/250780605880')),
          ),

          const SizedBox(height: 28),
          const _SectionLabel(text: 'Frequently Asked Questions'),
          const SizedBox(height: 8),

          _FaqTile(
            question: 'How do I place an order?',
            answer:
                'Browse products on the Home or Shop tab, tap a product to view details, adjust quantity, then tap "Add to Cart". When ready, go to Cart and proceed to checkout.',
          ),
          _FaqTile(
            question: 'What payment methods are accepted?',
            answer:
                'FreshBasket currently accepts Cash on Delivery (COD) only. Mobile money and card payments are coming soon.',
          ),
          _FaqTile(
            question: 'How long does delivery take?',
            answer:
                'Same-day delivery is available for orders placed before 2 PM. Orders placed after 2 PM are delivered the next business day.',
          ),
          _FaqTile(
            question: 'Can I cancel or modify my order?',
            answer:
                'You can cancel an order while it is still in "Pending" status. Go to My Orders, tap the order, and tap "Cancel Order". Once confirmed, cancellation is not possible.',
          ),
          _FaqTile(
            question: 'How do I become a seller?',
            answer:
                'Register an account and select "Seller" as your role. Complete the seller registration form. Your application will be reviewed within 24 hours.',
          ),
          _FaqTile(
            question: 'My order arrived with missing/damaged items. What now?',
            answer:
                'Please contact our support team within 24 hours of delivery with photos of the issue. We will arrange a replacement or refund.',
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dividerLight),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.green50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.dividerLight),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.primary,
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
