import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/status_chip.dart';

class SellerDashboardPage extends ConsumerWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    if (user == null) return const SizedBox.shrink();

    final ordersAsync = ref.watch(sellerOrdersProvider(user.uid));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seller Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(RouteNames.notifications),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push(RouteNames.settings),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  ordersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => _StatsRow(orders: orders),
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Quick actions
                  _QuickActions(),
                  const SizedBox(height: AppDimensions.lg),

                  // Revenue chart
                  ordersAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => _RevenueChart(orders: orders),
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
                    data: (orders) {
                      final recent = orders.take(5).toList();
                      return Column(
                        children: recent
                            .asMap()
                            .entries
                            .map(
                              (e) => _OrderCard(
                                order: e.value,
                                index: e.key,
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.sellerAddProduct),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add Product',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<OrderModel> orders;

  const _StatsRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final totalOrders = orders.length;
    final pendingOrders = orders
        .where((o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.confirmed)
        .length;
    final revenue = orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (sum, o) => sum + o.total);

    return Row(
      children: [
        _StatCard(
          label: 'Total Orders',
          value: '$totalOrders',
          icon: Icons.receipt_long_rounded,
          color: AppColors.info,
          index: 0,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Pending',
          value: '$pendingOrders',
          icon: Icons.pending_actions_rounded,
          color: AppColors.statusPending,
          index: 1,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Revenue',
          value: Formatters.compact(revenue),
          icon: Icons.payments_rounded,
          color: AppColors.primary,
          index: 2,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        'Products',
        Icons.inventory_2_outlined,
        RouteNames.sellerProducts,
        AppColors.primary,
      ),
      (
        'Orders',
        Icons.receipt_outlined,
        RouteNames.sellerOrders,
        AppColors.info,
      ),
      (
        'Analytics',
        Icons.bar_chart_rounded,
        RouteNames.sellerAnalytics,
        AppColors.accent,
      ),
      (
        'Store',
        Icons.storefront_outlined,
        RouteNames.sellerStore,
        AppColors.roleSeller,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
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
                    child: Icon(
                      e.value.$2,
                      color: e.value.$4,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e.value.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
                  .animate(delay: Duration(milliseconds: e.key * 60))
                  .fadeIn(duration: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ),
          )
          .toList(),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<OrderModel> orders;

  const _RevenueChart({required this.orders});

  @override
  Widget build(BuildContext context) {
    // Group delivered orders by day (last 7 days)
    final now = DateTime.now();
    final dailyRevenue = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayOrders = orders.where(
        (o) =>
            o.status == OrderStatus.delivered &&
            o.deliveredAt != null &&
            o.deliveredAt!.day == day.day &&
            o.deliveredAt!.month == day.month,
      );
      return dayOrders.fold<double>(0, (sum, o) => sum + o.total);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue (Last 7 Days)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: dailyRevenue.isEmpty
                    ? 100
                    : dailyRevenue.reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final day = now.subtract(
                            Duration(days: 6 - val.toInt()));
                        const days = [
                          'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'
                        ];
                        return Text(
                          days[day.weekday - 1],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyRevenue
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: AppColors.primary,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.dividerLight,
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms);
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final int index;

  const _OrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        RouteNames.sellerOrderDetail.replaceFirst(':id', order.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.customerName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.relativeTime(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusChip(status: order.status, small: true),
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 60))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.1),
    );
  }
}
