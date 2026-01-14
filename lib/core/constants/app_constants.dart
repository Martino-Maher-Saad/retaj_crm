import 'package:flutter_screenutil/flutter_screenutil.dart';


// نضع هذه القوائم في ملف منفصل يسمى constants.dart
class AppConstants {

  // --- [ PADDING & MARGIN ] ---
  static double get p4 => 4.w;
  static double get p8 => 8.w;
  static double get p16 => 16.w;
  static double get p24 => 24.w;
  static double get p32 => 32.w;

  // --- [ RADIUS (Corner Roundness) ] ---
  static double get r4 => 4.r;
  static double get r8 => 8.r; // للـ TextFields والأزرار
  static double get r12 => 12.r; // للـ Cards
  static double get r20 => 20.r; // للـ Modals

  // --- [ ICON SIZES ] ---
  static double get iconSm => 16.sp;
  static double get iconMd => 24.sp;
  static double get iconLg => 32.sp;




  static const int pageSize = 5;
  static const double minDesktopWidth = 1100.0;
  static const int resizeDebounceMs = 100; // وقت التأخير بالمللي ثانية





  static const List<String> cities = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الشيخ زايد', 'التجمع الخامس'
  ];

  static const List<String> propertyTypes = [
    'شقة', 'فيلا', 'مكتب إداري', 'محل تجاري', 'استوديو'
  ];

  static const List<String> propertyStatus = [
    'Active', 'Pending', 'Sold'
  ];
}
