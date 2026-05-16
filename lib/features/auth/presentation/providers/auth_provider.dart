import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

final authStateProvider = StreamProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges.map((u) => u != null);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

class AuthNotifier extends AsyncNotifier<UserModel?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<UserModel?> build() => _repo.getCurrentUser();

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
    if (state.hasValue && state.value != null) {
      await NotificationService.updateFcmToken(state.value!.uid);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInWithGoogle);
  }

  Future<void> registerWithGoogle({required UserRole role}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.registerWithGoogle(role: role),
    );
  }

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInAnonymously);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncData(null);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    final uid = state.value?.uid;
    if (uid == null) return;
    await _repo.updateUserProfile(
      uid: uid,
      fullName: fullName,
      phone: phone,
      photoUrl: photoUrl,
    );
    state = AsyncData(await _repo.getCurrentUser());
  }

  Future<void> refresh() async {
    state = AsyncData(await _repo.getCurrentUser());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
