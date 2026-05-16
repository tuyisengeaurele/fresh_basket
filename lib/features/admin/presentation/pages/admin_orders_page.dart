import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../orders/presentation/providers/order_provider.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _search = '';

  static const _tabs = ['All', 'Active', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by order # or customer...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          itemBuilder: (_, __) => const ListItemSkeleton(),
        ),
        error: (e, _) => QueryErrorView(error: e),
        data: (orders) {
          final searched = _search.isEmpty
              ? orders
              : orders
                  .where((o) =>
                      o.orderNumber.toLowerCase().contains(_search.toLowerCase()) ||
                      o.customerName.toLowerCase().contains(_search.toLowerCase()))
                  .toList();

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final filtered = _filter(searched, tab);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No $tab orders',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _AdminOrderTile(
                  order: filtered[i],
                  onDelete: () => _confirmDelete(context, filtered[i]),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete order ${order.orderNumber}?'),
            const SizedBox(height: 8),
            const Text(
              'This permanently removes the order from the database. '
              'This action cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await FirebaseService.orders.doc(order.id).delete();
                await FirebaseService.logAudit(
                  action: 'order_deleted',
                  actorId: FirebaseService.currentUid ?? '',
                  targetId: order.id,
                  targetType: 'order',
                  details: {
                    'orderNumber': order.orderNumber,
                    'customerName': order.customerName,
                    'status': order.status.name,
                  },
                );
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.orderNumber} deleted'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error deleting order: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<OrderModel> _filter(List<OrderModel> orders, String tab) {
    switch (tab) {
      case 'Active':
        return orders.where((o) => o.isActive).toList();
      case 'Delivered':
        return orders.where((o) => o.status == OrderStatus.delivered).toList();
      case 'Cancelled':
        return orders
            .where((o) =>
                o.status == OrderStatus.cancelled || o.status == OrderStatus.failed)
            .toList();
      default:
        return orders;
    }
  }
}

class _AdminOrderTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDelete;

  const _AdminOrderTile({required this.order, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.fromLTRB(14, 8, 8, 4),
            onTap: () => context.push('/order/${order.id}'),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_outlined,
                  color: AppColors.primary, size: 22),
            ),
            title: Row(
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                StatusChip(status: order.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(order.customerName,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(Formatters.currency(order.total),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const Spacer(),
                    Text(Formatters.dateTime(order.createdAt),
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
          // Admin action bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.green50.withOpacity(0.4),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // View detail
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => context.push('/order/${order.id}'),
                    icon: const Icon(Icons.visibility_outlined, size: 15),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.dividerLight),
                // Delete
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 15),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
