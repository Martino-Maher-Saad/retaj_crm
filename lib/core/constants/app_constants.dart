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

  // --- [ LEAD STATUS IDs ] ---
  static const String leadStatusFirstContact = "460be748-7685-49ef-abcf-c4dd49511ab7";
  static const String leadStatusSecondContact = "03453446-08ca-4061-ba50-ff915fcdf43a";
  static const String leadStatusThirdContact = "7bd8af5e-fb5b-41d1-955a-e5e5e1751d82";
  static const String leadStatusExcluded = "34f6f48c-3179-4b83-b34e-edc3fdc2e3d4";
  static const String leadStatusContracted = "6d5c7b17-9ef7-48ee-a9f6-0575cc390278";

  // --- [ PROPERTY APPROVAL STATUS IDs ] ---
  static const String propertyStatusPending = "634f7e69-6161-4535-b409-d1ea1bbbdcd3";
  static const String propertyStatusPublished = "70bb0089-736b-4607-951d-916fbcc1cc07";
  static const String propertyStatusRejected = "7345796d-1fd8-462d-b240-7eec15c87e6f";
  static const String propertyStatusApproved = "74076467-124a-4142-b821-6096d9fa3f4c";

  // --- [ ADVERTISING PLATFORM IDs ] ---
  static const String platformAqarMap = "07c10de8-4f0a-431a-826a-1aa52697c5ac";
  static const String platformPropertyFinder = "0f111e40-cebe-4f60-86e0-7b5aada827a1";
  static const String platformFacebook = "1a218d72-1dec-49c9-a9d4-8a84d99f9ce9";
  static const String platformBayut = "1f06bff1-1608-497c-8c83-b91c9ec7f14a";
  static const String platformOther = "4c96f691-57d6-4701-bca1-73792c370da4";
  static const String platformDubbizle = "d60fe2a8-269c-4aa9-b2ca-e6f96897ec46";
}
