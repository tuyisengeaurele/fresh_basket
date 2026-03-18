import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../shared/models/cart_model.dart';
import '../../../../shared/models/product_model.dart';

class CartNotifier extends Notifier<CartModel> {
  static const _boxName = 'cart';
  static const _key = 'cart_items';

  Box get _box => Hive.box(_boxName);

  @override
  CartModel build() {
    // Restore cart from Hive on cold start
    try {
      final raw = _box.get(_key) as String?;
      if (raw != null && raw.isNotEmpty) {
        final list = json.decode(raw) as List<dynamic>;
        final items = list
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return CartModel(items: items);
      }
    } catch (e) {
      debugPrint('[Cart] Failed to restore cart: $e');
    }
    return const CartModel();
  }

  void _persist(CartModel model) {
    try {
      final raw = json.encode(model.items.map((i) => i.toJson()).toList());
      _box.put(_key, raw);
    } catch (e) {
      debugPrint('[Cart] Failed to persist cart: $e');
    }
  }

  void addItem(ProductModel product, {int quantity = 1}) {
    state = state.addItem(product, quantity: quantity);
    _persist(state);
  }

  void removeItem(String productId) {
    state = state.removeItem(productId);
    _persist(state);
  }

  void updateQuantity(String productId, int quantity) {
    state = state.updateQuantity(productId, quantity);
    _persist(state);
  }

  void applyPromo(String code, double discount) {
    state = state.copyWith(promoCode: code, discount: discount);
    _persist(state);
  }

  void removePromo() {
    state = state.copyWith(promoCode: null, discount: 0);
    _persist(state);
  }

  void clear() {
    state = const CartModel();
    _persist(state);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartModel>(CartNotifier.new);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});
