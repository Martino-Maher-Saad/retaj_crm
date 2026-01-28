class Governorate {
  final String id;
  final String nameAr;
  final String nameEn;

  Governorate({required this.id, required this.nameAr, required this.nameEn});

  factory Governorate.fromJson(Map<String, dynamic> json) => Governorate(
    id: json['id'],
    nameAr: json['name_ar'],
    nameEn: json['name_en'],
  );
}

class City {
  final String id;
  final String govId;
  final String nameAr;
  final String nameEn;

  City({required this.id, required this.govId, required this.nameAr, required this.nameEn});

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'],
    govId: json['gov_id'],
    nameAr: json['name_ar'],
    nameEn: json['name_en'],
  );
}