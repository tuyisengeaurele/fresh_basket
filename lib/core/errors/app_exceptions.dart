import '../constants/app_strings.dart';

class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException()
      : super(AppStrings.networkError, code: 'network_error');
}

class AuthException extends AppException {
  const AuthException([String? message])
      : super(message ?? AppStrings.authError, code: 'auth_error');
}

class PermissionException extends AppException {
  const PermissionException()
      : super(AppStrings.permissionDenied, code: 'permission_denied');
}

class NotFoundException extends AppException {
  const NotFoundException([String? message])
      : super(message ?? 'Resource not found', code: 'not_found');
}

class ValidationException extends AppException {
  const ValidationException(String message)
      : super(message, code: 'validation_error');
}

String mapFirebaseAuthError(String code) {
  switch (code) {
    case 'email-already-in-use':
      return AppStrings.emailAlreadyInUse;
    case 'weak-password':
      return AppStrings.weakPassword;
    case 'invalid-email':
      return AppStrings.invalidEmail;
    case 'wrong-password':
    case 'invalid-credential':
      return AppStrings.wrongPassword;
    case 'user-not-found':
      return AppStrings.userNotFound;
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'operation-not-allowed':
      return 'This sign-in method is not allowed.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'requires-recent-login':
      return 'Please sign in again to complete this action.';
    case 'internal-error':
      return 'Firebase is not fully configured yet. Use Google Sign-In or Continue as Guest while this is resolved.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network and try again.';
    default:
      return AppStrings.genericError;
  }
}
