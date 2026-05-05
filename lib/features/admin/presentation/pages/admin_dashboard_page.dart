import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/status_chip.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Platform Overview',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(RouteNames.adminNotifications),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(RouteNames.adminSettings),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform stats
                  ordersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => _PlatformStats(orders: orders),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Quick Actions Grid
                  _AdminQuickActions(),
                  const SizedBox(height: AppDimensions.lg),

                  // Order status breakdown
                  ordersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => _OrderStatusChart(orders: orders),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Recent orders
                  const Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ordersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => Column(
                      children: orders
                          .take(10)
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (e) => _AdminOrderRow(
                              order: e.value,
                              index: e.key,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformStats extends StatelessWidget {
  final List<OrderModel> orders;

  const _PlatformStats({required this.orders});

  @override
  Widget build(BuildContext context) {
    final total = orders.length;
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).length;
    final revenue = orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.total);
    final active = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _BigStatCard(
          label: 'Total Orders',
          value: '$total',
          icon: Icons.receipt_long_rounded,
          color: AppColors.info,
          index: 0,
        ),
        _BigStatCard(
          label: 'Delivered',
          value: '$delivered',
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
          index: 1,
        ),
        _BigStatCard(
          label: 'Platform Revenue',
          value: 'RWF ${Formatters.compact(revenue)}',
          icon: Icons.payments_rounded,
          color: AppColors.accent,
          index: 2,
        ),
        _BigStatCard(
          label: 'Active Orders',
          value: '$active',
          icon: Icons.pending_actions_rounded,
          color: AppColors.statusPending,
          index: 3,
        ),
      ],
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _BigStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.15);
  }
}

class _AdminQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Users', Icons.people_outline_rounded, RouteNames.adminUsers, AppColors.info),
      ('Sellers', Icons.storefront_outlined, RouteNames.adminSellers, AppColors.roleSeller),
      ('Drivers', Icons.directions_bike_rounded, RouteNames.adminDrivers, AppColors.roleDriver),
      ('Products', Icons.inventory_2_outlined, RouteNames.adminProducts, AppColors.primary),
      ('Orders', Icons.receipt_outlined, RouteNames.adminOrders, AppColors.accent),
      ('Analytics', Icons.bar_chart_rounded, RouteNames.adminAnalytics, AppColors.info),
      ('Notifications', Icons.notifications_outlined, RouteNames.adminNotifications, AppColors.statusPending),
      ('Audit Logs', Icons.history_rounded, RouteNames.adminAuditLogs, AppColors.textSecondary),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.8,
      children: actions
          .asMap()
          .entries
          .map(
            (e) => GestureDetector(
              onTap: () => context.push(e.value.$3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: e.value.$4.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: Icon(e.value.$2, color: e.value.$4, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.value.$1,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
                  .animate(delay: Duration(milliseconds: e.key * 50))
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ),
          )
          .toList(),
    );
  }
}

class _OrderStatusChart extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrderStatusChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    final statusCounts = <OrderStatus, int>{};
    for (final o in orders) {
      statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
    }

    if (statusCounts.isEmpty) return const SizedBox.shrink();

    final colors = {
      OrderStatus.pending: AppColors.statusPending,
      OrderStatus.confirmed: AppColors.statusConfirmed,
      OrderStatus.onTheWay: AppColors.statusInTransit,
      OrderStatus.delivered: AppColors.statusDelivered,
      OrderStatus.cancelled: AppColors.statusCancelled,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status Breakdown',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: statusCounts.entries.map((e) {
                        final color = colors[e.key] ?? AppColors.primary;
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: color,
                          title: '${e.value}',
                          radius: 60,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: statusCounts.entries.map((e) {
                    final color = colors[e.key] ?? AppColors.primary;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.key.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms);
  }
}

class _AdminOrderRow extends StatelessWidget {
  final OrderModel order;
  final int index;

  const _AdminOrderRow({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        RouteNames.adminOrders,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(status: order.status, small: true),
            const SizedBox(width: 8),
            Text(
              Formatters.currency(order.total),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 40))
          .fadeIn(duration: 300.ms),
    );
  }
}
