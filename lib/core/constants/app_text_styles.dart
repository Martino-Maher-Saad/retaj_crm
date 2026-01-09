import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {

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
    color: AppColors.primaryBlue,
  );

}