class ListingType {
  final String id;
  final String nameAr;
  final String nameEn;

  ListingType({required this.id, required this.nameAr, required this.nameEn});

  factory ListingType.fromJson(Map<String, dynamic> json) => ListingType(
    id: json['id'],
    nameAr: json['name_ar'],
    nameEn: json['name_en'],
  );
}

class PropertyType {
  final String id;
  final String nameAr;
  final String nameEn;

  // تم حذف قائمة الـ units لأن الأنواع أصبحت مسطحة الآن
  PropertyType({required this.id, required this.nameAr, required this.nameEn});

  factory PropertyType.fromJson(Map<String, dynamic> json) {
    return PropertyType(
      id: json['id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
    );
  }
}