// نضع هذه القوائم في ملف منفصل يسمى constants.dart
class AppConstants {
  static const int pageSize = 5;
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