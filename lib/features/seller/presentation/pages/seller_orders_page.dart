import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../orders/presentation/providers/order_provider.dart';

class SellerOrdersPage extends ConsumerStatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  ConsumerState<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends ConsumerState<SellerOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['All', 'Pending', 'Confirmed', 'Preparing', 'Done'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final ordersAsync = ref.watch(sellerOrdersProvider(user.uid));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Orders'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          body: ordersAsync.when(
            loading: () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (_, __) => const ListItemSkeleton(),
            ),
            error: (e, _) => QueryErrorView(
              error: e,
              onRetry: () => ref.invalidate(sellerOrdersProvider(user.uid)),
            ),
            data: (orders) => TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filterOrders(orders, tab);
                if (filtered.isEmpty) {
                  return _EmptyOrders(tab: tab);
                }
                return _OrdersList(orders: filtered);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, String tab) {
    switch (tab) {
      case 'Pending':
        return orders.where((o) => o.status == OrderStatus.pending).toList();
      case 'Confirmed':
        return orders.where((o) => o.status == OrderStatus.confirmed).toList();
      case 'Preparing':
        return orders.where((o) => o.status == OrderStatus.preparing).toList();
      case 'Done':
        return orders
            .where((o) =>
                o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled)
            .toList();
      default:
        return orders;
    }
  }
}

class _OrdersList extends ConsumerWidget {
  final List<OrderModel> orders;
  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderCard(order: orders[i]),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.customerName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dateTime(order.createdAt),
                        style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusChip(status: order.status),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.currency(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.green50.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (order.status == OrderStatus.pending)
                  _DeclineButton(order: order),
                if (order.status == OrderStatus.pending)
                  const SizedBox(width: 8),
                if (_nextStatus(order.status) != null)
                  _ActionButton(order: order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  OrderStatus? _nextStatus(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return OrderStatus.confirmed;
      case OrderStatus.confirmed:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.assigned;
      default:
        return null;
    }
  }
}

class _ActionButton extends ConsumerWidget {
  final OrderModel order;
  const _ActionButton({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "preparing" → open driver picker instead of direct status update
    if (order.status == OrderStatus.preparing) {
      return TextButton(
        onPressed: () => _showDriverPicker(context, ref, order),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delivery_dining_rounded, size: 14),
            SizedBox(width: 4),
            Text('Assign Driver', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    OrderStatus? next;
    String label = '';
    switch (order.status) {
      case OrderStatus.pending:
        next = OrderStatus.confirmed;
        label = 'Confirm';
        break;
      case OrderStatus.confirmed:
        next = OrderStatus.preparing;
        label = 'Start Preparing';
        break;
      default:
        break;
    }

    if (next == null) return const SizedBox.shrink();

    return TextButton(
      onPressed: () async {
        try {
          await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            newStatus: next!,
            actorId: FirebaseService.currentUid ?? '',
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update order: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _showDriverPicker(BuildContext ctx, WidgetRef ref, OrderModel order) {

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DriverPickerSheet(order: order),
    );
  }
}

// ── Decline Button ────────────────────────────────────────────────────────────

class _DeclineButton extends ConsumerStatefulWidget {
  final OrderModel order;
  const _DeclineButton({required this.order});

  @override
  ConsumerState<_DeclineButton> createState() => _DeclineButtonState();
}

class _DeclineButtonState extends ConsumerState<_DeclineButton> {
  bool _loading = false;

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Decline Order'),
        content: Text(
          'Decline order ${widget.order.orderNumber}? The customer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
        orderId: widget.order.id,
        newStatus: OrderStatus.cancelled,
        actorId: FirebaseService.currentUid ?? '',
        note: 'Declined by seller',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _loading ? null : _decline,
      style: TextButton.styleFrom(
        backgroundColor: AppColors.error.withOpacity(0.1),
        foregroundColor: AppColors.error,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _loading
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            )
          : const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Driver Picker ─────────────────────────────────────────────────────────────

class _AvailableDriver {
  final DriverProfile profile;
  final UserModel user;
  const _AvailableDriver({required this.profile, required this.user});
}

class _DriverPickerSheet extends ConsumerStatefulWidget {
  final OrderModel order;
  const _DriverPickerSheet({required this.order});

  @override
  ConsumerState<_DriverPickerSheet> createState() => _DriverPickerSheetState();
}

class _DriverPickerSheetState extends ConsumerState<_DriverPickerSheet> {
  List<_AvailableDriver>? _drivers;
  String? _error;
  String? _assigningId;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      // Fetch ALL driver profiles then filter client-side — avoids Firestore
      // collection-query permission issues when isAvailable filter is applied.
      final snap = await FirebaseService.driverProfiles.get();

      final drivers = <_AvailableDriver>[];
      for (final doc in snap.docs) {
        try {
          final profile = DriverProfile.fromFirestore(doc);
          if (!profile.isAvailable) continue; // filter client-side
          final userDoc = await FirebaseService.users.doc(profile.uid).get();
          if (userDoc.exists) {
            drivers.add(_AvailableDriver(
              profile: profile,
              user: UserModel.fromFirestore(userDoc),
            ));
          }
        } catch (_) {}
      }

      if (mounted) setState(() => _drivers = drivers);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _assign(_AvailableDriver driver) async {
    if (_assigningId != null) return;
    setState(() => _assigningId = driver.profile.uid);
    try {
      await ref.read(orderRepositoryProvider).assignDriver(
        orderId: widget.order.id,
        driverId: driver.profile.uid,
        driverName: driver.user.fullName,
        driverPhone: driver.user.phone ?? '',
        customerId: widget.order.customerId,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${driver.user.fullName} assigned as driver'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _assigningId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign driver: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delivery_dining_rounded,
                      color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assign a Driver',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text(
                      'Order ${widget.order.orderNumber}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Select an available driver for this delivery',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const Divider(height: 1),

          // Content
          if (_drivers == null && _error == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Could not load drivers',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _drivers = null;
                        });
                        _loadDrivers();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_drivers!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delivery_dining_outlined,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('No available drivers',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    const Text(
                      'All drivers are currently offline or busy.\nAsk a driver to go online first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _drivers!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final d = _drivers![i];
                  final isAssigning = _assigningId == d.profile.uid;
                  final isDisabled = _assigningId != null && !isAssigning;
                  return _DriverOption(
                    driver: d,
                    isAssigning: isAssigning,
                    isDisabled: isDisabled,
                    onTap: isDisabled ? null : () => _assign(d),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DriverOption extends StatelessWidget {
  final _AvailableDriver driver;
  final bool isAssigning;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _DriverOption({
    required this.driver,
    required this.isAssigning,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAssigning
                  ? AppColors.accent
                  : AppColors.primary.withOpacity(0.15),
              width: isAssigning ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: driver.user.photoUrl != null
                    ? NetworkImage(driver.user.photoUrl!)
                    : null,
                child: driver.user.photoUrl == null
                    ? Text(
                        driver.user.fullName[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler_rounded,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          driver.profile.vehicleType[0].toUpperCase() +
                              driver.profile.vehicleType.substring(1),
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12),
                        ),
                        if (driver.profile.vehiclePlate != null) ...[
                          const Text(' · ',
                              style:
                                  TextStyle(color: AppColors.textHint)),
                          Text(driver.profile.vehiclePlate!,
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 12)),
                        ],
                      ],
                    ),
                    if (driver.user.phone != null)
                      Text(driver.user.phone!,
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              ),
              if (isAssigning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          driver.profile.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '${driver.profile.totalDeliveries} trips',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Online',
                          style: TextStyle(
                              color: AppColors.success,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final String tab;
  const _EmptyOrders({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 72, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('No $tab orders', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Orders will appear here when placed.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
// _DeclineButton: cancels order with seller note, triggers customer notification
// _DriverPickerSheet: fetches available drivers, assigns to order, updates status to assigned
// _DeclineButton: sets OrderStatus.cancelled with note 'Declined by seller'
