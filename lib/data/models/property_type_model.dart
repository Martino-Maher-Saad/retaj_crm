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
  final List<UnitType> units;

  PropertyType({required this.id, required this.nameAr, required this.nameEn, required this.units});

  factory PropertyType.fromJson(Map<String, dynamic> json) {
    return PropertyType(
      id: json['id'],
      nameAr: json['name_ar'],
      nameEn: json['name_en'],
      units: (json['units'] as List).map((u) => UnitType.fromJson(u)).toList(),
    );
  }
}

class UnitType {
  final String id;
  final String nameAr;
  final String nameEn;

  UnitType({required this.id, required this.nameAr, required this.nameEn});

  factory UnitType.fromJson(Map<String, dynamic> json) => UnitType(
    id: json['id'],
    nameAr: json['name_ar'],
    nameEn: json['name_en'],
  );
}