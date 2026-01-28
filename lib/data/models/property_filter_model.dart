/// نموذج بيانات لتجميع فلاتر البحث والفلترة المتقدمة
class PropertyFilterModel {
  final String? query;           // للبحث النصي (TSVECTOR)
  final String? city;
  final String? district;
  final String? type;            // Sale / Rent
  final String? category;        // Apartment / Villa / etc
  final double? minPrice;
  final double? maxPrice;
  final double? minArea;
  final double? maxArea;
  final bool? isInstallment;
  final String? propertyCode;
  final String? finishingType;

  PropertyFilterModel({
    this.query,
    this.city,
    this.district,
    this.type,
    this.category,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.isInstallment,
    this.propertyCode,
    this.finishingType,
  });

  // تحويل الفلاتر إلى Map لاستخدامها بسهولة مع استعلامات Supabase
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (query != null && query!.isNotEmpty) map['query'] = query;
    if (city != null) map['city'] = city;
    if (district != null) map['district'] = district;
    if (type != null) map['type'] = type;
    if (category != null) map['category'] = category;
    if (minPrice != null) map['minPrice'] = minPrice;
    if (maxPrice != null) map['maxPrice'] = maxPrice;
    if (isInstallment != null) map['isInstallment'] = isInstallment;
    if (propertyCode != null) map['propertyCode'] = propertyCode;
    return map;
  }
}