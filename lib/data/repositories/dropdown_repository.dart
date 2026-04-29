import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dropdown_option_model.dart';
import '../models/location_model.dart';
import '../services/dropdown_service.dart';

/// Repository للـ Dropdown data
/// يُستخدم من StaticDataManager عند التهيئة الأولى
class DropdownRepository {
  final DropdownService _service;

  DropdownRepository(this._service);

  /// جلب كل البيانات مرة واحدة: محافظات + مدن + كل خيارات الـ dropdown
  Future<({List<Governorate> governorates, List<City> cities, List<DropdownOptionModel> options})>
      fetchAllStaticData() async {
    // نجيب الاتنين بالتوازي عشان نوفر وقت
    final results = await Future.wait([
      _service.fetchGovernoratesWithCities(),
      _service.fetchAllOptions(),
    ]);

    final govRaw = results[0] as List<Map<String, dynamic>>;
    final optionsRaw = results[1] as List<DropdownOptionModel>;

    final governorates = <Governorate>[];
    final cities = <City>[];

    for (final govMap in govRaw) {
      final gov = Governorate.fromJson(govMap);
      governorates.add(gov);

      final citiesRaw = govMap['cities'] as List? ?? [];
      for (final cityMap in citiesRaw) {
        cities.add(City.fromJson(cityMap as Map<String, dynamic>));
      }
    }

    return (governorates: governorates, cities: cities, options: optionsRaw);
  }

  Future<DropdownOptionModel> addOption(String category, String valueAr) =>
      _service.addOption(category, valueAr);

  Future<void> deleteOption(String id) => _service.deleteOption(id);

  Future<DropdownOptionModel> updateOption(String id, String newValue) =>
      _service.updateOption(id, newValue);
}
