import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, seller, driver, admin }

enum SellerStatus { pending, approved, rejected, suspended }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String? phone;
  final UserRole role;
  final bool emailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.phone,
    required this.role,
    this.emailVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.fcmToken,
    this.metadata,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email']?.toString() ?? '',
      fullName: data['fullName']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString(),
      phone: data['phone']?.toString(), // toString() handles int stored by mistake
      role: UserRole.values.firstWhere(
        (r) => r.name == (data['role'] ?? 'customer'),
        orElse: () => UserRole.customer,
      ),
      emailVerified: data['emailVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken']?.toString(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'fullName': fullName,
        'photoUrl': photoUrl,
        'phone': phone,
        'role': role.name,
        'emailVerified': emailVerified,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'fcmToken': fcmToken,
        'metadata': metadata,
      };

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    String? phone,
    UserRole? role,
    bool? emailVerified,
    bool? isActive,
    DateTime? updatedAt,
    String? fcmToken,
    Map<String, dynamic>? metadata,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        fullName: fullName ?? this.fullName,
        photoUrl: photoUrl ?? this.photoUrl,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        emailVerified: emailVerified ?? this.emailVerified,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        fcmToken: fcmToken ?? this.fcmToken,
        metadata: metadata ?? this.metadata,
      );
}

class SellerProfile {
  final String uid;
  final String businessName;
  final String? tinNumber;
  final String storeAddress;
  final String nationalIdDocUrl;
  final SellerStatus status;
  final double rating;
  final int totalReviews;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  const SellerProfile({
    required this.uid,
    required this.businessName,
    this.tinNumber,
    required this.storeAddress,
    required this.nationalIdDocUrl,
    this.status = SellerStatus.pending,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.rejectionReason,
    required this.createdAt,
    this.verifiedAt,
  });

  factory SellerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerProfile(
      uid: doc.id,
      businessName: data['businessName'] ?? '',
      tinNumber: data['tinNumber'],
      storeAddress: data['storeAddress'] ?? '',
      nationalIdDocUrl: data['nationalIdDocUrl'] ?? '',
      status: SellerStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => SellerStatus.pending,
      ),
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'tinNumber': tinNumber,
        'storeAddress': storeAddress,
        'nationalIdDocUrl': nationalIdDocUrl,
        'status': status.name,
        'rating': rating,
        'totalReviews': totalReviews,
        'rejectionReason': rejectionReason,
        'createdAt': Timestamp.fromDate(createdAt),
        'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      };

  bool get isApproved => status == SellerStatus.approved;
}

class DriverProfile {
  final String uid;
  final String vehicleType;
  final String? vehiclePlate;
  final bool isAvailable;
  final double? currentLat;
  final double? currentLng;
  final String createdBySellerId;
  final double rating;
  final int totalDeliveries;
  final double totalEarnings;

  const DriverProfile({
    required this.uid,
    required this.vehicleType,
    this.vehiclePlate,
    this.isAvailable = false,
    this.currentLat,
    this.currentLng,
    required this.createdBySellerId,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
  });

  factory DriverProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverProfile(
      uid: doc.id,
      vehicleType: data['vehicleType']?.toString() ?? 'motorcycle',
      vehiclePlate: data['vehiclePlate']?.toString(),
      isAvailable: data['isAvailable'] ?? false,
      currentLat: (data['currentLat'] as num?)?.toDouble(),
      currentLng: (data['currentLng'] as num?)?.toDouble(),
      createdBySellerId: data['createdBySellerId']?.toString() ?? '',
      rating: (data['rating'] as num? ?? 0.0).toDouble(),
      totalDeliveries: (data['totalDeliveries'] as num? ?? 0).toInt(),
      totalEarnings: (data['totalEarnings'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'vehicleType': vehicleType,
        'vehiclePlate': vehiclePlate,
        'isAvailable': isAvailable,
        'currentLat': currentLat,
        'currentLng': currentLng,
        'createdBySellerId': createdBySellerId,
        'rating': rating,
        'totalDeliveries': totalDeliveries,
        'totalEarnings': totalEarnings,
      };
}

class DeliveryAddress {
  final String id;
  final String label;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final String? instructions;

  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
    this.instructions,
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) => DeliveryAddress(
        id: map['id'] ?? '',
        label: map['label'] ?? '',
        fullAddress: map['fullAddress'] ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        isDefault: map['isDefault'] ?? false,
        instructions: map['instructions'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'fullAddress': fullAddress,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
        'instructions': instructions,
      };
}
