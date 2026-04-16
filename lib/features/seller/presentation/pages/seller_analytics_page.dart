import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';

class SellerAnalyticsPage extends ConsumerWidget {
  const SellerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final ordersAsync = ref.watch(sellerOrdersProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('Analytics')),
          body: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => QueryErrorView(error: e),
            data: (orders) {
              final delivered = orders.where((o) => o.status == OrderStatus.delivered).toList();
              final revenue = delivered.fold<double>(0, (sum, o) => sum + o.total);
              final avgOrder = delivered.isEmpty ? 0.0 : revenue / delivered.length;

              final weeklyData = _buildWeeklyData(orders);
              final productSales = _buildProductSales(orders);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsRow(
                    stats: [
                      _StatItem(label: 'Total Orders', value: '${orders.length}', icon: Icons.receipt_outlined, color: AppColors.primary),
                      _StatItem(label: 'Revenue', value: Formatters.currency(revenue), icon: Icons.payments_outlined, color: AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StatsRow(
                    stats: [
                      _StatItem(label: 'Delivered', value: '${delivered.length}', icon: Icons.check_circle_outline, color: AppColors.success),
                      _StatItem(label: 'Avg Order', value: Formatters.currency(avgOrder), icon: Icons.trending_up_rounded, color: AppColors.info),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: '7-Day Revenue'),
                  const SizedBox(height: 12),
                  _RevenueChart(weeklyData: weeklyData),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Order Status Breakdown'),
                  const SizedBox(height: 12),
                  _StatusBreakdown(orders: orders),
                  if (productSales.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'Top Products by Revenue'),
                    const SizedBox(height: 12),
                    _TopProducts(products: productSales),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<({String day, double revenue})> _buildWeeklyData(List<OrderModel> orders) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayRevenue = orders
          .where((o) =>
              o.status == OrderStatus.delivered &&
              o.createdAt.year == day.year &&
              o.createdAt.month == day.month &&
              o.createdAt.day == day.day)
          .fold<double>(0, (sum, o) => sum + o.total);
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
      return (day: dayName, revenue: dayRevenue);
    });
  }

  Map<String, double> _buildProductSales(List<OrderModel> orders) {
    final map = <String, double>{};
    for (final order in orders.where((o) => o.status == OrderStatus.delivered)) {
      for (final item in order.items) {
        map[item.productName] = (map[item.productName] ?? 0) + item.subtotal;
      }
    }
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }
}

class _StatsRow extends StatelessWidget {
  final List<_StatItem> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: stats.last == s ? 0 : 8),
                  child: _StatCard(item: s),
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(height: 8),
          Text(item.value,
              style: TextStyle(
                  color: item.color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(item.label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary));
  }
}

class _RevenueChart extends StatelessWidget {
  final List<({String day, double revenue})> weeklyData;
  const _RevenueChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final maxRevenue = weeklyData.fold<double>(0, (m, d) => d.revenue > m ? d.revenue : m);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxRevenue == 0 ? 10 : maxRevenue * 1.2,
          barGroups: weeklyData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.revenue,
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) => Text(
                  weeklyData[value.toInt()].day,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
                reservedSize: 24,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final List<OrderModel> orders;
  const _StatusBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final counts = <OrderStatus, int>{};
    for (final o in orders) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }

    final colors = {
      OrderStatus.pending: AppColors.warning,
      OrderStatus.confirmed: AppColors.info,
      OrderStatus.preparing: AppColors.accent,
      OrderStatus.assigned: Colors.purple,
      OrderStatus.pickedUp: Colors.teal,
      OrderStatus.onTheWay: Colors.indigo,
      OrderStatus.delivered: AppColors.success,
      OrderStatus.cancelled: AppColors.error,
      OrderStatus.failed: AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: counts.entries.map((e) {
          final pct = orders.isEmpty ? 0.0 : e.value / orders.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    e.key.name[0].toUpperCase() + e.key.name.substring(1),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(colors[e.key] ?? AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${e.value}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors[e.key],
                        fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  final Map<String, double> products;
  const _TopProducts({required this.products});

  @override
  Widget build(BuildContext context) {
    final entries = products.entries.toList();
    final maxVal = entries.isEmpty ? 1.0 : entries.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: entries.map((e) {
          final pct = maxVal == 0 ? 0.0 : e.value / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Text(Formatters.currency(e.value),
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.green50,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
