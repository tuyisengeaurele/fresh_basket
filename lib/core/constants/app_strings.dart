class AppStrings {
  AppStrings._();

  static const String appName = 'FreshBasket';
  static const String tagline = 'Freshness Delivered.';
  static const String supportEmail = 'freshbasketrw@gmail.com';

  // Auth
  static const String login = 'Sign In';
  static const String register = 'Create Account';
  static const String logout = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String emailVerification = 'Verify Email';
  static const String continueWithGoogle = 'Continue with Google';
  static const String orSignInWith = 'Or sign in with';
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';

  // Roles
  static const String customer = 'Customer';
  static const String seller = 'Seller';
  static const String driver = 'Driver';
  static const String admin = 'Admin';

  // Onboarding
  static const String onboard1Title = 'Fresh From Farm';
  static const String onboard1Desc =
      'Get the freshest fruits and vegetables delivered from local farms to your doorstep.';
  static const String onboard2Title = 'Track Your Order';
  static const String onboard2Desc =
      'Watch your delivery in real-time with live GPS tracking and instant updates.';
  static const String onboard3Title = 'Pay on Delivery';
  static const String onboard3Desc =
      'Pay cash when your order arrives. Simple, safe, and convenient.';

  // Products
  static const String fruits = 'Fruits';
  static const String vegetables = 'Vegetables';
  static const String allProducts = 'All Products';
  static const String searchProducts = 'Search products...';
  static const String addToCart = 'Add to Cart';
  static const String outOfStock = 'Out of Stock';
  static const String inStock = 'In Stock';
  static const String freshness = 'Freshness Score';
  static const String nutritionInfo = 'Nutritional Info';
  static const String reviews = 'Reviews';
  static const String writeReview = 'Write a Review';
  static const String noReviews = 'No reviews yet. Be the first!';

  // Cart
  static const String cart = 'My Cart';
  static const String emptyCart = 'Your cart is empty';
  static const String emptyCartDesc = 'Add fresh products to get started!';
  static const String cartTotal = 'Total';
  static const String deliveryFee = 'Delivery Fee';
  static const String subtotal = 'Subtotal';
  static const String checkout = 'Checkout';
  static const String removeFromCart = 'Remove';
  static const String promoCode = 'Promo Code';
  static const String applyPromo = 'Apply';

  // Checkout
  static const String deliveryAddress = 'Delivery Address';
  static const String selectAddress = 'Select Address';
  static const String addNewAddress = 'Add New Address';
  static const String deliveryTime = 'Delivery Time';
  static const String paymentMethod = 'Payment Method';
  static const String cashOnDelivery = 'Cash on Delivery';
  static const String momoComingSoon = 'Mobile Money (Coming Soon)';
  static const String orderSummary = 'Order Summary';
  static const String placeOrder = 'Place Order';
  static const String orderPlaced = 'Order Placed!';
  static const String orderPlacedDesc =
      'Your order has been placed successfully. Track it in real-time!';

  // Orders
  static const String myOrders = 'My Orders';
  static const String orderHistory = 'Order History';
  static const String trackOrder = 'Track Order';
  static const String noOrders = 'No orders yet';
  static const String noOrdersDesc = 'Place your first order and enjoy fresh produce!';
  static const String reorder = 'Reorder';

  // Order statuses
  static const String statusPending = 'Pending';
  static const String statusConfirmed = 'Confirmed';
  static const String statusPreparing = 'Preparing';
  static const String statusAssigned = 'Driver Assigned';
  static const String statusPickedUp = 'Picked Up';
  static const String statusOnTheWay = 'On The Way';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';
  static const String statusFailed = 'Failed Delivery';

  // Tracking
  static const String liveTracking = 'Live Tracking';
  static const String driverOnWay = 'Driver is on the way';
  static const String estimatedArrival = 'Estimated Arrival';
  static const String driverNearby = 'Driver is nearby!';
  static const String orderDelivered = 'Order Delivered';

  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String myAddresses = 'My Addresses';
  static const String notifications = 'Notifications';
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String helpSupport = 'Help & Support';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String deleteAccount = 'Delete Account';
  static const String version = 'Version';

  // Seller
  static const String sellerDashboard = 'Seller Dashboard';
  static const String myProducts = 'My Products';
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit Product';
  static const String manageOrders = 'Manage Orders';
  static const String salesAnalytics = 'Sales Analytics';
  static const String myStore = 'My Store';
  static const String storeSettings = 'Store Settings';
  static const String pendingVerification = 'Verification Pending';
  static const String pendingVerificationDesc =
      'Your seller account is under review. We will notify you once approved.';
  static const String verificationRequired = 'Verification Required';
  static const String businessName = 'Business Name';
  static const String tinNumber = 'TIN Number (Optional)';
  static const String nationalId = 'National ID / Business Doc';
  static const String storeAddress = 'Store Address';

  // Driver
  static const String driverDashboard = 'Driver Dashboard';
  static const String myDeliveries = 'My Deliveries';
  static const String acceptDelivery = 'Accept Delivery';
  static const String rejectDelivery = 'Decline';
  static const String startNavigation = 'Start Navigation';
  static const String markPickedUp = 'Mark as Picked Up';
  static const String markDelivered = 'Mark as Delivered';
  static const String proofOfDelivery = 'Proof of Delivery';
  static const String earningsHistory = 'Earnings History';
  static const String availableDeliveries = 'Available Deliveries';

  // Admin
  static const String adminDashboard = 'Admin Dashboard';
  static const String manageUsers = 'Manage Users';
  static const String manageSellers = 'Manage Sellers';
  static const String manageDrivers = 'Manage Drivers';
  static const String manageProducts = 'Manage Products';
  static const String platformAnalytics = 'Platform Analytics';
  static const String orderMonitoring = 'Order Monitoring';
  static const String notifications_ = 'Notifications';
  static const String auditLogs = 'Audit Logs';
  static const String platformSettings = 'Platform Settings';
  static const String approveSeller = 'Approve Seller';
  static const String rejectSeller = 'Reject Seller';
  static const String createDriver = 'Create Driver';
  static const String broadcastNotification = 'Broadcast Notification';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection. Please check your network.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String emailAlreadyInUse = 'This email is already registered.';
  static const String weakPassword = 'Password is too weak. Use at least 8 characters.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String wrongPassword = 'Incorrect password. Please try again.';
  static const String userNotFound = 'No account found with this email.';
  static const String emailNotVerified = 'Please verify your email address first.';
  static const String permissionDenied = 'You do not have permission to perform this action.';

  // Validation
  static const String fieldRequired = 'This field is required';
  static const String passwordMinLength = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String phoneInvalid = 'Please enter a valid phone number';
  static const String nameTooShort = 'Name must be at least 2 characters';

  // Success
  static const String profileUpdated = 'Profile updated successfully!';
  static const String passwordReset = 'Password reset email sent. Check your inbox!';
  static const String reviewSubmitted = 'Review submitted successfully!';
  static const String addressSaved = 'Address saved successfully!';
  static const String productAdded = 'Product added successfully!';
  static const String productUpdated = 'Product updated successfully!';
  static const String productDeleted = 'Product deleted.';
}
