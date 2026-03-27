import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/cart_model.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/repositories/order_repository.dart';

final orderRepositoryProvider =
    Provider<OrderRepository>((_) => OrderRepository());

final customerOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, customerId) {
  return ref.watch(orderRepositoryProvider).customerOrdersStream(customerId);
});

final sellerOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, sellerId) {
  return ref.watch(orderRepositoryProvider).sellerOrdersStream(sellerId);
});

final driverOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, driverId) {
  return ref.watch(orderRepositoryProvider).driverOrdersStream(driverId);
});

final orderDetailProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).orderStream(orderId);
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).allOrdersStream();
});

final pendingSellerOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>((ref, sellerId) {
  return ref
      .watch(orderRepositoryProvider)
      .pendingOrdersForSellerStream(sellerId);
});

class PlaceOrderNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> placeOrder({
    required UserModel customer,
    required CartModel cart,
    required DeliveryAddress address,
    String? scheduledTime,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).placeOrder(
            customer: customer,
            cart: cart,
            address: address,
            scheduledTime: scheduledTime,
          ),
    );
    state = result;
    return result.value;
  }
}

final placeOrderProvider =
    AsyncNotifierProvider<PlaceOrderNotifier, String?>(
        PlaceOrderNotifier.new);
