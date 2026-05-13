import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final notifsStream = NotificationService.notificationsStream(user.uid);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              TextButton(
                onPressed: () => _markAllRead(user.uid),
                child: const Text('Mark all read',
                    style: TextStyle(fontSize: 13, color: AppColors.primary)),
              ),
            ],
          ),
          body: StreamBuilder<List<NotificationModel>>(
            stream: notifsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
                  itemBuilder: (_, __) => const ListItemSkeleton(),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          size: 72, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text("You're all caught up!",
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (_, i) => _NotifTile(
                  notification: notifications[i],
                  onTap: () => NotificationService.markAsRead(notifications[i].id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _markAllRead(String userId) async {
    final snap = await FirebaseService.notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = FirebaseService.firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotifTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).cardColor
              : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: notification.isRead
              ? null
              : Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(notification.type), color: color, size: 22),
              ),
              // App icon badge (bottom-right)
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(notification.body,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(Formatters.relativeTime(notification.createdAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
      case NotificationType.orderDelivered:
        return AppColors.primary;
      case NotificationType.paymentReceived:
        return AppColors.accent;
      case NotificationType.promotion:
      case NotificationType.newProduct:
        return AppColors.warning;
      case NotificationType.systemAlert:
      case NotificationType.sellerApproved:
      case NotificationType.sellerRejected:
        return AppColors.info;
      case NotificationType.driverAssigned:
      case NotificationType.driverNearby:
        return AppColors.primary;
      case NotificationType.orderCancelled:
        return AppColors.error;
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
      case NotificationType.orderCancelled:
        return Icons.receipt_long_outlined;
      case NotificationType.paymentReceived:
        return Icons.payments_outlined;
      case NotificationType.promotion:
      case NotificationType.newProduct:
        return Icons.local_offer_outlined;
      case NotificationType.systemAlert:
      case NotificationType.sellerApproved:
      case NotificationType.sellerRejected:
        return Icons.info_outline_rounded;
      case NotificationType.driverAssigned:
      case NotificationType.driverNearby:
      case NotificationType.orderDelivered:
        return Icons.delivery_dining_rounded;
    }
  }
}
