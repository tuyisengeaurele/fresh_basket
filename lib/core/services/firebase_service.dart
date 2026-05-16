import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference<Map<String, dynamic>> get users =>
      firestore.collection('users');
  static CollectionReference<Map<String, dynamic>> get sellerProfiles =>
      firestore.collection('seller_profiles');
  static CollectionReference<Map<String, dynamic>> get driverProfiles =>
      firestore.collection('driver_profiles');
  static CollectionReference<Map<String, dynamic>> get products =>
      firestore.collection('products');
  static CollectionReference<Map<String, dynamic>> get orders =>
      firestore.collection('orders');
  static CollectionReference<Map<String, dynamic>> get reviews =>
      firestore.collection('reviews');
  static CollectionReference<Map<String, dynamic>> get notifications =>
      firestore.collection('notifications');
  static CollectionReference<Map<String, dynamic>> get promoCodes =>
      firestore.collection('promo_codes');
  static CollectionReference<Map<String, dynamic>> get auditLogs =>
      firestore.collection('audit_logs');
  static CollectionReference<Map<String, dynamic>> get platformSettings =>
      firestore.collection('platform_settings');

  static User? get currentUser => auth.currentUser;
  static String? get currentUid => auth.currentUser?.uid;
  static bool get isAuthenticated => auth.currentUser != null;

  static Future<void> logAudit({
    required String action,
    required String actorId,
    String? actorName,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? details,
  }) async {
    await auditLogs.add({
      'action': action,
      'actorId': actorId,
      'actorName': actorName,
      'targetId': targetId,
      'targetType': targetType,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
