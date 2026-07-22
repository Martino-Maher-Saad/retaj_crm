import '../../data/models/form_field_model.dart';
import '../../data/models/location_model.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/dropdown_repository.dart';
import '../../data/repositories/form_field_repository.dart';
import '../../data/services/dropdown_service.dart';
import '../../data/services/lead_service.dart';

import 'package:flutter/foundation.dart';

abstract class StaticDataManager extends ChangeNotifier {
  Future<void> initialize();
  Future<void> refresh();
  Future<void> refreshFormFields(); // تحديث الحقول فقط
  Future<void> refreshDropdowns(); // تحديث القوائم فقط (بدون employees أو formFields)
  Future<void> refreshEmployees(); // تحديث الموظفين فقط
  List<City> getActiveCities({String? includeName});
  List<City> get allCities;
  List<ProfileModel> get employees;
  List<FormFieldModel> get formFields;
  List<String> getOptions(String category);
  List<String> getActiveOptions(String category, {String? includeValue});

  List<LookupOptionModel> getOptionModels(String category);

  /// يرجع الـ UUID الخاص باسم معين في category معينة
  /// مثال: getIdByName('lead_status', 'جديد') => 'uuid-xxx'
  String? getIdByName(String category, String name);

  LookupOptionModel? getOptionById(String category, String id);
  LookupOptionModel? getOptionByName(String category, String name);

  /// يرجع قائمة بالـ status_ids التي ترتبط بـ stage_type له behavior محدد
  List<String> getStatusIdsByBehavior(String behavior);

  /// يرجع options جاهزة للعرض في حقل select_ref بناءً على اسم الجدول
  /// استخدم تحديداً: 'cities', 'property_types', الخ
  List<LookupOptionModel> getRefTableOptions(String refTable);

  /// يرجع الحقول المرئية لدور معين بعد تطبيق فلتر showInForm و isActive
  List<FormFieldModel> getFormFieldsForRole(String role, {bool onlyForm = true});
  bool canPerformAction(String actionKey, String role);
}

class StaticDataManagerImpl extends ChangeNotifier implements StaticDataManager {
  final DropdownRepository _dropdownRepository;
  final LeadService _leadService;
  final FormFieldRepository _formFieldRepository;

  StaticDataManagerImpl(this._dropdownRepository, this._leadService, this._formFieldRepository);

  List<Governorate> _governorates = [];
  List<City> _cities = [];
  List<ProfileModel> _employees = [];
  List<FormFieldModel> _formFields = [];

  // category -> List<String> للعرض في الـ Dropdown
  final Map<String, List<String>> _optionsMap = {};
  // category -> List<LookupOptionModel> للـ admin screen
  final Map<String, List<LookupOptionModel>> _optionModelsMap = {};
  // category -> { nameAr -> id } لتحويل الاختيار إلى UUID عند الحفظ
  final Map<String, Map<String, String>> _nameToIdMap = {};

  @override
  Future<void> initialize() async => await _loadData();

  @override
  Future<void> refresh() async => await _loadData();

  /// تحديث القوائم فقط (lead_statuses, cities, property_types, ...)
  /// يُستدعى لما الأدمن يغيّر في جداول القوائم
  @override
  Future<void> refreshDropdowns() async {
    try {
      final data = await _dropdownRepository.fetchAllStaticData();
      _governorates = data.governorates;
      _cities = data.cities;

      _optionsMap.clear();
      _optionModelsMap.clear();
      _nameToIdMap.clear();

      data.lookupOptions.forEach((category, options) {
        _optionsMap[category] = options.map((o) => o.nameAr).toList();
        _optionModelsMap[category] = options;
        _nameToIdMap[category] = {for (final o in options) o.nameAr: o.id};
      });
      notifyListeners();
    } catch (_) {}
  }

  /// تحديث قائمة الموظفين فقط
  /// يُستدعى لما يتغير شيء في جدول profiles
  @override
  Future<void> refreshEmployees() async {
    try {
      _employees = await _leadService.fetchAllEmployees();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _dropdownRepository.fetchAllStaticData(),
        _leadService.fetchAllEmployees(),
        _formFieldRepository.getFormFields('lead'),
      ]);

      final data =
          results[0]
              as ({
        List<Governorate> governorates,
        List<City> cities,
        Map<String, List<LookupOptionModel>> lookupOptions,
      });
      _employees = results[1] as List<ProfileModel>;
      _formFields = results[2] as List<FormFieldModel>;

      _governorates = data.governorates;
      _cities = data.cities;

      _optionsMap.clear();
      _optionModelsMap.clear();
      _nameToIdMap.clear();

      data.lookupOptions.forEach((category, options) {
        _optionsMap[category] = options.map((o) => o.nameAr).toList();
        _optionModelsMap[category] = options;
        _nameToIdMap[category] = {for (final o in options) o.nameAr: o.id};
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  @override
  List<City> get allCities => _cities;
  @override
  List<ProfileModel> get employees => _employees;
  @override
  List<FormFieldModel> get formFields => _formFields;
  @override
  List<String> getOptions(String category) => _optionsMap[category] ?? [];
  @override
  List<LookupOptionModel> getOptionModels(String category) =>
      _optionModelsMap[category] ?? [];
  @override
  String? getIdByName(String category, String name) =>
      _nameToIdMap[category]?[name];

  @override
  LookupOptionModel? getOptionById(String category, String id) {
    if (category == 'cities') {
      try {
        final c = _cities.firstWhere((c) => c.id.toString() == id);
        return LookupOptionModel(id: c.id.toString(), nameAr: c.name, isActive: c.isActive);
      } catch (_) { return null; }
    }
    if (category == 'governorates') {
      try {
        final g = _governorates.firstWhere((g) => g.id.toString() == id);
        return LookupOptionModel(id: g.id.toString(), nameAr: g.name, isActive: g.isActive);
      } catch (_) { return null; }
    }
    if (category == 'profiles') {
      try {
        final p = _employees.firstWhere((p) => p.id == id);
        return LookupOptionModel(id: p.id, nameAr: p.fullName, isActive: p.isActive);
      } catch (_) { return null; }
    }

    final options = _optionModelsMap[category];
    if (options == null) return null;
    try {
      return options.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  LookupOptionModel? getOptionByName(String category, String name) {
    if (category == 'cities') {
      try {
        final c = _cities.firstWhere((c) => c.name == name);
        return LookupOptionModel(id: c.id.toString(), nameAr: c.name, isActive: c.isActive);
      } catch (_) { return null; }
    }
    if (category == 'governorates') {
      try {
        final g = _governorates.firstWhere((g) => g.name == name);
        return LookupOptionModel(id: g.id.toString(), nameAr: g.name, isActive: g.isActive);
      } catch (_) { return null; }
    }
    if (category == 'profiles') {
      try {
        final p = _employees.firstWhere((p) => p.fullName == name);
        return LookupOptionModel(id: p.id, nameAr: p.fullName, isActive: p.isActive);
      } catch (_) { return null; }
    }

    final options = _optionModelsMap[category];
    if (options == null) return null;
    try {
      return options.firstWhere((o) => o.nameAr == name);
    } catch (_) {
      return null;
    }
  }

  @override
  List<String> getStatusIdsByBehavior(String behavior) {
    try {
      // 1. Get the stage_type ID for this behavior
      final stageTypes = _optionModelsMap['stage_types'] ?? [];
      final stageType = stageTypes.firstWhere(
        (s) => s.extra?['behavior'] == behavior,
      );

      // 2. Get all statuses linked to this stage_type ID
      final statuses = _optionModelsMap['lead_status'] ?? [];
      return statuses
          .where((s) => s.extra?['stage_type_id'] == stageType.id)
          .map((s) => s.id)
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  List<City> getActiveCities({String? includeName}) {
    return _cities.where((c) => c.isActive || c.name == includeName).toList();
  }

  @override
  Future<void> refreshFormFields() async {
    try {
      _formFields = await _formFieldRepository.getFormFields('lead');
      notifyListeners();
    } catch (_) {}
  }

  @override
  List<LookupOptionModel> getRefTableOptions(String refTable) {
    if (refTable == 'cities') {
      return _cities.map((c) => LookupOptionModel(id: c.id.toString(), nameAr: c.name, isActive: c.isActive)).toList();
    }
    if (refTable == 'governorates') {
      return _governorates.map((g) => LookupOptionModel(id: g.id.toString(), nameAr: g.name, isActive: g.isActive)).toList();
    }
    if (refTable == 'profiles') {
      return _employees.map((e) => LookupOptionModel(id: e.id, nameAr: e.fullName, isActive: e.isActive)).toList();
    }

    // تحويل اسم الجدول إلى المفتاح المخزن في _optionModelsMap
    // بعض الجداول محفوظة بنفس الاسم، وبعضها باسم مختلف في Map
    const tableToCategory = {
      'communication_channels': 'communication_channel',
      'property_types': 'property_type',
      'listing_types': 'listing_type',
      'lead_platforms': 'platform',
      'lead_statuses': 'lead_status',
      'lead_exclusion_reasons': 'lead_exclusion_reasons',
      'lead_rates': 'lead_rates',
    };
    final category = tableToCategory[refTable] ?? refTable;
    return _optionModelsMap[category] ?? [];
  }

  @override
  List<FormFieldModel> getFormFieldsForRole(String role, {bool onlyForm = true}) {
    return _formFields.where((f) {
      if (!f.isActive) return false;
      if (onlyForm && !f.showInForm) return false;
      return f.isVisibleForRole(role);
    }).toList()
      ..sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));
  }

  @override
  List<String> getActiveOptions(String category, {String? includeValue}) {
    final options = _optionModelsMap[category] ?? [];
    return options
        .where((o) => o.isActive || o.nameAr == includeValue)
        .map((o) => o.nameAr)
        .toList();
  }

  @override
  bool canPerformAction(String actionKey, String role) {
    if (role == 'admin' || role == 'super_admin') return true;
    final f = _formFields.where((f) => f.fieldKey == actionKey).firstOrNull;
    if (f == null || !f.isActive) return false;
    return f.isVisibleForRole(role);
  }
}
