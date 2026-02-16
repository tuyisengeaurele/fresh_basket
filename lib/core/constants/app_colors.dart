import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — extracted from FreshBasket logo
  static const Color primary = Color(0xFF2E9E2E);
  static const Color primaryDark = Color(0xFF1A5C1A);
  static const Color primaryLight = Color(0xFF55CC22);
  static const Color accent = Color(0xFFE8651A);
  static const Color accentLight = Color(0xFFFF8A40);

  // Greens scale
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);

  // Orange scale
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange400 = Color(0xFFFFCA28);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange600 = Color(0xFFFB8C00);

  // Semantic
  static const Color success = Color(0xFF2E9E2E);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1976D2);

  // Light theme surfaces
  static const Color backgroundLight = Color(0xFFF8FAF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE8F0E8);

  // Dark theme surfaces
  static const Color backgroundDark = Color(0xFF0F1A0F);
  static const Color surfaceDark = Color(0xFF1A2A1A);
  static const Color cardDark = Color(0xFF1E301E);
  static const Color dividerDark = Color(0xFF2A3D2A);

  // Text
  static const Color textPrimary = Color(0xFF1A2A1A);
  static const Color textSecondary = Color(0xFF5A7A5A);
  static const Color textHint = Color(0xFF9EBD9E);
  static const Color textPrimaryDark = Color(0xFFF0F8F0);
  static const Color textSecondaryDark = Color(0xFFAAC4AA);

  // Glassmorphism
  static Color glassWhite = Colors.white.withOpacity(0.15);
  static Color glassDark = Colors.black.withOpacity(0.15);
  static Color glassGreen = const Color(0xFF2E9E2E).withOpacity(0.12);

  // Rating star
  static const Color star = Color(0xFFFFB300);

  // Status chips
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusConfirmed = Color(0xFF1976D2);
  static const Color statusInTransit = Color(0xFF9C27B0);
  static const Color statusDelivered = Color(0xFF2E9E2E);
  static const Color statusCancelled = Color(0xFFE53935);
  static const Color statusFailed = Color(0xFF795548);

  // Role badges
  static const Color roleCustomer = Color(0xFF1976D2);
  static const Color roleSeller = Color(0xFF7B1FA2);
  static const Color roleDriver = Color(0xFF00796B);
  static const Color roleAdmin = Color(0xFFC62828);
}
