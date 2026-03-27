import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/route_names.dart';

class OrderConfirmationPage extends StatelessWidget {
  final String orderId;

  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation / icon
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: AppColors.green50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),
              const SizedBox(height: 32),
              Text(
                AppStrings.orderPlaced,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              const Text(
                AppStrings.orderPlacedDesc,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.green50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Order #${orderId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ).animate(delay: 650.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(
                    RouteNames.orderTracking.replaceFirst(':id', orderId),
                  ),
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text(
                    AppStrings.trackOrder,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate(delay: 750.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(RouteNames.home),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
