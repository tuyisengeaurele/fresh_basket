import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/order_provider.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _actionLoading = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Order Detail')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: AppColors.textHint, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Unable to load order',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Make sure you are connected and have permission to view this order.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(orderDetailProvider(widget.orderId)),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (order) {
          if (order == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Order Detail')),
              body: const Center(child: Text('Order not found.')),
            );
          }

          final user = userAsync.value;
          final isDriver = user != null && user.uid == order.driverId;
          final isCustomer = user != null && user.uid == order.customerId;
          final isSeller = user != null && order.sellerIds.contains(user.uid);
          final isAdmin = user?.role == UserRole.admin;

          return Scaffold(
            appBar: AppBar(
              title: Text('Order ${order.orderNumber}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: 'Copy order ID',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: order.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order ID copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                // ── Scrollable content ──────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _StatusHeader(order: order),
                      const SizedBox(height: 16),
                      if (order.driverId != null) ...[
                        _DriverInfoCard(order: order),
                        const SizedBox(height: 16),
                      ],
                      _ItemsCard(order: order),
                      const SizedBox(height: 16),
                      _AddressCard(order: order),
                      const SizedBox(height: 16),
                      _PriceCard(order: order),
                      const SizedBox(height: 16),
                      _TimelineCard(order: order),
                      if (order.cancellationReason != null) ...[
                        const SizedBox(height: 16),
                        _CancellationCard(order: order),
                      ],
                      const SizedBox(height: 100), // room for bottom bar
                    ],
                  ),
                ),

                // ── Action bar ──────────────────────────────────────
                _ActionBar(
                  order: order,
                  isDriver: isDriver,
                  isCustomer: isCustomer,
                  isSeller: isSeller,
                  isAdmin: isAdmin,
                  loading: _actionLoading,
                  onDriverPickUp: () => _updateStatus(
                    order,
                    OrderStatus.pickedUp,
                    user!,
                    note: 'Order picked up from seller',
                  ),
                  onDriverDeliver: () => _confirmDelivery(order, user!),
                  onCustomerCancel: () => _confirmCancel(order, user!),
                  onTrack: () => context.push('/order/track/${order.id}'),
                  onRate: () => _showRatingSheet(order, user!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
    OrderModel order,
    OrderStatus newStatus,
    UserModel actor, {
    String? note,
    String? cancellationReason,
  }) async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            newStatus: newStatus,
            actorId: actor.uid,
            note: note,
            cancellationReason: cancellationReason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusSuccessMessage(newStatus)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _confirmDelivery(OrderModel order, UserModel actor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm that order ${order.orderNumber} has been delivered to ${order.customerName}?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Collect ${Formatters.currency(order.total)} cash on delivery.',
                      style: const TextStyle(
                          color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateStatus(order, OrderStatus.delivered, actor,
                  note: 'Order delivered to customer');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(OrderModel order, UserModel actor) {
    final _reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to cancel order ${order.orderNumber}?'),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Changed my mind',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              final reason = _reasonCtrl.text.trim();
              Navigator.of(ctx).pop();
              _updateStatus(order, OrderStatus.cancelled, actor,
                  note: 'Cancelled by customer',
                  cancellationReason: reason.isEmpty ? null : reason);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingSheet(OrderModel order, UserModel user) async {
    // Use a proper StatefulWidget for the sheet so the TextEditingController
    // is disposed through Flutter's normal widget lifecycle — NOT manually
    // after showModalBottomSheet returns. Calling dispose() manually causes a
    // crash because Flutter may still be rendering the closing animation frame.
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RatingSheet(
        order: order,
        onSubmit: (sellerStars, driverStars, comment) => _submitRating(
          order: order,
          user: user,
          sellerStars: sellerStars,
          driverStars: driverStars,
          comment: comment,
        ),
      ),
    );
  }

  Future<void> _submitRating({
    required OrderModel order,
    required UserModel user,
    required int sellerStars,
    required int driverStars,
    required String comment,
  }) async {
    try {
      final sellerId =
          order.sellerIds.isNotEmpty ? order.sellerIds.first : null;

      // Save review document
      await FirebaseService.reviews.add({
        'orderId': order.id,
        'userId': user.uid,
        'sellerId': sellerId,
        'sellerRating': sellerStars.toDouble(),
        'driverId': order.driverId,
        'driverRating':
            order.driverId != null ? driverStars.toDouble() : null,
        'comment': comment.isEmpty ? null : comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update seller profile rating
      if (sellerId != null) {
        final sellerDoc =
            await FirebaseService.sellerProfiles.doc(sellerId).get();
        if (sellerDoc.exists) {
          final d = sellerDoc.data()!;
          final oldRating = (d['rating'] as num?)?.toDouble() ?? 0.0;
          final totalReviews = (d['totalReviews'] as num?)?.toInt() ?? 0;
          final newRating =
              (oldRating * totalReviews + sellerStars) / (totalReviews + 1);
          await FirebaseService.sellerProfiles.doc(sellerId).update({
            'rating': double.parse(newRating.toStringAsFixed(1)),
            'totalReviews': FieldValue.increment(1),
          });
        }
      }

      // Update driver profile rating
      if (order.driverId != null) {
        final driverDoc = await FirebaseService.driverProfiles
            .doc(order.driverId!)
            .get();
        if (driverDoc.exists) {
          final d = driverDoc.data()!;
          final oldRating = (d['rating'] as num?)?.toDouble() ?? 0.0;
          final totalDel =
              (d['totalDeliveries'] as num?)?.toInt() ?? 1;
          // Use totalDeliveries as denominator for running average
          final newRating =
              (oldRating * (totalDel - 1) + driverStars) / totalDel;
          await FirebaseService.driverProfiles.doc(order.driverId!).update({
            'rating': double.parse(newRating.toStringAsFixed(1)),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _statusSuccessMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pickedUp:
        return 'Pick-up confirmed!';
      case OrderStatus.delivered:
        return 'Order marked as delivered!';
      case OrderStatus.cancelled:
        return 'Order cancelled.';
      default:
        return 'Status updated.';
    }
  }
}

// ── Status header ──────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  final OrderModel order;
  const _StatusHeader({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return AppColors.error;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return AppColors.statusInTransit;
      case OrderStatus.preparing:
        return AppColors.info;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      default:
        return AppColors.warning;
    }
  }

  IconData get _statusIcon {
    switch (order.status) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.assigned:
        return Icons.person_pin_circle_rounded;
      case OrderStatus.pickedUp:
        return Icons.inventory_2_outlined;
      case OrderStatus.onTheWay:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_statusIcon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(Formatters.dateTime(order.createdAt),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: color.withOpacity(0.2), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderStat(
                label: 'Items',
                value: '${order.items.length}',
                icon: Icons.shopping_basket_outlined,
                color: color,
              ),
              _HeaderStat(
                label: 'Total',
                value: Formatters.currency(order.total),
                icon: Icons.payments_outlined,
                color: color,
              ),
              _HeaderStat(
                label: 'Payment',
                value: 'Cash on Delivery',
                icon: Icons.point_of_sale_rounded,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _HeaderStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Driver info ────────────────────────────────────────────────────────────────

class _DriverInfoCard extends StatelessWidget {
  final OrderModel order;
  const _DriverInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Driver',
      icon: Icons.delivery_dining_rounded,
      iconColor: AppColors.roleDriver,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.roleDriver.withOpacity(0.12),
            child: Text(
              (order.driverName ?? 'D')[0].toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.roleDriver,
                  fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.driverName ?? 'Driver',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (order.driverPhone != null)
                  Text(order.driverPhone!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (order.driverPhone != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.phone_outlined,
                    color: AppColors.primary, size: 20),
                onPressed: () async {
                  final digits =
                      order.driverPhone!.replaceAll(RegExp(r'\s+'), '');
                  final uri = Uri(scheme: 'tel', path: digits);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
                tooltip: 'Call driver',
              ),
            ),
        ],
      ),
    );
  }
}

// ── Items ──────────────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final OrderModel order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Items (${order.items.length})',
      icon: Icons.shopping_basket_outlined,
      iconColor: AppColors.primary,
      child: Column(
        children: order.items.map((item) => _ItemRow(item: item)).toList(),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.productImageUrl.isNotEmpty
                ? Image.network(item.productImageUrl,
                    width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackImage())
                : _fallbackImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${item.quantity} × ${Formatters.currency(item.price)} / ${item.unit}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                Text('From ${item.sellerBusinessName}',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text(Formatters.currency(item.subtotal),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_basket_outlined,
          color: AppColors.primary, size: 20),
    );
  }
}

// ── Delivery address ───────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final OrderModel order;
  const _AddressCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final addr = order.deliveryAddress;
    return _Card(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      iconColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(addr.label,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11)),
              ),
              if (addr.isDefault) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Default',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(addr.fullAddress,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13, height: 1.4)),
          if (addr.instructions != null && addr.instructions!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(addr.instructions!,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          // Customer info
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(order.customerName,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              if (order.customerPhone.isNotEmpty) ...[
                const Text(' · ',
                    style: TextStyle(color: AppColors.textHint)),
                Text(order.customerPhone,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Price breakdown ────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final OrderModel order;
  const _PriceCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Price Breakdown',
      icon: Icons.receipt_long_outlined,
      iconColor: AppColors.info,
      child: Column(
        children: [
          _PriceRow('Subtotal', order.subtotal),
          _PriceRow('Delivery Fee', order.deliveryFee),
          if (order.discount > 0)
            _PriceRow('Discount', -order.discount, highlight: AppColors.success),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(Formatters.currency(order.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary)),
            ],
          ),
          if (order.promoCode != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Promo: ${order.promoCode}',
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments_outlined,
                    color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Text('Payment: Cash on Delivery',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color? highlight;
  const _PriceRow(this.label, this.amount, {this.highlight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(
            amount < 0
                ? '-${Formatters.currency(amount.abs())}'
                : Formatters.currency(amount),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: highlight ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ───────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final OrderModel order;
  const _TimelineCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final events = order.timeline.reversed.toList();
    return _Card(
      title: 'Order Timeline',
      icon: Icons.timeline_rounded,
      iconColor: AppColors.accent,
      child: Column(
        children: List.generate(events.length, (i) {
          final event = events[i];
          final isFirst = i == 0;
          return _TimelineEvent(
            event: event,
            isFirst: isFirst,
            isLast: i == events.length - 1,
          );
        }),
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final OrderTimeline event;
  final bool isFirst;
  final bool isLast;
  const _TimelineEvent(
      {required this.event, required this.isFirst, required this.isLast});

  Color get _dotColor {
    if (isFirst) return AppColors.primary;
    switch (event.status) {
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return AppColors.error;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return AppColors.statusInTransit;
      default:
        return AppColors.textHint;
    }
  }

  String get _statusLabel {
    switch (event.status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.assigned:
        return 'Driver Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: _dotColor.withOpacity(0.3), blurRadius: 4)
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.dividerLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_statusLabel,
                      style: TextStyle(
                          fontWeight:
                              isFirst ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                          color: isFirst
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  if (event.note != null) ...[
                    const SizedBox(height: 2),
                    Text(event.note!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                  const SizedBox(height: 2),
                  Text(Formatters.dateTime(event.timestamp),
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancellation reason ────────────────────────────────────────────────────────

class _CancellationCard extends StatelessWidget {
  final OrderModel order;
  const _CancellationCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cancellation Reason',
                    style: TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(order.cancellationReason!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action bar (sticky bottom) ─────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final OrderModel order;
  final bool isDriver;
  final bool isCustomer;
  final bool isSeller;
  final bool isAdmin;
  final bool loading;
  final VoidCallback onDriverPickUp;
  final VoidCallback onDriverDeliver;
  final VoidCallback onCustomerCancel;
  final VoidCallback onTrack;
  final VoidCallback onRate;

  const _ActionBar({
    required this.order,
    required this.isDriver,
    required this.isCustomer,
    required this.isSeller,
    required this.isAdmin,
    required this.loading,
    required this.onDriverPickUp,
    required this.onDriverDeliver,
    required this.onCustomerCancel,
    required this.onTrack,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    // ── Driver actions ─────────────────────────────────────────
    if (isDriver && order.isActive) {
      if (order.status == OrderStatus.assigned) {
        buttons.add(_ActionButton(
          label: 'Confirm Pick Up',
          icon: Icons.inventory_2_outlined,
          color: AppColors.info,
          loading: loading,
          onPressed: onDriverPickUp,
        ));
      } else if (order.status == OrderStatus.pickedUp ||
          order.status == OrderStatus.onTheWay) {
        buttons.add(_ActionButton(
          label: 'Mark as Delivered',
          icon: Icons.task_alt_rounded,
          color: AppColors.success,
          loading: loading,
          onPressed: onDriverDeliver,
        ));
      }
    }

    // ── Customer actions ───────────────────────────────────────
    if (isCustomer) {
      if (order.isActive) {
        buttons.add(_ActionButton(
          label: 'Track Order',
          icon: Icons.map_outlined,
          color: AppColors.primary,
          outlined: true,
          loading: false,
          onPressed: onTrack,
        ));
      }
      if (order.canBeCancelled) {
        buttons.add(_ActionButton(
          label: 'Cancel Order',
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          outlined: true,
          loading: loading,
          onPressed: onCustomerCancel,
        ));
      }
      if (order.status == OrderStatus.delivered) {
        buttons.add(_ActionButton(
          label: 'Rate Experience',
          icon: Icons.star_outline_rounded,
          color: AppColors.warning,
          loading: false,
          onPressed: onRate,
        ));
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
              color: AppColors.dividerLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: buttons
            .map((b) => Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    child: b,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool loading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.outlined = false,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          minimumSize: const Size(0, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child,
    );
  }
}

// ── Rating sheet (StatefulWidget so TextEditingController is lifecycle-managed) ─

class _RatingSheet extends StatefulWidget {
  final OrderModel order;
  final void Function(int sellerStars, int driverStars, String comment) onSubmit;

  const _RatingSheet({required this.order, required this.onSubmit});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _sellerStars = 5;
  int _driverStars = 5;
  // Controller created and disposed inside this widget — safe lifecycle
  late final TextEditingController _commentCtrl;

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Rate Your Experience',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),

          // Seller rating
          if (widget.order.items.isNotEmpty) ...[
            Text(
              'Seller: ${widget.order.items.first.sellerBusinessName}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _StarRating(
              value: _sellerStars,
              onChanged: (v) => setState(() => _sellerStars = v),
            ),
            const SizedBox(height: 16),
          ],

          // Driver rating
          if (widget.order.driverId != null) ...[
            Text(
              'Driver: ${widget.order.driverName ?? "Driver"}',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _StarRating(
              value: _driverStars,
              onChanged: (v) => setState(() => _driverStars = v),
            ),
            const SizedBox(height: 16),
          ],

          // Comment
          TextField(
            controller: _commentCtrl,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              border: OutlineInputBorder(),
              hintText: 'Share your experience...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final comment = _commentCtrl.text.trim();
                Navigator.of(context).pop(); // close sheet first
                widget.onSubmit(_sellerStars, _driverStars, comment);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Rating',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Star rating widget ─────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  final int value;
  final void Function(int) onChanged;
  const _StarRating({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              star <= value
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: AppColors.warning,
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}

// ── Reusable card wrapper ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _Card({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }
}
// Rating submitted via Firestore transaction on seller_profiles and driver_profiles
