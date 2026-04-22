import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/orders/data/repositories/order_repository.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/status_chip.dart';

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() =>
      _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage> {
  bool _isAvailable = false;
  bool _availabilityLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAvailability());
  }

  Future<void> _loadAvailability() async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) {
      if (mounted) setState(() => _availabilityLoading = false);
      return;
    }
    try {
      final doc = await FirebaseService.driverProfiles.doc(user.uid).get();
      if (mounted) {
        setState(() {
          _isAvailable = doc.data()?['isAvailable'] ?? false;
          _availabilityLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _availabilityLoading = false);
    }
  }

  Future<void> _setAvailability(String uid, bool value) async {
    setState(() => _isAvailable = value);
    try {
      await FirebaseService.driverProfiles.doc(uid).update({
        'isAvailable': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Revert on failure
      if (mounted) setState(() => _isAvailable = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    if (user == null) return const SizedBox.shrink();

    final deliveriesAsync = ref.watch(driverOrdersProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          // Availability toggle
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _availabilityLoading
                      ? ''
                      : _isAvailable
                          ? 'Online'
                          : 'Offline',
                  key: ValueKey(_isAvailable),
                  style: TextStyle(
                    fontSize: 13,
                    color: _isAvailable ? AppColors.success : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_availabilityLoading)
                const SizedBox(
                  width: 36,
                  height: 20,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                CupertinoSwitch(
                  value: _isAvailable,
                  onChanged: (v) => _setAvailability(user.uid, v),
                  activeColor: AppColors.success,
                ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: deliveriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (deliveries) {
          final active = deliveries
              .where((o) =>
                  o.status == OrderStatus.assigned ||
                  o.status == OrderStatus.pickedUp ||
                  o.status == OrderStatus.onTheWay)
              .toList();
          final completed =
              deliveries.where((o) => o.status == OrderStatus.delivered).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats
                      _DriverStats(
                        activeCount: active.length,
                        completedCount: completed.length,
                        earnings: deliveries
                            .where((o) => o.status == OrderStatus.delivered)
                            .fold<double>(0.0, (s, o) => s + o.deliveryFee),
                      ),
                      const SizedBox(height: AppDimensions.lg),

                      // Active deliveries
                      if (active.isNotEmpty) ...[
                        const Text(
                          'Active Deliveries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...active.asMap().entries.map(
                          (e) => _DeliveryCard(
                            order: e.value,
                            index: e.key,
                            isActive: true,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.lg),
                      ],

                      // Recent
                      if (deliveries.isNotEmpty)
                        const Text(
                          'Recent Deliveries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 12),
                      ...deliveries
                          .where((o) =>
                              o.status != OrderStatus.assigned &&
                              o.status != OrderStatus.pickedUp &&
                              o.status != OrderStatus.onTheWay)
                          .take(10)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (e) => _DeliveryCard(
                              order: e.value,
                              index: e.key,
                              isActive: false,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DriverStats extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final double earnings;

  const _DriverStats({
    required this.activeCount,
    required this.completedCount,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          label: 'Active',
          value: '$activeCount',
          color: AppColors.accent,
          index: 0,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Completed',
          value: '$completedCount',
          color: AppColors.primary,
          index: 1,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Earnings',
          value: 'RWF\n${Formatters.compact(earnings)}',
          color: AppColors.info,
          index: 2,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final int index;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.2),
    );
  }
}

class _DeliveryCard extends ConsumerWidget {
  final OrderModel order;
  final int index;
  final bool isActive;

  const _DeliveryCard({
    required this.order,
    required this.index,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push(
        RouteNames.driverDeliveryDetail.replaceFirst(':id', order.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: isActive
              ? Border.all(color: AppColors.accent.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                StatusChip(status: order.status, small: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.deliveryAddress.fullAddress,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (order.status == OrderStatus.assigned)
                    Expanded(
                      child: _ActionBtn(
                        label: 'Mark Picked Up',
                        color: AppColors.accent,
                        onTap: () => ref
                            .read(orderRepositoryProvider)
                            .updateOrderStatus(
                              orderId: order.id,
                              newStatus: OrderStatus.pickedUp,
                              actorId: order.driverId ?? '',
                              note: 'Order picked up by driver',
                            ),
                      ),
                    ),
                  if (order.status == OrderStatus.pickedUp ||
                      order.status == OrderStatus.onTheWay) ...[
                    Expanded(
                      child: _ActionBtn(
                        label: 'Navigate',
                        color: AppColors.info,
                        icon: Icons.navigation_rounded,
                        onTap: () => context.push(
                          RouteNames.driverNavigation
                              .replaceFirst(':orderId', order.id),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionBtn(
                        label: 'Delivered',
                        color: AppColors.primary,
                        icon: Icons.check_rounded,
                        onTap: () => _confirmDelivered(context, ref, order),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 60))
          .fadeIn(duration: 300.ms),
    );
  }

  void _confirmDelivered(
      BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      // Use 'ctx' (the dialog's own context) for Navigator.pop — using the
      // outer page context would pop the GoRouter page instead of the dialog,
      // leaving an empty navigator stack and causing a black screen.
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mark this order as delivered?'),
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
                  const Icon(Icons.payments_outlined,
                      color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Collect ${Formatters.currency(order.total)} cash on delivery.',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
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
              ref.read(orderRepositoryProvider).updateOrderStatus(
                    orderId: order.id,
                    newStatus: OrderStatus.delivered,
                    actorId: order.driverId ?? '',
                    note: 'Delivered by driver',
                  );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('Confirm Delivery'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
