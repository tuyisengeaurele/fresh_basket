import 'package:get_it/get_it.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/products/data/repositories/product_repository.dart';
import '../../features/orders/data/repositories/order_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());
  sl.registerLazySingleton<ProductRepository>(() => ProductRepository());
  sl.registerLazySingleton<OrderRepository>(() => OrderRepository());

  // Services
  sl.registerLazySingleton(() => FirebaseService);
}
