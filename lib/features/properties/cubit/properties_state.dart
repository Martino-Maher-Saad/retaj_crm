import '../../../data/models/property_model.dart';

sealed class PropertiesState {}

class PropertiesInitial extends PropertiesState {}
class PropertiesLoading extends PropertiesState {}

class PropertiesSuccess extends PropertiesState {
  // الكاش الجديد: يربط رقم الصفحة بقائمة عقاراتها
  final Map<int, List<PropertyModel>> propertyCache;
  final int currentPage;
  final int totalCount;
  final String? city;
  final String? type;
  final bool sortByPrice;

  PropertiesSuccess({
    required this.propertyCache, // تم التغيير من properties إلى propertyCache
    required this.currentPage,
    required this.totalCount,
    this.city,
    this.type,
    this.sortByPrice = false,
  });

  // Getter لجلب عقارات الصفحة الحالية بسهولة في الـ UI
  List<PropertyModel> get currentProperties => propertyCache[currentPage] ?? [];

  int get totalPages => (totalCount / 15).ceil();

  PropertiesSuccess copyWith({
    Map<int, List<PropertyModel>>? propertyCache, // تحديث الكاش
    int? currentPage,
    int? totalCount,
    String? city,
    String? type,
    bool? sortByPrice,
  }) {
    return PropertiesSuccess(
      // نستخدم Map.from لضمان إنشاء نسخة جديدة تماماً في الذاكرة (Deep Copy)
      // لكي يشعر الـ Bloc بالتغيير ويحدث الواجهة
      propertyCache: propertyCache ?? Map.from(this.propertyCache),
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      city: city ?? this.city,
      type: type ?? this.type,
      sortByPrice: sortByPrice ?? this.sortByPrice,
    );
  }
}

class PropertiesError extends PropertiesState {
  final String message;
  PropertiesError(this.message);
}