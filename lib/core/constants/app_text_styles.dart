import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {

  // القاعدة الأساسية للخطوط
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.4, // مثالي للعربي والإنجليزي معاً في Cairo
  }) {
    return TextStyle(
      fontSize: fontSize.sp, // يجعل الخط responsive
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontFamily: 'Cairo',
    );
  }

  // --- [ 1. DASHBOARD & STATS ] ---
  static TextStyle get displayLarge => _baseStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.brandPrimary);
  static TextStyle get statsNumber => _baseStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);

  // --- [ 2. HEADINGS (Leads & Properties) ] ---
  static TextStyle get h1 => _baseStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle get h2 => _baseStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.brandPrimaryDark);
  static TextStyle get h3 => _baseStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // --- [ 3. TABLE & LIST DATA (CRM Core) ] ---
  static TextStyle get tableHeader => _baseStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSecondary);
  static TextStyle get tableCellMain => _baseStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get tableCellSub => _baseStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);

  // --- [ 4. PROPERTY & DESIGN CARDS ] ---
  static TextStyle get cardTitle => _baseStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle get cardPrice => _baseStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.success);
  static TextStyle get cardLocation => _baseStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.info);

  // --- [ 5. FORMS & INPUTS (Lead Management) ] ---
  static TextStyle get inputLabel => _baseStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandPrimary);
  static TextStyle get inputText => _baseStyle(fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static TextStyle get helperText => _baseStyle(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.brandAccent);

  // --- [ 6. BUTTONS & CHIPS ] ---
  static TextStyle get buttonLarge => _baseStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get chipLabel => _baseStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, height: 1.1);




  // Headings
  static const TextStyle blue32Bold = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlueDark,
  );
  static const TextStyle blue28Bold = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlueDark,
  );
  static const TextStyle blue24Bold = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlueDark,
  );
  // Body Text
  static const TextStyle blue20Medium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );
  static const TextStyle blue18Medium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );
  static const TextStyle grey20Regular = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.greyDark,
  );
  // Sidebar & Buttons
  static const TextStyle white18SemiBold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  static const TextStyle white16Bold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 1.1,
  );
  // Specialized Styles
  static const TextStyle red16SemiBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryRed,
  );
  static const TextStyle blue16Bold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlueDark,
  );

}