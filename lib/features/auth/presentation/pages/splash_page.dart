import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    try {
      final user = await ref.read(authNotifierProvider.future);
      if (!mounted) return;

      if (user == null) {
        context.go(RouteNames.onboarding);
        return;
      }

      _routeByRole(user.role);
    } catch (_) {
      if (mounted) context.go(RouteNames.login);
    }
  }

  void _routeByRole(UserRole role) {
    switch (role) {
      case UserRole.seller:
        context.go(RouteNames.sellerDashboard);
      case UserRole.driver:
        context.go(RouteNames.driverDashboard);
      case UserRole.admin:
        context.go(RouteNames.adminDashboard);
      case UserRole.customer:
        context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo — Twitter/X-style zoom from nothing
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/fresh_basket_logo.png',
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.05, 0.05),
                      end: const Offset(1.0, 1.0),
                      duration: 750.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'FreshBasket',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    fontFamily: 'Poppins',
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Freshness Delivered.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.5,
                    fontFamily: 'Poppins',
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// easeOutBack curve gives the spring-past-then-settle feel identical to Twitter/X
