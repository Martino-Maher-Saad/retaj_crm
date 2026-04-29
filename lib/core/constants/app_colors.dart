import 'package:flutter/material.dart';

class AppColors {

  // --- [ BRAND PRIMARY - Blue Scale ] ---
  // التسمية وظيفية: تستخدم درجات الأزرق في العناصر القيادية والأساسية
  static const Color brandPrimary = Color(0xFF2E3192); // اللون الأصلي
  static const Color brandPrimaryDark = Color(0xFF1D1F5E);
  static const Color brandPrimaryLight = Color(0xFF5A5EB9);
  static const Color brandPrimarySurface = Color(0xFFEAEBFF); // لخلفية العناصر المختارة

  // --- [ BRAND ACCENT - Red Scale ] ---
  // تستخدم للأفعال التي تحتاج انتباه (الحذف، التنبيهات، العناصر الهامة)
  static const Color brandAccent = Color(0xFFE31E24); // اللون الأصلي
  static const Color brandAccentDark = Color(0xFFB3171B);
  static const Color brandAccentLight = Color(0xFFED5D62);
  static const Color brandAccentSurface = Color(0xFFFFEBEC);

  // --- [ NEUTRALS - Grayscale ] ---
  // التسمية حسب الوظيفة (نص، حدود، خلفية)
  static const Color textPrimary = Color(0xFF1A1A1A); // العناوين
  static const Color textSecondary = Color(0xFF666666); // النصوص الفرعية
  static const Color textDisabled = Color(0xFF9E9E9E);

  static const Color borderSubtle = Color(0xFFE0E0E0); // حدود خفيفة
  static const Color borderStrong = Color(0xFFBDBDBD); // حدود الحقول

  static const Color bgMain = Color(0xFFF8F9FA); // خلفية التطبيق
  static const Color bgSurface = Colors.white;    // خلفية الكروت
  static const Color bgSideBar = Color(0xFF1A1F2E);

  // --- [ STATUS ] ---
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);
  static const Color error = Color(0xFFD32F2F);

}
