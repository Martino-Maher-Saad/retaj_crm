import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/property_image_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyRepository _repo;
  PropertiesCubit(this._repo) : super(PropertiesInitial());

  // ─── Filter state — بالـ IDs الجديدة ───
  String? _filterAssignedTo;
  int? _filterCityId;
  String? _filterPropertyTypeId;
  int? _filterGovernorateId;
  String? _filterListingTypeId;
  num? _filterMinPrice;
  num? _filterMaxPrice;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;

  bool _isLoadingMoreFiltered = false;

  @override
  void emit(PropertiesState state) {
    if (!isClosed) super.emit(state);
  }

  // 1. جلب عقارات الموظف (أو المدير) — Infinite Scroll
  Future<void> fetchMyProperties({
    bool isRefresh = false,
    required String userId,
    required String role,
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    if (!isRefresh &&
        current.myProperties.length >= current.myTotalCount &&
        current.myTotalCount != 0) return;

    try {
      if (isRefresh) emit(PropertiesLoading());

      final isManagerOrAdmin = role == 'manager' || role == 'admin';
      final count = isManagerOrAdmin
          ? await _repo.fetchFilterCount()
          : await _repo.fetchMyCount(userId);

      final newItems = isManagerOrAdmin
          ? await _repo.filterProperties(
              isRefresh ? 0 : current.myProperties.length,
              (isRefresh ? 0 : current.myProperties.length) + 14,
            )
          : await _repo.getMyProperties(
              userId,
              isRefresh ? 0 : current.myProperties.length,
              (isRefresh ? 0 : current.myProperties.length) + 14,
            );

      emit(current.copyWith(
        myProperties: isRefresh ? newItems : [...current.myProperties, ...newItems],
        myTotalCount: count,
      ));
    } catch (e) {
      emit(PropertiesError("فشل تحميل العقارات: $e"));
    }
  }

  // 2. الفلترة المتقدمة — تستخدم IDs
  Future<void> applyAdvancedFilters({
    int? cityId,
    String? propertyTypeId,
    int? governorateId,
    String? listingTypeId,
    num? minPrice,
    num? maxPrice,
    String? selectedEmployee,
    DateTime? fromDate,
    DateTime? toDate,
    required String role,
    required String currentUserId,
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    emit(PropertiesLoading());
    try {
      final filterUserId =
          (role == 'manager' || role == 'admin') ? selectedEmployee : currentUserId;

      // تخزين الفلاتر بالـ IDs للـ loadMore
      _filterCityId = cityId;
      _filterPropertyTypeId = propertyTypeId;
      _filterGovernorateId = governorateId;
      _filterListingTypeId = listingTypeId;
      _filterMinPrice = minPrice;
      _filterMaxPrice = maxPrice;
      _filterFromDate = fromDate;
      _filterToDate = toDate;
      _filterAssignedTo = filterUserId;

      final count = await _repo.fetchFilterCount(
        cityId: cityId,
        propertyTypeId: propertyTypeId,
        governorateId: governorateId,
        listingTypeId: listingTypeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: filterUserId,
        fromDate: fromDate,
        toDate: toDate,
      );
      final newItems = await _repo.filterProperties(
        0, 14,
        cityId: cityId,
        propertyTypeId: propertyTypeId,
        governorateId: governorateId,
        listingTypeId: listingTypeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: filterUserId,
        fromDate: fromDate,
        toDate: toDate,
      );

      emit(current.copyWith(
        myProperties: current.myProperties,
        searchedProperties: const [],
        isSearching: false,
        filteredProperties: newItems,
        filteredTotalCount: count,
        isFiltering: true,
      ));
    } catch (e) {
      emit(PropertiesError("فشل الفلترة: $e"));
    }
  }

  Future<void> loadMoreFilteredProperties() async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    if (_isLoadingMoreFiltered) return;
    if (current.filteredProperties.length >= current.filteredTotalCount &&
        current.filteredTotalCount != 0) return;

    _isLoadingMoreFiltered = true;
    try {
      final from = current.filteredProperties.length;
      final newItems = await _repo.filterProperties(
        from, from + 14,
        cityId: _filterCityId,
        propertyTypeId: _filterPropertyTypeId,
        governorateId: _filterGovernorateId,
        listingTypeId: _filterListingTypeId,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
        assignedTo: _filterAssignedTo,
        fromDate: _filterFromDate,
        toDate: _filterToDate,
      );
      emit(current.copyWith(
        filteredProperties: [...current.filteredProperties, ...newItems],
      ));
    } catch (e) {
      emit(PropertiesError("فشل تحميل المزيد: $e"));
    } finally {
      _isLoadingMoreFiltered = false;
    }
  }

  Future<void> search(String term) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (term.isEmpty) {
      emit(current.copyWith(searchedProperties: []));
      return;
    }
    try {
      final results = await _repo.searchProperties(term);
      emit(current.copyWith(myProperties: results, myTotalCount: results.length));
    } catch (e) {
      emit(PropertiesError("فشل البحث: $e"));
    }
  }

  Future<void> smartSearch(String query) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (query.isEmpty) { clearSearch(); return; }
    emit(PropertiesLoading());
    try {
      final results = await _repo.searchWithAi(query);
      emit(current.copyWith(searchedProperties: results, isSearching: true));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      emit(current);
    }
  }

  void clearSearch() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      emit(current.copyWith(isSearching: false, searchedProperties: []));
    }
  }

  void clearFilter() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      emit(current.copyWith(isFiltering: false, filteredProperties: []));
    }
  }

  Future<void> addProperty(PropertyModel p, List<Uint8List> imgs, {List<String> platformIds = const []}) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      final newProp = await _repo.createFullProperty(p, imgs, platformIds: platformIds);
      emit(current.copyWith(
        myProperties: [newProp, ...current.myProperties],
        myTotalCount: current.myTotalCount + 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل إضافة العقار: $e"));
      emit(current);
    }
  }

  Future<void> deleteFullProperty(String id) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      await _repo.deleteFullProperty(id);
      final updatedList = current.myProperties.where((p) => p.id != id).toList();
      emit(current.copyWith(
        myProperties: updatedList,
        myTotalCount: current.myTotalCount - 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل حذف العقار: $e"));
    }
  }

  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<PropertyImageModel>? imagesToDelete,
    List<String> platformIds = const [],
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      final List<String> delIds = imagesToDelete?.map((e) => e.id!).toList() ?? [];
      final List<String> delUrls = imagesToDelete?.map((e) => e.imageUrl).toList() ?? [];

      final updatedProp = await _repo.updateFullProperty(
        p: property,
        newImgs: newImages,
        delImgsIds: delIds,
        delImgsUrls: delUrls,
        platformIds: platformIds,
      );
      final updatedList = current.myProperties.map((p) {
        return p.id == updatedProp.id ? updatedProp : p;
      }).toList();
      emit(current.copyWith(myProperties: updatedList));
    } catch (e) {
      emit(PropertiesError("فشل تحديث العقار: $e"));
      emit(current);
    }
  }
}
