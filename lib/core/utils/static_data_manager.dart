import '../../data/models/location_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/dropdown_repository.dart';
import '../../data/services/dropdown_service.dart';
import '../../data/services/lead_service.dart';

abstract class StaticDataManager {
  Future<void> initialize();
  Future<void> refresh();
  List<Governorate> get governorates;
  List<Governorate> getActiveGovernorates({int? includeId});

  List<City> get allCities;
  List<ProfileModel> get employees;
  List<String> getOptions(String category);
  List<String> getActiveOptions(String category, {String? includeValue});

  List<City> getCitiesByGovName(String govName);
  List<City> getCitiesByGovId(int govId);
  List<City> getActiveCitiesByGovId(int govId, {int? includeId, String? includeName});

  List<LookupOptionModel> getOptionModels(String category);

  /// يرجع الـ UUID الخاص باسم معين في category معينة
  /// مثال: getIdByName('lead_status', 'جديد') => 'uuid-xxx'
  String? getIdByName(String category, String name);
}

class StaticDataManagerImpl implements StaticDataManager {
  final DropdownRepository _dropdownRepository;
  final LeadService _leadService;

  StaticDataManagerImpl(this._dropdownRepository, this._leadService);

  List<Governorate> _governorates = [];
  List<City> _cities = [];
  List<ProfileModel> _employees = [];

  // category -> List<String> للعرض في الـ Dropdown
  final Map<String, List<String>> _optionsMap = {};
  // category -> List<LookupOptionModel> للـ admin screen
  final Map<String, List<LookupOptionModel>> _optionModelsMap = {};
  // category -> { nameAr -> id } لتحويل الاختيار إلى UUID عند الحفظ
  final Map<String, Map<String, String>> _nameToIdMap = {};

  final Map<int, List<City>> _citiesByGovId = {};
  final Map<String, List<City>> _citiesByGovName = {};

  @override
  Future<void> initialize() async => await _loadData();

  @override
  Future<void> refresh() async => await _loadData();

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _dropdownRepository.fetchAllStaticData(),
        _leadService.fetchAllEmployees(),
      ]);

      final data = results[0] as ({
        List<Governorate> governorates,
        List<City> cities,
        Map<String, List<LookupOptionModel>> lookupOptions,
      });
      _employees = results[1] as List<ProfileModel>;

      _governorates = data.governorates;
      _cities = data.cities;

      _citiesByGovId.clear();
      _citiesByGovName.clear();
      _optionsMap.clear();
      _optionModelsMap.clear();
      _nameToIdMap.clear();

      for (final city in _cities) {
        _citiesByGovId.putIfAbsent(city.governorateId, () => []).add(city);
      }
      for (final gov in _governorates) {
        _citiesByGovName[gov.name] = _citiesByGovId[gov.id] ?? [];
      }

      data.lookupOptions.forEach((category, options) {
        _optionsMap[category] = options.map((o) => o.nameAr).toList();
        _optionModelsMap[category] = options;
        _nameToIdMap[category] = {
          for (final o in options) o.nameAr: o.id,
        };
      });

    } catch (e) {
      rethrow;
    }
  }

  @override List<Governorate> get governorates => _governorates;
  @override List<City> get allCities => _cities;
  @override List<ProfileModel> get employees => _employees;
  @override List<String> getOptions(String category) => _optionsMap[category] ?? [];
  @override List<LookupOptionModel> getOptionModels(String category) => _optionModelsMap[category] ?? [];
  @override List<City> getCitiesByGovName(String govName) => _citiesByGovName[govName] ?? [];
  @override List<City> getCitiesByGovId(int govId) => _citiesByGovId[govId] ?? [];
  @override String? getIdByName(String category, String name) => _nameToIdMap[category]?[name];

  @override
  List<Governorate> getActiveGovernorates({int? includeId}) {
    return _governorates.where((g) => g.isActive || g.id == includeId).toList();
  }

  @override
  List<City> getActiveCitiesByGovId(int govId, {int? includeId, String? includeName}) {
    final cities = _citiesByGovId[govId] ?? [];
    return cities.where((c) => c.isActive || c.id == includeId || c.name == includeName).toList();
  }

  @override
  List<String> getActiveOptions(String category, {String? includeValue}) {
    final options = _optionModelsMap[category] ?? [];
    return options.where((o) => o.isActive || o.nameAr == includeValue).map((o) => o.nameAr).toList();
  }
}