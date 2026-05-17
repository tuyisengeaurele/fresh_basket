import 'product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  CartItem copyWith({ProductModel? product, int? quantity}) => CartItem(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );

  /// Minimal map used internally (e.g. for order creation)
  Map<String, dynamic> toMap() => {
        'productId': product.id,
        'quantity': quantity,
        'price': product.price,
      };

  /// Full serialisation for offline cart persistence
  Map<String, dynamic> toJson() => {
        'quantity': quantity,
        'product': {
          'id': product.id,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'originalPrice': product.originalPrice,
          'unit': product.unit,
          'category': product.category.name,
          'imageUrls': product.imageUrls,
          'sellerId': product.sellerId,
          'sellerName': product.sellerName,
          'sellerBusinessName': product.sellerBusinessName,
          'stock': product.stock,
          'rating': product.rating,
          'reviewCount': product.reviewCount,
          'freshnessScore': product.freshnessScore,
          'isAvailable': product.isAvailable,
          'isFeatured': product.isFeatured,
          'isSeasonal': product.isSeasonal,
          'promoTag': product.promoTag,
        },
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final p = json['product'] as Map<String, dynamic>;
    final product = ProductModel(
      id: p['id'] as String,
      name: p['name'] as String,
      description: p['description'] as String? ?? '',
      price: (p['price'] as num).toDouble(),
      originalPrice: (p['originalPrice'] as num?)?.toDouble(),
      unit: p['unit'] as String,
      category: ProductCategory.values.firstWhere(
        (c) => c.name == p['category'],
        orElse: () => ProductCategory.fruits,
      ),
      imageUrls: List<String>.from(p['imageUrls'] as List? ?? []),
      sellerId: p['sellerId'] as String? ?? '',
      sellerName: p['sellerName'] as String? ?? '',
      sellerBusinessName: p['sellerBusinessName'] as String? ?? '',
      stock: (p['stock'] as num?)?.toInt() ?? 0,
      rating: (p['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (p['reviewCount'] as num?)?.toInt() ?? 0,
      freshnessScore: (p['freshnessScore'] as num?)?.toInt() ?? 95,
      isAvailable: p['isAvailable'] as bool? ?? true,
      isFeatured: p['isFeatured'] as bool? ?? false,
      isSeasonal: p['isSeasonal'] as bool? ?? false,
      promoTag: p['promoTag'] as String?,
      createdAt: DateTime.now(), // not stored, safe fallback for cart display
    );
    return CartItem(product: product, quantity: (json['quantity'] as num).toInt());
  }
}

class CartModel {
  final List<CartItem> items;
  final String? promoCode;
  final double discount;

  const CartModel({
    this.items = const [],
    this.promoCode,
    this.discount = 0,
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.subtotal);

  double get deliveryFee {
    if (items.isEmpty) return 0;
    if (subtotal >= 5000) return 0;
    return 500;
  }

  double get total => subtotal + deliveryFee - discount;

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  bool hasProduct(String productId) =>
      items.any((i) => i.product.id == productId);

  int quantityOf(String productId) {
    final item =
        items.where((i) => i.product.id == productId).firstOrNull;
    return item?.quantity ?? 0;
  }

  CartModel copyWith({
    List<CartItem>? items,
    String? promoCode,
    double? discount,
  }) =>
      CartModel(
        items: items ?? this.items,
        promoCode: promoCode ?? this.promoCode,
        discount: discount ?? this.discount,
      );

  CartModel addItem(ProductModel product, {int quantity = 1}) {
    final existing = items.indexWhere((i) => i.product.id == product.id);
    final newItems = List<CartItem>.from(items);
    if (existing >= 0) {
      // Never exceed available stock
      final newQty = (newItems[existing].quantity + quantity)
          .clamp(1, product.stock);
      newItems[existing] = newItems[existing].copyWith(quantity: newQty);
    } else {
      // Clamp the initial quantity too
      final safeQty = quantity.clamp(1, product.stock.clamp(1, 999));
      newItems.add(CartItem(product: product, quantity: safeQty));
    }
    return copyWith(items: newItems);
  }

  CartModel removeItem(String productId) {
    final newItems = items.where((i) => i.product.id != productId).toList();
    return copyWith(items: newItems);
  }

  CartModel updateQuantity(String productId, int quantity) {
    if (quantity <= 0) return removeItem(productId);
    final newItems = items.map((i) {
      if (i.product.id == productId) {
        // Cap at the stock cached when the item was added to the cart
        final capped = quantity.clamp(1, i.product.stock.clamp(1, 999));
        return i.copyWith(quantity: capped);
      }
      return i;
    }).toList();
    return copyWith(items: newItems);
  }

  CartModel clear() => const CartModel();
}
