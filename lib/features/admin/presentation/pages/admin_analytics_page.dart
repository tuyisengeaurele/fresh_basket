import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';

class AdminAnalyticsPage extends ConsumerWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Analytics')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => QueryErrorView(error: e),
        data: (orders) => _AnalyticsBody(orders: orders),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final List<OrderModel> orders;

  const _AnalyticsBody({required this.orders});

  @override
  Widget build(BuildContext context) {
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).toList();
    final totalRevenue =
        delivered.fold<double>(0, (s, o) => s + o.total);
    final active = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled &&
            o.status != OrderStatus.failed)
        .length;
    final cancelled = orders
        .where((o) =>
            o.status == OrderStatus.cancelled ||
            o.status == OrderStatus.failed)
        .length;
    final avgOrderValue =
        delivered.isEmpty ? 0.0 : totalRevenue / delivered.length;

    // Group delivered orders by day (last 7 days)
    final now = DateTime.now();
    final dailyRevenue = <int, double>{};
    for (var i = 6; i >= 0; i--) {
      dailyRevenue[i] = 0;
    }
    for (final o in delivered) {
      final diff = now.difference(o.createdAt).inDays;
      if (diff <= 6) {
        dailyRevenue[diff] = (dailyRevenue[diff] ?? 0) + o.total;
      }
    }

    // Top 5 products by revenue
    final productRevenue = <String, double>{};
    for (final o in delivered) {
      for (final item in o.items) {
        productRevenue[item.productName] =
            (productRevenue[item.productName] ?? 0) + item.subtotal;
      }
    }
    final topProducts = productRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topProducts.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary row ──────────────────────────────────────────
        _SummaryGrid(
          totalRevenue: totalRevenue,
          totalOrders: orders.length,
          delivered: delivered.length,
          active: active,
          cancelled: cancelled,
          avgOrder: avgOrderValue,
        ),
        const SizedBox(height: 20),

        // ── Revenue last 7 days ──────────────────────────────────
        _SectionTitle(title: 'Revenue — Last 7 Days'),
        const SizedBox(height: 12),
        _RevenueBarChart(dailyRevenue: dailyRevenue, now: now),
        const SizedBox(height: 20),

        // ── Order status breakdown ───────────────────────────────
        _SectionTitle(title: 'Order Status Breakdown'),
        const SizedBox(height: 12),
        _StatusBreakdown(orders: orders),
        const SizedBox(height: 20),

        // ── Top products ─────────────────────────────────────────
        if (top5.isNotEmpty) ...[
          _SectionTitle(title: 'Top Products by Revenue'),
          const SizedBox(height: 12),
          _TopProductsList(topProducts: top5),
        ],

        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
  }
}

class _SummaryGrid extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final int delivered;
  final int active;
  final int cancelled;
  final double avgOrder;

  const _SummaryGrid({
    required this.totalRevenue,
    required this.totalOrders,
    required this.delivered,
    required this.active,
    required this.cancelled,
    required this.avgOrder,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Total Revenue', Formatters.currency(totalRevenue), AppColors.primary, Icons.payments_rounded),
      _StatItem('Total Orders', '$totalOrders', AppColors.info, Icons.receipt_long_rounded),
      _StatItem('Delivered', '$delivered', AppColors.success, Icons.check_circle_outline),
      _StatItem('Active', '$active', AppColors.statusPending, Icons.pending_actions_rounded),
      _StatItem('Cancelled', '$cancelled', AppColors.error, Icons.cancel_outlined),
      _StatItem('Avg. Order', Formatters.currency(avgOrder), AppColors.accent, Icons.bar_chart_rounded),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items
          .asMap()
          .entries
          .map((e) => _StatCard(item: e.value, index: e.key))
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatItem(this.label, this.value, this.color, this.icon);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  final int index;
  const _StatCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            item.color.withOpacity(0.14),
            item.color.withOpacity(0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(item.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: item.color,
                )),
          ),
          Text(item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15);
  }
}

class _RevenueBarChart extends StatelessWidget {
  final Map<int, double> dailyRevenue; // key = days ago (0 = today)
  final DateTime now;

  const _RevenueBarChart({required this.dailyRevenue, required this.now});

  @override
  Widget build(BuildContext context) {
    final maxVal =
        dailyRevenue.values.isEmpty ? 1.0 : dailyRevenue.values.reduce((a, b) => a > b ? a : b);
    final yMax = maxVal <= 0 ? 1000.0 : (maxVal * 1.25).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            horizontalInterval: yMax / 4,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.dividerLight,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  Formatters.compact(v),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final daysAgo = 6 - v.toInt();
                  final date =
                      now.subtract(Duration(days: daysAgo));
                  const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
                  return Text(
                    days[date.weekday - 1],
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(7, (i) {
            final daysAgo = 6 - i;
            final revenue = dailyRevenue[daysAgo] ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: revenue,
                  color: revenue > 0
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.15),
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _StatusBreakdown extends StatelessWidget {
  final List<OrderModel> orders;
  const _StatusBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    final statusCounts = <OrderStatus, int>{};
    for (final o in orders) {
      statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
    }
    if (statusCounts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No orders yet',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final colorMap = {
      OrderStatus.pending: AppColors.statusPending,
      OrderStatus.confirmed: AppColors.statusConfirmed,
      OrderStatus.preparing: AppColors.info,
      OrderStatus.assigned: AppColors.info,
      OrderStatus.pickedUp: AppColors.statusInTransit,
      OrderStatus.onTheWay: AppColors.statusInTransit,
      OrderStatus.delivered: AppColors.statusDelivered,
      OrderStatus.cancelled: AppColors.statusCancelled,
      OrderStatus.failed: AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: statusCounts.entries.map((e) {
          final color = colorMap[e.key] ?? AppColors.primary;
          final pct = orders.isEmpty ? 0.0 : e.value / orders.length;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    e.key.name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.value}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

class _TopProductsList extends StatelessWidget {
  final List<MapEntry<String, double>> topProducts;
  const _TopProductsList({required this.topProducts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: topProducts.asMap().entries.map((e) {
          final rank = e.key + 1;
          final name = e.value.key;
          final revenue = e.value.value;
          final maxRevenue = topProducts.first.value;
          final pct = maxRevenue <= 0 ? 0.0 : revenue / maxRevenue;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                '$rank',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            title: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),
            trailing: Text(
              Formatters.currency(revenue),
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          );
        }).toList(),
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms);
  }
}
