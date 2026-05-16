import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyAuthToken = 'auth_token';
  static const _keyBiometricEnabled = 'biometric_enabled';

  static Future<void> saveUserId(String uid) =>
      _storage.write(key: _keyUserId, value: uid);

  static Future<String?> getUserId() => _storage.read(key: _keyUserId);

  static Future<void> saveUserRole(String role) =>
      _storage.write(key: _keyUserRole, value: role);

  static Future<String?> getUserRole() => _storage.read(key: _keyUserRole);

  static Future<void> saveAuthToken(String token) =>
      _storage.write(key: _keyAuthToken, value: token);

  static Future<String?> getAuthToken() => _storage.read(key: _keyAuthToken);

  static Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _keyBiometricEnabled, value: enabled.toString());

  static Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  static Future<void> clearAll() => _storage.deleteAll();

  static Future<void> clearSession() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserRole);
    await _storage.delete(key: _keyAuthToken);
  }
}
