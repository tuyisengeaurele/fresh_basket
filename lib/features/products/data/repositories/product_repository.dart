import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../shared/models/product_model.dart';

class ProductRepository {
  Stream<List<ProductModel>> productsStream({
    ProductCategory? category,
    String? sellerId,
    bool featuredOnly = false,
    int limit = 40,
  }) {
    Query<Map<String, dynamic>> query =
        FirebaseService.products.where('isAvailable', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (sellerId != null) {
      query = query.where('sellerId', isEqualTo: sellerId);
    }
    if (featuredOnly) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => ProductModel.fromFirestore(d)).toList());
  }

  Stream<List<ProductModel>> searchStream(String query) {
    if (query.trim().isEmpty) return productsStream();
    final lower = query.toLowerCase();
    return FirebaseService.products
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProductModel.fromFirestore(d))
            .where((p) =>
                p.name.toLowerCase().contains(lower) ||
                p.description.toLowerCase().contains(lower) ||
                p.sellerBusinessName.toLowerCase().contains(lower))
            .toList());
  }

  Future<ProductModel?> getById(String id) async {
    final doc = await FirebaseService.products.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Stream<ProductModel?> productStream(String id) {
    return FirebaseService.products
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? ProductModel.fromFirestore(d) : null);
  }

  Stream<List<ReviewModel>> reviewsStream(String productId) {
    return FirebaseService.reviews
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => ReviewModel.fromFirestore(d)).toList());
  }

  Future<String> addProduct(ProductModel product) async {
    final doc = await FirebaseService.products.add(product.toMap());
    return doc.id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await FirebaseService.products.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String id) async {
    await FirebaseService.products.doc(id).delete();
  }

  Future<void> submitReview(ReviewModel review) async {
    final batch = FirebaseService.firestore.batch();

    // Add review
    final reviewRef = FirebaseService.reviews.doc();
    batch.set(reviewRef, review.toMap());

    // Update product rating
    final productRef = FirebaseService.products.doc(review.productId);
    final productDoc = await productRef.get();
    if (productDoc.exists) {
      final current = ProductModel.fromFirestore(productDoc);
      final newCount = current.reviewCount + 1;
      final newRating =
          (current.rating * current.reviewCount + review.rating) / newCount;
      batch.update(productRef, {
        'rating': newRating,
        'reviewCount': newCount,
        // 'updatedAt' intentionally omitted — security rules only permit
        // customers to touch ['rating', 'reviewCount'] on a product doc.
      });
    }

    await batch.commit();
  }

  Future<bool> hasUserReviewed(String productId, String userId) async {
    final existing = await FirebaseService.reviews
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .get();
    return existing.docs.isNotEmpty;
  }

  Future<List<ProductModel>> getSellerProducts(String sellerId) async {
    final snap = await FirebaseService.products
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
  }
}
