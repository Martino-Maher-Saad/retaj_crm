import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';



class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgMain,

      // تنسيق الـ AppBar (للـ Leads & Accounts)
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: const IconThemeData(color: AppColors.brandPrimary),
      ),

      // تنسيق الكروت (Properties & Designs)
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 2,
        shadowColor: AppColors.textSecondary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.r12)),
      ),

      // تنسيق حقول الإدخال بشكل احترافي
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.r8),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.r8),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
      ),
    );
  }
}