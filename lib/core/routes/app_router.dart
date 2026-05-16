import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../routes/route_names.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/products/presentation/pages/product_detail_page.dart';
import '../../features/products/presentation/pages/shop_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/orders/presentation/pages/order_confirmation_page.dart';
import '../../features/tracking/presentation/pages/order_tracking_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/addresses_page.dart';
import '../../features/seller/presentation/pages/seller_register_page.dart';
import '../../features/seller/presentation/pages/seller_dashboard_page.dart';
import '../../features/seller/presentation/pages/seller_products_page.dart';
import '../../features/seller/presentation/pages/seller_add_product_page.dart';
import '../../features/seller/presentation/pages/seller_orders_page.dart';
import '../../features/seller/presentation/pages/seller_analytics_page.dart';
import '../../features/seller/presentation/pages/seller_store_page.dart';
import '../../features/driver/presentation/pages/driver_dashboard_page.dart';
import '../../features/driver/presentation/pages/driver_deliveries_page.dart';
import '../../features/driver/presentation/pages/driver_earnings_page.dart';
import '../../features/driver/presentation/pages/driver_navigation_page.dart';
import '../../features/driver/presentation/pages/driver_profile_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_sellers_page.dart';
import '../../features/admin/presentation/pages/admin_drivers_page.dart';
import '../../features/admin/presentation/pages/admin_create_driver_page.dart';
import '../../features/admin/presentation/pages/admin_settings_page.dart';
import '../../features/admin/presentation/pages/admin_notifications_page.dart';
import '../../features/admin/presentation/pages/admin_audit_logs_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/admin_analytics_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/help_support_page.dart';
import '../../features/settings/presentation/pages/privacy_policy_page.dart';
import '../../features/settings/presentation/pages/terms_of_service_page.dart';
import '../../features/settings/presentation/pages/notification_preferences_page.dart';
import '../../shared/models/product_model.dart';
import '../../shared/widgets/app_shell.dart';

/// Converts a [Stream] into a [ChangeNotifier] so GoRouter can listen to it.
/// GoRouterRefreshStream was removed from go_router in v6+, so we roll our own.
class _StreamChangeNotifier extends ChangeNotifier {
  _StreamChangeNotifier(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Paths that are always accessible without authentication.
const _publicPaths = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.register,
  RouteNames.forgotPassword,
  RouteNames.sellerRegister,
  RouteNames.sellerPendingVerification,
};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: false,
    // Refresh the router whenever Firebase auth state changes.
    // This is the safety net that redirects to login on session expiry.
    refreshListenable: _StreamChangeNotifier(
      fb.FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = fb.FirebaseAuth.instance.currentUser != null;
      final location = state.matchedLocation;
      final isPublic = _publicPaths.contains(location);

      // Not logged in and trying to access a protected route → go to login
      if (!isLoggedIn && !isPublic) {
        return RouteNames.login;
      }

      return null; // no redirect needed
    },
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),

      // Onboarding
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),

      // Auth
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (_, state) => _fade(const LoginPage(), state),
      ),
      GoRoute(
        path: RouteNames.register,
        pageBuilder: (_, state) => _fade(const RegisterPage(), state),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),

      // Seller registration
      GoRoute(
        path: RouteNames.sellerRegister,
        builder: (_, __) => const SellerRegisterPage(),
      ),
      GoRoute(
        path: RouteNames.sellerPendingVerification,
        builder: (_, __) => const _PendingVerificationPage(),
      ),

      // Standalone pages
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailPage(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.checkout,
        builder: (_, __) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/order/confirmation/:id',
        builder: (_, state) => OrderConfirmationPage(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/order/track/:id',
        builder: (_, state) => OrderTrackingPage(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (_, __) => const EditProfilePage(),
      ),
      GoRoute(
        path: RouteNames.addresses,
        builder: (_, __) => const AddressesPage(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.helpSupport,
        builder: (_, __) => const HelpSupportPage(),
      ),
      GoRoute(
        path: RouteNames.privacyPolicy,
        builder: (_, __) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: RouteNames.termsOfService,
        builder: (_, __) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: RouteNames.notificationPreferences,
        builder: (_, __) => const NotificationPreferencesPage(),
      ),

      // Customer Shell
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (_, state) => _noTransition(const HomePage(), state),
          ),
          GoRoute(
            path: RouteNames.shop,
            pageBuilder: (_, state) => _noTransition(const ShopPage(), state),
          ),
          GoRoute(
            path: RouteNames.cart,
            pageBuilder: (_, state) => _noTransition(const CartPage(), state),
          ),
          GoRoute(
            path: RouteNames.orders,
            pageBuilder: (_, state) => _noTransition(const OrdersPage(), state),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (_, state) => _noTransition(const ProfilePage(), state),
          ),
        ],
      ),

      // Seller Shell
      ShellRoute(
        builder: (_, __, child) => SellerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.sellerDashboard,
            pageBuilder: (_, state) =>
                _noTransition(const SellerDashboardPage(), state),
          ),
          GoRoute(
            path: RouteNames.sellerProducts,
            pageBuilder: (_, state) =>
                _noTransition(const SellerProductsPage(), state),
          ),
          GoRoute(
            path: RouteNames.sellerOrders,
            pageBuilder: (_, state) =>
                _noTransition(const SellerOrdersPage(), state),
          ),
          GoRoute(
            path: RouteNames.sellerAnalytics,
            pageBuilder: (_, state) =>
                _noTransition(const SellerAnalyticsPage(), state),
          ),
          GoRoute(
            path: RouteNames.sellerStore,
            pageBuilder: (_, state) =>
                _noTransition(const SellerStorePage(), state),
          ),
        ],
      ),

      // Driver Shell
      ShellRoute(
        builder: (_, __, child) => DriverShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.driverDashboard,
            pageBuilder: (_, state) =>
                _noTransition(const DriverDashboardPage(), state),
          ),
          GoRoute(
            path: RouteNames.driverDeliveries,
            pageBuilder: (_, state) =>
                _noTransition(const DriverDeliveriesPage(), state),
          ),
          GoRoute(
            path: RouteNames.driverEarnings,
            pageBuilder: (_, state) =>
                _noTransition(const DriverEarningsPage(), state),
          ),
          GoRoute(
            path: RouteNames.driverProfile,
            pageBuilder: (_, state) =>
                _noTransition(const DriverProfilePage(), state),
          ),
        ],
      ),

      // Admin Shell
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.adminDashboard,
            pageBuilder: (_, state) =>
                _noTransition(const AdminDashboardPage(), state),
          ),
          GoRoute(
            path: RouteNames.adminUsers,
            pageBuilder: (_, state) =>
                _noTransition(const AdminUsersPage(), state),
          ),
          GoRoute(
            path: RouteNames.adminOrders,
            pageBuilder: (_, state) =>
                _noTransition(const AdminOrdersPage(), state),
          ),
          GoRoute(
            path: RouteNames.adminSettings,
            pageBuilder: (_, state) =>
                _noTransition(const AdminSettingsPage(), state),
          ),
        ],
      ),

      // Seller sub-routes (outside shell)
      GoRoute(
        path: RouteNames.sellerAddProduct,
        builder: (_, __) => const SellerAddProductPage(),
      ),
      GoRoute(
        path: RouteNames.sellerEditProduct,
        builder: (_, state) => SellerAddProductPage(
          productId: state.pathParameters['id'],
        ),
      ),

      // Admin sub-routes (outside shell)
      GoRoute(
        path: RouteNames.adminSellers,
        builder: (_, __) => const AdminSellersPage(),
      ),
      GoRoute(
        path: RouteNames.adminDrivers,
        builder: (_, __) => const AdminDriversPage(),
      ),
      GoRoute(
        path: RouteNames.adminCreateDriver,
        builder: (_, __) => const AdminCreateDriverPage(),
      ),
      GoRoute(
        path: RouteNames.adminNotifications,
        builder: (_, __) => const AdminNotificationsPage(),
      ),
      GoRoute(
        path: RouteNames.adminAuditLogs,
        builder: (_, __) => const AdminAuditLogsPage(),
      ),
      GoRoute(
        path: RouteNames.adminProducts,
        builder: (_, __) => const AdminProductsPage(),
      ),
      GoRoute(
        path: RouteNames.adminAnalytics,
        builder: (_, __) => const AdminAnalyticsPage(),
      ),

      // Driver sub-routes (outside shell)
      GoRoute(
        path: '/driver/deliveries/:id',
        builder: (_, state) => OrderDetailPage(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/driver/navigate/:orderId',
        builder: (_, state) => DriverNavigationPage(
          orderId: state.pathParameters['orderId']!,
        ),
      ),

      // Order detail
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => OrderDetailPage(orderId: state.pathParameters['id']!),
      ),

      // Search / category
      GoRoute(
        path: '/search',
        builder: (_, __) => const ShopPage(),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'];
          final cat = id != null
              ? ProductCategory.values.firstWhere(
                  (c) => c.name == id,
                  orElse: () => ProductCategory.fruits,
                )
              : null;
          return ShopPage(initialCategory: cat);
        },
      ),
    ],
  );
});

CustomTransitionPage<T> _fade<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

NoTransitionPage<T> _noTransition<T>(Widget child, GoRouterState state) {
  return NoTransitionPage<T>(
    key: state.pageKey,
    child: child,
  );
}

class _PendingVerificationPage extends StatelessWidget {
  const _PendingVerificationPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                'Verification Pending',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your seller application is under review. We will notify you by email within 24 hours once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


