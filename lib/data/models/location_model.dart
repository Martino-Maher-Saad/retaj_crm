/// موديل المحافظة - يُقرأ من جدول governorates في الداتابيز
class Governorate {
  final int id;
  final String name; // اسم المحافظة بالعربي

  const Governorate({required this.id, required this.name});

  factory Governorate.fromJson(Map<String, dynamic> json) => Governorate(
    id: json['id'] as int,
    name: json['name']?.toString() ?? '',
  );
}

/// موديل المدينة - يُقرأ من جدول cities في الداتابيز
/// كل مدينة مرتبطة بمحافظة عن طريق governorateId
class City {
  final int id;
  final int governorateId;
  final String name; // اسم المدينة بالعربي

  const City({
    required this.id,
    required this.governorateId,
    required this.name,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'] as int,
    governorateId: json['governorate_id'] as int,
    name: json['name']?.toString() ?? '',
  );
}