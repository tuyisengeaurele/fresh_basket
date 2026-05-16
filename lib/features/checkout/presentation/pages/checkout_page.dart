import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  bool _locationLoading = false;
  String? _selectedSchedule;
  double _lat = 0;
  double _lng = 0;

  final _scheduleOptions = [
    'ASAP (30–60 min)',
    'Today Evening (5–8 PM)',
    'Tomorrow Morning (8–11 AM)',
    'Tomorrow Afternoon (12–4 PM)',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) return;
    if (user.phone != null && user.phone!.isNotEmpty) {
      _phoneCtrl.text = user.phone!;
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services on your device.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied. Enable it in Settings.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Reverse-geocode to human-readable address
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
        _addressCtrl.text = parts.isEmpty ? '${pos.latitude}, ${pos.longitude}' : parts;
      }
    } catch (e) {
      _showSnack('Could not get location: $e');
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = ref.read(authNotifierProvider).value;
    final cart = ref.read(cartProvider);
    if (user == null || cart.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final address = DeliveryAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: 'Delivery Address',
      fullAddress: _addressCtrl.text.trim(),
      latitude: _lat,
      longitude: _lng,
      instructions: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    try {
      final orderId = await ref.read(placeOrderProvider.notifier).placeOrder(
            customer: user,
            cart: cart,
            address: address,
            scheduledTime: _selectedSchedule,
          );

      if (!mounted) return;

      ref.read(cartProvider.notifier).clear();
      context.go(
        RouteNames.orderConfirmation.replaceFirst(':id', orderId ?? ''),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.checkout),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Items Summary
              _SectionTitle(title: 'Order Items (${cart.totalItems})'),
              const SizedBox(height: 12),
              ...cart.items.map((item) => _OrderItemRow(item: item)),
              const SizedBox(height: 24),

              // Delivery Address
              _SectionTitle(title: AppStrings.deliveryAddress),
              const SizedBox(height: 12),
              // Location buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locationLoading ? null : _useCurrentLocation,
                      icon: _locationLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 16),
                      label: const Text('Use My Location',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _addressCtrl.clear();
                        _lat = 0;
                        _lng = 0;
                        FocusScope.of(context).requestFocus(FocusNode());
                        Future.delayed(const Duration(milliseconds: 50), () {
                          FocusScope.of(context).unfocus();
                        });
                      },
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                      label: const Text('Type Address',
                          style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Full Address',
                  hintText: 'Enter your full delivery address',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: _lat != 0
                      ? Tooltip(
                          message: 'GPS location captured',
                          child: const Icon(Icons.gps_fixed_rounded,
                              color: AppColors.primary, size: 18),
                        )
                      : null,
                ),
                validator: (v) => Validators.required(v, 'Address'),
              ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+250 7XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: Validators.phone,
              ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Delivery Notes (Optional)',
                  hintText: 'e.g. Gate code, landmark...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 24),

              // Delivery Schedule
              _SectionTitle(title: AppStrings.deliveryTime),
              const SizedBox(height: 12),
              ..._scheduleOptions.map(
                (s) => RadioListTile<String>(
                  value: s,
                  groupValue: _selectedSchedule ?? _scheduleOptions.first,
                  onChanged: (v) => setState(() => _selectedSchedule = v),
                  title: Text(s, style: const TextStyle(fontSize: 14)),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method
              _SectionTitle(title: AppStrings.paymentMethod),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.cashOnDelivery,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Pay when your order arrives',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.dividerLight),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mobile Money (MTN/Airtel)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Coming Soon',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
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
              ),
              const SizedBox(height: 24),

              // Order Summary
              _OrderSummaryCard(cart: cart),
              const SizedBox(height: 32),

              // Place Order button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${AppStrings.placeOrder} — ${Formatters.currency(cart.total)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${item.product.name} x${item.quantity}',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            Formatters.currency(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final cart;

  const _OrderSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        children: [
          _Row(
            label: AppStrings.subtotal,
            value: Formatters.currency(cart.subtotal),
          ),
          const SizedBox(height: 6),
          _Row(
            label: AppStrings.deliveryFee,
            value: cart.deliveryFee == 0
                ? 'FREE'
                : Formatters.currency(cart.deliveryFee),
            valueColor:
                cart.deliveryFee == 0 ? AppColors.success : null,
          ),
          if (cart.discount > 0) ...[
            const SizedBox(height: 6),
            _Row(
              label: 'Discount',
              value: '- ${Formatters.currency(cart.discount)}',
              valueColor: AppColors.success,
            ),
          ],
          const Divider(height: 20),
          _Row(
            label: 'Total to Pay',
            value: Formatters.currency(cart.total),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: bold ? 15 : 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? (bold ? AppColors.primary : AppColors.textPrimary),
            fontSize: bold ? 17 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
// _useCurrentLocation: geolocator + placemarkFromCoordinates for address autofill
