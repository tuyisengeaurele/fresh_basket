import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/widgets/status_chip.dart';

class OrderTrackingPage extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.orders),
        ),
      ),
      body: orderAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _TrackingContent(
            order: order,
            onMapCreated: (c) => _mapController = c,
          );
        },
      ),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  final OrderModel order;
  final void Function(GoogleMapController) onMapCreated;

  const _TrackingContent({
    required this.order,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final hasDriver = order.driverId != null;
    final driverPos = hasDriver &&
            order.driverLat != null &&
            order.driverLng != null
        ? LatLng(order.driverLat!, order.driverLng!)
        : null;

    final deliveryPos = LatLng(
      order.deliveryAddress.latitude == 0
          ? -1.9578
          : order.deliveryAddress.latitude,
      order.deliveryAddress.longitude == 0
          ? 30.1127
          : order.deliveryAddress.longitude,
    );

    return Column(
      children: [
        // Map
        Expanded(
          flex: 5,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: driverPos ?? deliveryPos,
              zoom: 14,
            ),
            onMapCreated: onMapCreated,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('delivery'),
                position: deliveryPos,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Delivery Location'),
              ),
              if (driverPos != null)
                Marker(
                  markerId: const MarkerId('driver'),
                  position: driverPos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange),
                  infoWindow: InfoWindow(
                    title: 'Driver: ${order.driverName ?? ""}',
                  ),
                ),
            },
          ),
        ),

        // Status Panel
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.pagePadding),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXxl),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                if (hasDriver) ...[
                  _DriverCard(order: order),
                  const SizedBox(height: 16),
                ],
                // Timeline
                Expanded(
                  child: ListView(
                    children: _buildTimeline(order, context),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),
        ),
      ],
    );
  }

  List<Widget> _buildTimeline(OrderModel order, BuildContext context) {
    final milestones = [
      (OrderStatus.pending, 'Order Placed', Icons.receipt_long_rounded),
      (OrderStatus.confirmed, 'Confirmed', Icons.check_circle_outline),
      (OrderStatus.preparing, 'Preparing', Icons.kitchen_rounded),
      (OrderStatus.assigned, 'Driver Assigned', Icons.person_pin_circle_outlined),
      (OrderStatus.pickedUp, 'Picked Up', Icons.directions_bike_rounded),
      (OrderStatus.onTheWay, 'On The Way', Icons.local_shipping_outlined),
      (OrderStatus.delivered, 'Delivered', Icons.home_rounded),
    ];

    final completedStatuses = order.timeline.map((t) => t.status).toSet();
    final currentIdx =
        milestones.indexWhere((m) => m.$1 == order.status);

    return milestones.asMap().entries.map((entry) {
      final mIdx = entry.key;
      final m = entry.value;
      // Mark completed if the order has progressed past this step (index-based),
      // or if it was explicitly recorded in the timeline.
      final isCompleted = (currentIdx >= 0 && mIdx < currentIdx) ||
          completedStatuses.contains(m.$1);
      final isCurrent = m.$1 == order.status;
      final isUpcoming = !isCompleted && !isCurrent;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : isCurrent
                            ? AppColors.accent
                            : AppColors.dividerLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    m.$3,
                    size: 16,
                    color: isUpcoming ? AppColors.textHint : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                m.$2,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isUpcoming
                      ? AppColors.textHint
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isCompleted)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      );
    }).toList();
  }
}

class _DriverCard extends StatelessWidget {
  final OrderModel order;

  const _DriverCard({required this.order});

  Future<void> _callDriver(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use card color so text is always legible in both light and dark mode.
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.green50;
    final nameColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bike_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName ?? 'Your Driver',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: nameColor,
                  ),
                ),
                if (order.driverPhone != null)
                  Text(
                    order.driverPhone!,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 12,
                    ),
                  )
                else if (order.estimatedDeliveryTime != null)
                  Text(
                    'ETA: ${order.estimatedDeliveryTime}',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          if (order.driverPhone != null)
            GestureDetector(
              onTap: () => _callDriver(order.driverPhone!),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
