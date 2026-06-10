import '../models/location_model.dart';
import '../services/dropdown_service.dart';

class DropdownRepository {
  final DropdownService _service;

  DropdownRepository(this._service);

  /// جلب كل البيانات الثابتة للـ StaticDataManager (active فقط)
  Future<({
    List<Governorate> governorates,
    List<City> cities,
    Map<String, List<LookupOptionModel>> lookupOptions,
  })> fetchAllStaticData() async {
    final results = await Future.wait([
      _service.fetchGovernoratesWithCities(),   // 0
      _service.fetchLeadStatuses(),              // 1
      _service.fetchPropertyTypes(),             // 2
      _service.fetchListingTypes(),              // 3
      _service.fetchLeadPlatforms(),             // 4
      _service.fetchCommunicationChannels(),     // 5
      _service.fetchPropertySources(),           // 6
      _service.fetchAdvertisingPlatforms(),      // 7
      _service.fetchLeadExclusionReasons(),      // 8
      _service.fetchPropertyApprovalStatuses(),  // 9
    ]);

    final govRaw = results[0] as List<Map<String, dynamic>>;
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

    return (
      governorates: governorates,
      cities: cities,
      lookupOptions: {
        'lead_status':           results[1] as List<LookupOptionModel>,
        'property_type':         results[2] as List<LookupOptionModel>,
        'listing_type':          results[3] as List<LookupOptionModel>,
        'platform':              results[4] as List<LookupOptionModel>,
        'communication_channel': results[5] as List<LookupOptionModel>,
        'property_source':       results[6] as List<LookupOptionModel>,
        'advertising_platform':  results[7] as List<LookupOptionModel>,
        'lead_exclusion_reasons': results[8] as List<LookupOptionModel>,
        'property_approval_statuses': results[9] as List<LookupOptionModel>,
      },
    );
  }

  // ─── للـ Admin Management Screen ───

  Future<List<LookupOptionModel>> fetchAllForAdmin(String tableName, {bool isLocation = false}) =>
      _service.fetchAllForAdmin(tableName, isLocation: isLocation);

  Future<List<Map<String, dynamic>>> fetchGovernoratesWithCitiesForAdmin() =>
      _service.fetchGovernoratesWithCitiesForAdmin();

  Future<LookupOptionModel> addOption(
    String tableName,
    String nameAr, {
    bool isLocation = false,
    int? governorateId,
  }) => _service.addOption(tableName, nameAr, isLocation: isLocation, governorateId: governorateId);

  Future<LookupOptionModel> updateOption(
    String tableName,
    String id,
    String newName, {
    bool isLocation = false,
  }) => _service.updateOption(tableName, id, newName, isLocation: isLocation);

  Future<void> deactivateOption(String tableName, String id) =>
      _service.deactivateOption(tableName, id);

  Future<void> activateOption(String tableName, String id) =>
      _service.activateOption(tableName, id);
}
