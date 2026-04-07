import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgMain,
      hoverColor: AppColors.brandPrimary.withValues(alpha: 0.04),
      focusColor: AppColors.brandPrimary.withValues(alpha: 0.08),
      splashColor: AppColors.brandPrimary.withValues(alpha: 0.06),

      // تنسيق الـ AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2,
        iconTheme: const IconThemeData(color: AppColors.brandPrimary),
      ),

      // تنسيق الكروت
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.r12),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),

      // تنسيق حقول الإدخال — سيتم تجاوزه بواسطة NeonTextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        labelStyle: AppTextStyles.inputLabel.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle: AppTextStyles.inputLabel.copyWith(color: AppColors.brandPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.r8),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.r8),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.r8),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // تنسيق الأزرار المرفوعة
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
          ),
          textStyle: AppTextStyles.buttonLarge,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}