import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

final productRepositoryProvider =
    Provider<ProductRepository>((_) => ProductRepository());

final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).productsStream();
});

final featuredProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref
      .watch(productRepositoryProvider)
      .productsStream(featuredOnly: true, limit: 10);
});

final fruitsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref
      .watch(productRepositoryProvider)
      .productsStream(category: ProductCategory.fruits);
});

final vegetablesProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref
      .watch(productRepositoryProvider)
      .productsStream(category: ProductCategory.vegetables);
});

final productDetailProvider =
    StreamProvider.family<ProductModel?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).productStream(id);
});

final productReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).reviewsStream(productId);
});

final searchQueryProvider = StateProvider<String>((_) => '');

final searchResultsProvider = StreamProvider<List<ProductModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref.watch(productRepositoryProvider).searchStream(query);
});

final selectedCategoryProvider =
    StateProvider<ProductCategory?>((_) => null);

final sellerProductsProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, sellerId) {
  return ref
      .watch(productRepositoryProvider)
      .productsStream(sellerId: sellerId);
});
