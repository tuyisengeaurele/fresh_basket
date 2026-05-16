class RouteNames {
  RouteNames._();

  // Splash & Onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String roleSelection = '/role-selection';

  // Customer Shell
  static const String customerShell = '/customer';
  static const String home = '/customer/home';
  static const String shop = '/customer/shop';
  static const String cart = '/customer/cart';
  static const String orders = '/customer/orders';
  static const String profile = '/customer/profile';

  // Products
  static const String productDetail = '/product/:id';
  static const String search = '/search';
  static const String category = '/category/:id';

  // Checkout & Tracking
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order/confirmation/:id';
  static const String orderTracking = '/order/track/:id';
  static const String orderDetail = '/order/:id';

  // Profile sub-pages
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';
  static const String addAddress = '/profile/addresses/add';
  static const String notifications = '/profile/notifications';
  static const String settings = '/settings';
  static const String writeReview = '/review/write/:productId';

  // Seller Shell
  static const String sellerShell = '/seller';
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerProducts = '/seller/products';
  static const String sellerAddProduct = '/seller/products/add';
  static const String sellerEditProduct = '/seller/products/edit/:id';
  static const String sellerOrders = '/seller/orders';
  static const String sellerOrderDetail = '/seller/orders/:id';
  static const String sellerAnalytics = '/seller/analytics';
  static const String sellerStore = '/seller/store';
  static const String sellerRegister = '/seller/register';
  static const String sellerPendingVerification = '/seller/pending';

  // Driver Shell
  static const String driverShell = '/driver';
  static const String driverDashboard = '/driver/dashboard';
  static const String driverDeliveries = '/driver/deliveries';
  static const String driverDeliveryDetail = '/driver/deliveries/:id';
  static const String driverNavigation = '/driver/navigate/:orderId';
  static const String driverEarnings = '/driver/earnings';
  static const String driverProfile = '/driver/profile';

  // Admin Shell
  static const String adminShell = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminSellers = '/admin/sellers';
  static const String adminSellerDetail = '/admin/sellers/:id';
  static const String adminDrivers = '/admin/drivers';
  static const String adminCreateDriver = '/admin/drivers/create';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminNotifications = '/admin/notifications';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminSettings = '/admin/settings';

  // Info pages
  static const String helpSupport = '/help-support';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String notificationPreferences = '/notification-preferences';

  // Static
  static const String notFound = '/404';
  static const String unauthorized = '/403';
}
