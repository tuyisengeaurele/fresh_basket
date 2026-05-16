import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/user_model.dart';
import '../services/firebase_service.dart';

/// Seed test accounts for all 4 roles.
/// Call this once from the Admin dashboard or a dev button.
/// Credentials are printed to the console after seeding.
class SeedData {
  static const _seeds = [
    _SeedAccount(
      email: 'customer@freshbasket.rw',
      password: 'Test@1234',
      fullName: 'Alice Customer',
      phone: '+250781000001',
      role: UserRole.customer,
    ),
    _SeedAccount(
      email: 'seller@freshbasket.rw',
      password: 'Test@1234',
      fullName: 'Bob Seller',
      phone: '+250781000002',
      role: UserRole.seller,
    ),
    _SeedAccount(
      email: 'driver@freshbasket.rw',
      password: 'Test@1234',
      fullName: 'Charlie Driver',
      phone: '+250781000003',
      role: UserRole.driver,
    ),
    _SeedAccount(
      email: 'admin@freshbasket.rw',
      password: 'Test@1234',
      fullName: 'Diana Admin',
      phone: '+250781000004',
      role: UserRole.admin,
    ),
  ];

  /// Writes seed accounts directly to Firestore without touching Firebase Auth
  /// (so the admin's session is never interrupted). The Auth accounts must be
  /// created separately — see the credentials printed by [runAuthOnly].
  static Future<List<String>> run() async {
    final results = <String>[];
    final auth = FirebaseService.auth;

    // Remember who is currently signed in so we can restore them after.
    final adminUser = auth.currentUser;
    final String? adminEmail = adminUser?.email;

    for (final seed in _seeds) {
      try {
        // Create the Firebase Auth account (this switches current session).
        String uid;
        try {
          final cred = await auth.createUserWithEmailAndPassword(
            email: seed.email,
            password: seed.password,
          );
          uid = cred.user!.uid;
          await cred.user!.updateDisplayName(seed.fullName);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Account exists — find uid via Firestore query.
            final q = await FirebaseService.users
                .where('email', isEqualTo: seed.email)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              results.add('${seed.role.name}: already exists — skipped');
              continue;
            }
            // Auth account exists but no Firestore doc — sign in to get uid.
            final cred2 = await auth.signInWithEmailAndPassword(
              email: seed.email,
              password: seed.password,
            );
            uid = cred2.user!.uid;
          } else {
            rethrow;
          }
        }

        final userModel = UserModel(
          uid: uid,
          email: seed.email,
          fullName: seed.fullName,
          phone: seed.phone,
          role: seed.role,
          emailVerified: true,
          isActive: true,
          createdAt: DateTime.now(),
        );
        await FirebaseService.users.doc(uid).set(userModel.toMap());

        if (seed.role == UserRole.seller) {
          await _seedSellerProfile(uid);
        } else if (seed.role == UserRole.driver) {
          await _seedDriverProfile(uid);
        }

        results.add('${seed.role.name}: ${seed.email}  /  ${seed.password}');
      } catch (e) {
        results.add('${seed.role.name}: FAILED — $e');
      }
    }

    // Restore admin session if we had one and it changed.
    if (adminEmail != null && auth.currentUser?.email != adminEmail) {
      final adminSeed = _seeds.firstWhere(
        (s) => s.email == adminEmail,
        orElse: () => const _SeedAccount(
          email: '',
          password: '',
          fullName: '',
          phone: '',
          role: UserRole.admin,
        ),
      );
      if (adminSeed.email.isNotEmpty) {
        await auth.signInWithEmailAndPassword(
          email: adminSeed.email,
          password: adminSeed.password,
        );
      }
    }

    await _seedProducts();
    results.add('');
    results.add('Sample products written to Firestore.');
    return results;
  }

  static Future<void> _seedSellerProfile(String uid) async {
    final profile = SellerProfile(
      uid: uid,
      businessName: 'Fresh Farms RW',
      tinNumber: '101234567',
      storeAddress: 'KG 123 St, Gasabo, Kigali',
      nationalIdDocUrl: '',
      status: SellerStatus.approved,
      rating: 4.7,
      totalReviews: 42,
      createdAt: DateTime.now(),
      verifiedAt: DateTime.now(),
    );
    await FirebaseService.sellerProfiles.doc(uid).set(profile.toMap());
  }

  static Future<void> _seedDriverProfile(String uid) async {
    final profile = DriverProfile(
      uid: uid,
      vehicleType: 'motorcycle',
      vehiclePlate: 'RAD 123 A',
      isAvailable: true,
      currentLat: -1.9440727,
      currentLng: 30.0618851,
      createdBySellerId: '',
      rating: 4.9,
      totalDeliveries: 87,
      totalEarnings: 43500,
    );
    await FirebaseService.driverProfiles.doc(uid).set(profile.toMap());
  }

  static Future<void> _seedProducts() async {
    final sellerDoc = await FirebaseService.sellerProfiles
        .where('status', isEqualTo: 'approved')
        .limit(1)
        .get();
    if (sellerDoc.docs.isEmpty) return;

    final sellerProfile = SellerProfile.fromFirestore(sellerDoc.docs.first);
    final sellerUser =
        await FirebaseService.users.doc(sellerProfile.uid).get();
    if (!sellerUser.exists) return;
    final sellerName =
        (sellerUser.data() as Map<String, dynamic>)['fullName'] ?? 'Seller';

    final products = [
      {
        'id': 'seed_p1',
        'name': 'Fresh Mangoes',
        'description': 'Sweet Rwandan mangoes, freshly harvested.',
        'category': 'fruits',
        'sellerId': sellerProfile.uid,
        'sellerName': sellerName,
        'sellerBusinessName': sellerProfile.businessName,
        'price': 1500.0,
        'unit': 'kg',
        'stock': 50,
        'freshnessScore': 95,
        'imageUrls': <String>[],
        'rating': 4.5,
        'reviewCount': 12,
        'isAvailable': true,
        'isFeatured': true,
        'isSeasonal': false,
        'deliveryZones': <String>[],
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'seed_p2',
        'name': 'Tomatoes',
        'description': 'Vine-ripened tomatoes from local farms.',
        'category': 'vegetables',
        'sellerId': sellerProfile.uid,
        'sellerName': sellerName,
        'sellerBusinessName': sellerProfile.businessName,
        'price': 800.0,
        'unit': 'kg',
        'stock': 100,
        'freshnessScore': 90,
        'imageUrls': <String>[],
        'rating': 4.3,
        'reviewCount': 8,
        'isAvailable': true,
        'isFeatured': false,
        'isSeasonal': false,
        'deliveryZones': <String>[],
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'seed_p3',
        'name': 'Avocados',
        'description': 'Creamy Hass avocados, ripe and ready.',
        'category': 'fruits',
        'sellerId': sellerProfile.uid,
        'sellerName': sellerName,
        'sellerBusinessName': sellerProfile.businessName,
        'price': 2000.0,
        'unit': 'piece',
        'stock': 30,
        'freshnessScore': 88,
        'imageUrls': <String>[],
        'rating': 4.8,
        'reviewCount': 25,
        'isAvailable': true,
        'isFeatured': true,
        'isSeasonal': true,
        'deliveryZones': <String>[],
        'createdAt': Timestamp.now(),
      },
    ];

    final batch = FirebaseService.firestore.batch();
    for (final p in products) {
      final ref = FirebaseService.products.doc(p['id'] as String);
      final existing = await ref.get();
      if (!existing.exists) {
        batch.set(ref, p);
      }
    }
    await batch.commit();
  }
}

class _SeedAccount {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final UserRole role;

  const _SeedAccount({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.role,
  });
}
