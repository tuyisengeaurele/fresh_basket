import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';

class DriverNavigationPage extends ConsumerStatefulWidget {
  final String orderId;
  const DriverNavigationPage({super.key, required this.orderId});

  @override
  ConsumerState<DriverNavigationPage> createState() =>
      _DriverNavigationPageState();
}

class _DriverNavigationPageState extends ConsumerState<DriverNavigationPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  OrderModel? _order;
  bool _orderLoading = true;

  LatLng? _driverPos;
  LatLng? _destPos;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final doc = await FirebaseService.orders.doc(widget.orderId).get();
      if (!doc.exists || !mounted) return;
      final order = OrderModel.fromFirestore(doc);
      setState(() {
        _order = order;
        _orderLoading = false;
        if (order.deliveryAddress.latitude != 0 ||
            order.deliveryAddress.longitude != 0) {
          _destPos = LatLng(
            order.deliveryAddress.latitude,
            order.deliveryAddress.longitude,
          );
        }
        _updateMarkers();
      });
    } catch (e) {
      if (mounted) setState(() => _orderLoading = false);
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10m moved
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _driverPos = LatLng(pos.latitude, pos.longitude);
        _updateMarkers();
      });

      // Animate camera to keep driver centred
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_driverPos!),
      );
    });
  }

  void _updateMarkers() {
    _markers.clear();

    if (_driverPos != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    }

    if (_destPos != null) {
      _markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Delivery Address',
          snippet: _order?.deliveryAddress.fullAddress,
        ),
      ));
    }
  }

  Future<void> _openGoogleMapsNav() async {
    if (_destPos == null && _order == null) return;

    String url;
    if (_destPos != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=${_destPos!.latitude},${_destPos!.longitude}&travelmode=driving';
    } else {
      final addr = Uri.encodeComponent(_order!.deliveryAddress.fullAddress);
      url =
          'https://www.google.com/maps/dir/?api=1&destination=$addr&travelmode=driving';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Future<void> _markOnTheWay() async {
    if (_order == null) return;
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: _order!.id,
            newStatus: OrderStatus.onTheWay,
            actorId: FirebaseService.currentUid ?? '',
            note: 'Driver is on the way',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated: On the way'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  LatLng get _initialCamera {
    if (_driverPos != null) return _driverPos!;
    if (_destPos != null) return _destPos!;
    // Default: Kigali, Rwanda
    return const LatLng(-1.9441, 30.0619);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Navigate to Customer', style: TextStyle(fontSize: 16)),
            if (_order != null)
              Text(
                _order!.orderNumber,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          if (_order?.status == OrderStatus.pickedUp)
            TextButton(
              onPressed: _markOnTheWay,
              child: const Text('On the Way',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
            ),
        ],
      ),
      body: _orderLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialCamera,
                      zoom: 14,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (ctrl) {
                      _mapController = ctrl;
                      // Fit both markers if possible
                      if (_driverPos != null && _destPos != null) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngBounds(
                              LatLngBounds(
                                southwest: LatLng(
                                  _driverPos!.latitude < _destPos!.latitude
                                      ? _driverPos!.latitude
                                      : _destPos!.latitude,
                                  _driverPos!.longitude < _destPos!.longitude
                                      ? _driverPos!.longitude
                                      : _destPos!.longitude,
                                ),
                                northeast: LatLng(
                                  _driverPos!.latitude > _destPos!.latitude
                                      ? _driverPos!.latitude
                                      : _destPos!.latitude,
                                  _driverPos!.longitude > _destPos!.longitude
                                      ? _driverPos!.longitude
                                      : _destPos!.longitude,
                                ),
                              ),
                              80,
                            ),
                          );
                        });
                      }
                    },
                  ),
                ),

                // Bottom panel
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 16, 16, MediaQuery.paddingOf(context).bottom + 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delivery address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: AppColors.error, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Delivery Address',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  _order?.deliveryAddress.fullAddress ??
                                      'Loading...',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                if (_order != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_order!.customerName}  •  ${_order!.customerPhone}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_order?.deliveryAddress.instructions != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.warning.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _order!.deliveryAddress.instructions!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Amount reminder + navigate button
                      Row(
                        children: [
                          if (_order != null)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Collect',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                    Text(
                                      Formatters.currency(_order!.total),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _openGoogleMapsNav,
                              icon: const Icon(Icons.navigation_rounded),
                              label: const Text('Navigate',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                backgroundColor: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
// _startLocationTracking: Geolocator.getPositionStream with distanceFilter: 10
// _openGoogleMapsNav: launches Maps with lat/lng or address as destination
