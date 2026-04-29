import '../../data/models/dropdown_option_model.dart';
import '../../data/models/location_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/dropdown_repository.dart';
import '../../data/services/lead_service.dart';

abstract class StaticDataManager {
  Future<void> initialize();
  Future<void> refresh(); // يُستدعى بعد إضافة/حذف قيمة من الـ admin
  List<Governorate> get governorates;
  List<City> get allCities;
  List<ProfileModel> get employees; // قائمة الموظفين المحمّلة مسبقاً
  List<String> getOptions(String category);
  List<City> getCitiesByGovName(String govName);
  List<City> getCitiesByGovId(int govId);
  List<DropdownOptionModel> getOptionModels(String category);
}

class StaticDataManagerImpl implements StaticDataManager {
  final DropdownRepository _dropdownRepository;
  final LeadService _leadService;

  StaticDataManagerImpl(this._dropdownRepository, this._leadService);

  List<Governorate> _governorates = [];
  List<City> _cities = [];
  List<ProfileModel> _employees = [];

  // Map لتسريع البحث: category -> list of option values
  final Map<String, List<String>> _optionsMap = {};
  // Map لتسريع البحث: category -> list of DropdownOptionModel (للـ admin screen)
  final Map<String, List<DropdownOptionModel>> _optionModelsMap = {};
  // Map لتسريع جلب مدن محافظة: govId -> list of cities
  final Map<int, List<City>> _citiesByGovId = {};
  // Map لتسريع جلب مدن محافظة باسمها: govName -> list of cities
  final Map<String, List<City>> _citiesByGovName = {};

  @override
  Future<void> initialize() async {
    await _loadData();
  }

  @override
  Future<void> refresh() async {
    // يُستدعى بعد تعديل الـ admin على الـ dropdown options
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      // نحمّل البيانات الثابتة والموظفين بشكل موازٍ لتسريع التحميل
      final results = await Future.wait([
        _dropdownRepository.fetchAllStaticData(),
        _leadService.fetchAllEmployees(),
      ]);

      final data = results[0] as dynamic;
      _employees = results[1] as List<ProfileModel>;

      _governorates = data.governorates;
      _cities = data.cities;

      // بناء الـ Maps للبحث السريع
      _citiesByGovId.clear();
      _citiesByGovName.clear();
      _optionsMap.clear();
      _optionModelsMap.clear();

      // تجميع المدن حسب الـ governorateId
      for (final city in _cities) {
        _citiesByGovId.putIfAbsent(city.governorateId, () => []).add(city);
      }

      // تجميع المدن حسب اسم المحافظة
      for (final gov in _governorates) {
        _citiesByGovName[gov.name] = _citiesByGovId[gov.id] ?? [];
      }

      // تجميع الـ dropdown options حسب الـ category
      for (final option in data.options) {
        _optionsMap.putIfAbsent(option.category, () => []).add(option.valueAr);
        _optionModelsMap.putIfAbsent(option.category, () => []).add(option);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  List<Governorate> get governorates => _governorates;

  @override
  List<City> get allCities => _cities;

  @override
  List<ProfileModel> get employees => _employees;

  @override
  List<String> getOptions(String category) => _optionsMap[category] ?? [];

  @override
  List<DropdownOptionModel> getOptionModels(String category) =>
      _optionModelsMap[category] ?? [];

  @override
  List<City> getCitiesByGovName(String govName) =>
      _citiesByGovName[govName] ?? [];

  @override
  List<City> getCitiesByGovId(int govId) => _citiesByGovId[govId] ?? [];
}