import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/query_error_view.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';

final _driverProfileProvider = StreamProvider.family<DriverProfile?, String>((ref, uid) {
  return FirebaseService.driverProfiles
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? DriverProfile.fromFirestore(s) : null);
});

class DriverEarningsPage extends ConsumerWidget {
  const DriverEarningsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final ordersAsync = ref.watch(driverOrdersProvider(user.uid));
        final profileAsync = ref.watch(_driverProfileProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('Earnings')),
          body: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => QueryErrorView(error: e),
            data: (orders) {
              final delivered =
                  orders.where((o) => o.status == OrderStatus.delivered).toList();
              final totalEarnings = profileAsync.value?.totalEarnings ??
                  delivered.length * 500.0;
              final weeklyData = _buildWeeklyData(delivered);
              final thisWeek =
                  weeklyData.fold<double>(0, (sum, d) => sum + d.earnings);
              final thisMonth = _thisMonthEarnings(delivered);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _EarningsBanner(
                    totalEarnings: totalEarnings,
                    thisWeek: thisWeek,
                    thisMonth: thisMonth,
                    deliveries: delivered.length,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: '7-Day Earnings'),
                  const SizedBox(height: 12),
                  _WeeklyChart(weeklyData: weeklyData),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Recent Deliveries'),
                  const SizedBox(height: 12),
                  ...delivered.take(20).map((o) => _DeliveryEarningRow(order: o)),
                  if (delivered.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No completed deliveries yet.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<({String day, double earnings})> _buildWeeklyData(List<OrderModel> orders) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dayCount = orders
          .where((o) =>
              o.createdAt.year == day.year &&
              o.createdAt.month == day.month &&
              o.createdAt.day == day.day)
          .length;
      final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
      return (day: dayName, earnings: dayCount * 500.0);
    });
  }

  double _thisMonthEarnings(List<OrderModel> orders) {
    final now = DateTime.now();
    return orders
            .where((o) => o.createdAt.month == now.month && o.createdAt.year == now.year)
            .length *
        500.0;
  }
}

class _EarningsBanner extends StatelessWidget {
  final double totalEarnings;
  final double thisWeek;
  final double thisMonth;
  final int deliveries;

  const _EarningsBanner({
    required this.totalEarnings,
    required this.thisWeek,
    required this.thisMonth,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earnings',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            Formatters.currency(totalEarnings),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BannerStat(label: 'This Week', value: Formatters.currency(thisWeek)),
              const SizedBox(width: 20),
              _BannerStat(label: 'This Month', value: Formatters.currency(thisMonth)),
              const SizedBox(width: 20),
              _BannerStat(label: 'Deliveries', value: '$deliveries'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  const _BannerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
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

class _WeeklyChart extends StatelessWidget {
  final List<({String day, double earnings})> weeklyData;
  const _WeeklyChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final maxY = weeklyData.fold<double>(0, (m, d) => d.earnings > m ? d.earnings : m);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1000 : maxY * 1.2,
          barGroups: weeklyData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.earnings,
                  color: AppColors.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
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

class _DeliveryEarningRow extends StatelessWidget {
  final OrderModel order;
  const _DeliveryEarningRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(Formatters.dateTime(order.createdAt),
                    style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Text(
            Formatters.currency(500),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
