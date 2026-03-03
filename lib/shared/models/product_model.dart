import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory { fruits, vegetables }

class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fiber;
  final double fat;
  final String per;

  const NutritionInfo({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.fat = 0,
    this.per = '100g',
  });

  factory NutritionInfo.fromMap(Map<String, dynamic> map) => NutritionInfo(
        calories: (map['calories'] as num?)?.toDouble() ?? 0,
        protein: (map['protein'] as num?)?.toDouble() ?? 0,
        carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
        fat: (map['fat'] as num?)?.toDouble() ?? 0,
        per: map['per'] ?? '100g',
      );

  Map<String, dynamic> toMap() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fiber': fiber,
        'fat': fat,
        'per': per,
      };
}

class ProductModel {
  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final String sellerId;
  final String sellerName;
  final String sellerBusinessName;
  final double price;
  final String unit;
  final int stock;
  final int freshnessScore;
  final List<String> imageUrls;
  final NutritionInfo? nutritionInfo;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final bool isFeatured;
  final bool isSeasonal;
  final List<String> deliveryZones;
  final String? promoTag;
  final double? originalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.sellerBusinessName,
    required this.price,
    this.unit = 'kg',
    required this.stock,
    this.freshnessScore = 100,
    required this.imageUrls,
    this.nutritionInfo,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isSeasonal = false,
    this.deliveryZones = const [],
    this.promoTag,
    this.originalPrice,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: ProductCategory.values.firstWhere(
        (c) => c.name == (data['category'] ?? 'fruits'),
        orElse: () => ProductCategory.fruits,
      ),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerBusinessName: data['sellerBusinessName'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] ?? 'kg',
      stock: data['stock'] ?? 0,
      freshnessScore: data['freshnessScore'] ?? 100,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      nutritionInfo: data['nutritionInfo'] != null
          ? NutritionInfo.fromMap(data['nutritionInfo'])
          : null,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isSeasonal: data['isSeasonal'] ?? false,
      deliveryZones: List<String>.from(data['deliveryZones'] ?? []),
      promoTag: data['promoTag'],
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category.name,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerBusinessName': sellerBusinessName,
        'price': price,
        'unit': unit,
        'stock': stock,
        'freshnessScore': freshnessScore,
        'imageUrls': imageUrls,
        'nutritionInfo': nutritionInfo?.toMap(),
        'rating': rating,
        'reviewCount': reviewCount,
        'isAvailable': isAvailable,
        'isFeatured': isFeatured,
        'isSeasonal': isSeasonal,
        'deliveryZones': deliveryZones,
        'promoTag': promoTag,
        'originalPrice': originalPrice,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'metadata': metadata,
      };

  String get firstImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : '';

  bool get hasDiscount =>
      originalPrice != null && originalPrice! > price;

  double get discountPercent => hasDiscount
      ? ((originalPrice! - price) / originalPrice! * 100)
      : 0;

  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    int? stock,
    int? freshnessScore,
    List<String>? imageUrls,
    NutritionInfo? nutritionInfo,
    bool? isAvailable,
    bool? isFeatured,
    bool? isSeasonal,
    double? rating,
    int? reviewCount,
    String? promoTag,
    double? originalPrice,
    DateTime? updatedAt,
  }) =>
      ProductModel(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerBusinessName: sellerBusinessName,
        price: price ?? this.price,
        unit: unit,
        stock: stock ?? this.stock,
        freshnessScore: freshnessScore ?? this.freshnessScore,
        imageUrls: imageUrls ?? this.imageUrls,
        nutritionInfo: nutritionInfo ?? this.nutritionInfo,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        isAvailable: isAvailable ?? this.isAvailable,
        isFeatured: isFeatured ?? this.isFeatured,
        isSeasonal: isSeasonal ?? this.isSeasonal,
        deliveryZones: deliveryZones,
        promoTag: promoTag ?? this.promoTag,
        originalPrice: originalPrice ?? this.originalPrice,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata,
      );
}

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;
  final bool isVerifiedPurchase;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    required this.createdAt,
    this.isVerifiedPurchase = false,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'isVerifiedPurchase': isVerifiedPurchase,
      };
}
