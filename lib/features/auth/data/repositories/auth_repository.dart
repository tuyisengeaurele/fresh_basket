import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseService.auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      return _getUserModel(user.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code));
    }
  }

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(fullName);

      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        fullName: fullName,
        phone: phone,
        role: role,
        emailVerified: false,
        createdAt: DateTime.now(),
      );

      await FirebaseService.users.doc(user.uid).set(userModel.toMap());
      await user.sendEmailVerification();
      await SecureStorageService.saveUserId(user.uid);
      await SecureStorageService.saveUserRole(role.name);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code));
    }
  }

  Future<UserModel> signInWithGoogle() async {
    return _googleSignInWithRole(UserRole.customer);
  }

  /// Used from the register page — respects the role the user selected.
  /// If the Google account already exists in Firestore the existing role is kept.
  Future<UserModel> registerWithGoogle({required UserRole role}) async {
    return _googleSignInWithRole(role);
  }

  Future<UserModel> _googleSignInWithRole(UserRole role) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      final existing = await FirebaseService.users.doc(user.uid).get();
      if (!existing.exists) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          photoUrl: user.photoURL,
          role: role,
          emailVerified: true,
          createdAt: DateTime.now(),
        );
        await FirebaseService.users.doc(user.uid).set(userModel.toMap());
        await SecureStorageService.saveUserRole(role.name);
      }

      await NotificationService.updateFcmToken(user.uid);
      await SecureStorageService.saveUserId(user.uid);
      return _getUserModel(user.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code));
    }
  }

  Future<UserModel> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user!;

      final existing = await FirebaseService.users.doc(user.uid).get();
      if (!existing.exists) {
        final guestModel = UserModel(
          uid: user.uid,
          email: '',
          fullName: 'Guest',
          role: UserRole.customer,
          emailVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          metadata: const {'isAnonymous': true},
        );
        await FirebaseService.users.doc(user.uid).set(guestModel.toMap());
        return guestModel;
      }
      return _getUserModel(user.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(mapFirebaseAuthError(e.code));
    }
  }

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await SecureStorageService.clearSession();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      return await _getUserModel(user.uid);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _getUserModel(String uid) async {
    final doc = await FirebaseService.users.doc(uid).get();
    if (!doc.exists) throw const NotFoundException('User profile not found');
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    await FirebaseService.users.doc(uid).update(updates);
    if (fullName != null) {
      await _auth.currentUser?.updateDisplayName(fullName);
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser!;
    if (user.email != null) {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
    }
    await FirebaseService.users.doc(user.uid).delete();
    await user.delete();
    await SecureStorageService.clearAll();
  }
}

// registerWithGoogle: supports role-based sign-up
