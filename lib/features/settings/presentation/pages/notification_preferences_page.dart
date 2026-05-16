import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

// Simple local state — persisted via hive or shared prefs in a real app
final _notifPrefsProvider =
    StateNotifierProvider<_NotifPrefsNotifier, _NotifPrefs>(
  (ref) => _NotifPrefsNotifier(),
);

class _NotifPrefs {
  final bool orderUpdates;
  final bool promotions;
  final bool newProducts;
  final bool deliveryAlerts;
  final bool appUpdates;

  const _NotifPrefs({
    this.orderUpdates = true,
    this.promotions = true,
    this.newProducts = false,
    this.deliveryAlerts = true,
    this.appUpdates = false,
  });

  _NotifPrefs copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? newProducts,
    bool? deliveryAlerts,
    bool? appUpdates,
  }) =>
      _NotifPrefs(
        orderUpdates: orderUpdates ?? this.orderUpdates,
        promotions: promotions ?? this.promotions,
        newProducts: newProducts ?? this.newProducts,
        deliveryAlerts: deliveryAlerts ?? this.deliveryAlerts,
        appUpdates: appUpdates ?? this.appUpdates,
      );
}

class _NotifPrefsNotifier extends StateNotifier<_NotifPrefs> {
  _NotifPrefsNotifier() : super(const _NotifPrefs());

  void toggle(String key, bool value) {
    switch (key) {
      case 'orderUpdates':
        state = state.copyWith(orderUpdates: value);
        break;
      case 'promotions':
        state = state.copyWith(promotions: value);
        break;
      case 'newProducts':
        state = state.copyWith(newProducts: value);
        break;
      case 'deliveryAlerts':
        state = state.copyWith(deliveryAlerts: value);
        break;
      case 'appUpdates':
        state = state.copyWith(appUpdates: value);
        break;
    }
  }
}

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(_notifPrefsProvider);
    final notifier = ref.read(_notifPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.notifications_active_rounded,
                    color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose which notifications you want to receive from FreshBasket.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _NotifGroup(
            title: 'Orders',
            children: [
              _NotifTile(
                icon: Icons.receipt_long_rounded,
                title: 'Order Updates',
                subtitle: 'Confirmations, status changes and delivery info',
                value: prefs.orderUpdates,
                onChanged: (v) => notifier.toggle('orderUpdates', v),
              ),
              _NotifTile(
                icon: Icons.local_shipping_rounded,
                title: 'Delivery Alerts',
                subtitle: 'When your order is out for delivery or delivered',
                value: prefs.deliveryAlerts,
                onChanged: (v) => notifier.toggle('deliveryAlerts', v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _NotifGroup(
            title: 'Promotions & Products',
            children: [
              _NotifTile(
                icon: Icons.local_offer_rounded,
                title: 'Promotions & Offers',
                subtitle: 'Discounts, promo codes and special deals',
                value: prefs.promotions,
                onChanged: (v) => notifier.toggle('promotions', v),
              ),
              _NotifTile(
                icon: Icons.eco_rounded,
                title: 'New Products',
                subtitle: 'When new fresh items are added near you',
                value: prefs.newProducts,
                onChanged: (v) => notifier.toggle('newProducts', v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _NotifGroup(
            title: 'App',
            children: [
              _NotifTile(
                icon: Icons.system_update_rounded,
                title: 'App Updates',
                subtitle: 'News about new features and improvements',
                value: prefs.appUpdates,
                onChanged: (v) => notifier.toggle('appUpdates', v),
              ),
            ],
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification preferences saved'),
                  backgroundColor: AppColors.primary,
                ),
              );
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Preferences'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _NotifGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NotifGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: value ? AppColors.primary : AppColors.textHint, size: 22),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}
