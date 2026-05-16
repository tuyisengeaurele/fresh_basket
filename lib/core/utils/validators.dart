import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return AppStrings.invalidEmail;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 8) return AppStrings.passwordMinLength;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final base = password(value);
    if (base != null) return base;
    if (value != original) return AppStrings.passwordMismatch;
    return null;
  }

  static String? required(String? value, [String? label]) {
    if (value == null || value.trim().isEmpty) {
      return label != null ? '$label is required' : AppStrings.fieldRequired;
    }
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (value.trim().length < 2) return AppStrings.nameTooShort;
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleaned.length < 9 || cleaned.length > 15) {
      return AppStrings.phoneInvalid;
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return AppStrings.phoneInvalid;
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return 'Please enter a valid price';
    return null;
  }

  static String? stock(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Please enter a valid stock quantity';
    return null;
  }

  static String? optionalMinLength(String? value, int min) {
    if (value == null || value.isEmpty) return null;
    if (value.length < min) return 'Minimum $min characters required';
    return null;
  }
}
