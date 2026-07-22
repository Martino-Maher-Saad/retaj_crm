import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../tasks/cubit/property_tasks_cubit.dart';
import '../../../data/models/property_image_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/realtime_sync_service.dart';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyRepository _repo;
  final RealtimeSyncService _realtime;

  // ─── كاش صور العقارات ───
  // تتحمل فقط عند فتح صفحة تفاصيل العقار، وتبقى مخزنة حتى يحصل تغيير عليها
  final Map<String, List<PropertyImageModel>> _imagesCache = {};

  List<PropertyImageModel>? getCachedImages(String propertyId) =>
      _imagesCache[propertyId];

  void updateImagesCache(String propertyId, List<PropertyImageModel> images) {
    _imagesCache[propertyId] = images;
  }

  void invalidateImagesCache(String propertyId) {
    _imagesCache.remove(propertyId);
  }

  // الـ userId والـ role للتحقق من صلاحية التحديث
  String? _currentUserId;
  String? _currentRole;

  void setCurrentUser(String userId, String role) {
    _currentUserId = userId;
    _currentRole = role;
  }

  PropertiesCubit(this._repo, this._realtime) : super(PropertiesInitial()) {
    _realtime.events.listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(RealtimePayload payload) {
    if (state is! PropertiesSuccess) return;
    final currentState = state as PropertiesSuccess;

    if (payload.table == 'properties') {
      if (payload.type == RealtimeOpType.update || payload.type == RealtimeOpType.insert) {
        final propertyId = payload.newRecord['id']?.toString();
        if (propertyId == null) return;

        final assignedTo = payload.newRecord['assigned_to']?.toString();
        final isMine = assignedTo == _currentUserId;
        final isManager = AppRole.fromString(_currentRole ?? '').isAtLeast(AppRole.manager);

        // هل العقار موجود حالياً في الكاش المحلي؟
        final existsInMy = currentState.myProperties.any((p) => p.id == propertyId);
        final existsInFiltered = currentState.filteredProperties.any((p) => p.id == propertyId);
        final existsInSearched = currentState.searchedProperties.any((p) => p.id == propertyId);
        final existsInCache = existsInMy || existsInFiltered || existsInSearched;

        if (existsInCache) {
          // موجود → حدّثه وأضف وميض
          if (!isMine && !isManager) {
            // لم يعد مُسنداً لنا → احذفه
            final myProps = currentState.myProperties.where((p) => p.id != propertyId).toList();
            final filteredProps = currentState.filteredProperties.where((p) => p.id != propertyId).toList();
            final searchedProps = currentState.searchedProperties.where((p) => p.id != propertyId).toList();
            emit(currentState.copyWith(
              myProperties: myProps,
              filteredProperties: filteredProps,
              searchedProperties: searchedProps,
              flashingIds: {},
            ));
            return;
          }
          // نجلب التفاصيل بدون الصور (الصور في الكاش المنفصل)
          fetchPropertyDetails(propertyId, includeImages: false)
              .then((_) => _flashItem(propertyId));
        } else {
          // مش موجود في الكاش
          if (isMine || isManager) {
            fetchPropertyDetails(propertyId, includeImages: false)
                .then((_) => _flashItem(propertyId));
          }
          // موظف عادي وليس مُسنداً له → تجاهل
        }
      } else if (payload.type == RealtimeOpType.delete) {
        final deletedId = payload.oldRecord['id']?.toString();
        if (deletedId != null) {
          final myProps = currentState.myProperties.where((p) => p.id != deletedId).toList();
          final filteredProps = currentState.filteredProperties.where((p) => p.id != deletedId).toList();
          final searchedProps = currentState.searchedProperties.where((p) => p.id != deletedId).toList();
          invalidateImagesCache(deletedId);
          emit(currentState.copyWith(
            myProperties: myProps,
            filteredProperties: filteredProps,
            searchedProperties: searchedProps,
            flashingIds: {},
          ));
        }
      }
    } else if (payload.table == 'property_images') {
      // تغيير في الصور → نبطل كاش الصور فقط بدون fetchPropertyDetails كامل
      if (payload.type == RealtimeOpType.insert || payload.type == RealtimeOpType.delete) {
        final propertyId = payload.type == RealtimeOpType.insert
            ? payload.newRecord['property_id']?.toString()
            : payload.oldRecord['property_id']?.toString();
        if (propertyId != null) {
          // نبطل كاش الصور عشان لما يفتح صفحة تفاصيل العقار تجلب الصور الجديدة
          invalidateImagesCache(propertyId);
        }
      }
    }
  }

  /// يضيف وميضاً لحظياً على العقار المحدَّث — يختفي بعد 1.2 ثانية
  void _flashItem(String id) {
    if (state is! PropertiesSuccess || isClosed) return;
    final st = state as PropertiesSuccess;
    emit(st.copyWith(flashingIds: {id}));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (state is PropertiesSuccess && !isClosed) {
        emit((state as PropertiesSuccess).copyWith(flashingIds: {}));
      }
    });
  }

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
  bool? _filterIsArchived;

  // Public Getters for Filters
  int? get filterCityId => _filterCityId;
  String? get filterPropertyTypeId => _filterPropertyTypeId;
  int? get filterGovernorateId => _filterGovernorateId;
  String? get filterListingTypeId => _filterListingTypeId;
  num? get filterMinPrice => _filterMinPrice;
  num? get filterMaxPrice => _filterMaxPrice;
  String? get filterAssignedTo => _filterAssignedTo;
  DateTime? get filterFromDate => _filterFromDate;
  DateTime? get filterToDate => _filterToDate;
  bool? get filterIsArchived => _filterIsArchived;

  bool _isLoadingMoreFiltered = false;

  // Smart Search Pagination & Cache
  int _smartSearchOffset = 0;
  String _lastSmartSearchQuery = "";
  bool _hasMoreSmartSearch = true;
  bool _isLoadingMoreSmartSearch = false;
  List<double>? _cachedQueryEmbedding;
  bool _searchAll = false;

  // Getters for Search
  bool get searchAll => _searchAll;
  bool get isLoadingMoreSmartSearch => _isLoadingMoreSmartSearch;

  void toggleSearchAll(bool val) {
    _searchAll = val;
  }

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
        current.myTotalCount != 0)
      return;

    try {
      if (isRefresh) emit(PropertiesLoading());

      final isManagerOrAdmin =
          AppRole.fromString(role).isAtLeast(AppRole.manager);
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

      emit(
        current.copyWith(
          myProperties: isRefresh
              ? newItems
              : [...current.myProperties, ...newItems],
          myTotalCount: count,
        ),
      );
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
    bool? isArchived,
    bool searchAll = false,
    required String role,
    required String currentUserId,
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    emit(PropertiesLoading());
    try {
      String? filterUserId;
      if (AppRole.fromString(role).isAtLeast(AppRole.manager)) {
        filterUserId = selectedEmployee;
      } else if (!searchAll) {
        filterUserId = currentUserId;
      }

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
      _filterIsArchived = isArchived;
      _searchAll = searchAll;

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
        isArchived: isArchived,
      );
      final newItems = await _repo.filterProperties(
        0,
        14,
        cityId: cityId,
        propertyTypeId: propertyTypeId,
        governorateId: governorateId,
        listingTypeId: listingTypeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: filterUserId,
        fromDate: fromDate,
        toDate: toDate,
        isArchived: isArchived,
      );

      emit(
        current.copyWith(
          myProperties: current.myProperties,
          searchedProperties: const [],
          isSearching: false,
          filteredProperties: newItems,
          filteredTotalCount: count,
          isFiltering: true,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل الفلترة: $e"));
    }
  }

  Future<List<PropertyModel>> checkDuplicates(String ownerPhone) async {
    try {
      return await _repo.checkDuplicatePropertyPhone(ownerPhone);
    } catch (e) {
      return [];
    }
  }

  void patchProperty(PropertyModel updated) {
    if (state is! PropertiesSuccess) return;
    final current = state as PropertiesSuccess;
    emit(
      current.copyWith(
        myProperties: current.myProperties
            .map((e) => e.id == updated.id ? updated : e)
            .toList(),
        filteredProperties: current.filteredProperties
            .map((e) => e.id == updated.id ? updated : e)
            .toList(),
        searchedProperties: current.searchedProperties
            .map((e) => e.id == updated.id ? updated : e)
            .toList(),
      ),
    );
  }

  void removeProperty(String propertyId) {
    if (state is! PropertiesSuccess) return;
    final current = state as PropertiesSuccess;
    emit(
      current.copyWith(
        myProperties: current.myProperties
            .where((p) => p.id != propertyId)
            .toList(),
        filteredProperties: current.filteredProperties
            .where((p) => p.id != propertyId)
            .toList(),
        searchedProperties: current.searchedProperties
            .where((p) => p.id != propertyId)
            .toList(),
        myTotalCount: current.myTotalCount > 0 ? current.myTotalCount - 1 : 0,
        filteredTotalCount: current.filteredTotalCount > 0
            ? current.filteredTotalCount - 1
            : 0,
      ),
    );
  }

  Future<void> loadMoreFilteredProperties() async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    if (_isLoadingMoreFiltered) return;
    if (current.filteredProperties.length >= current.filteredTotalCount &&
        current.filteredTotalCount != 0)
      return;

    _isLoadingMoreFiltered = true;
    try {
      final from = current.filteredProperties.length;
      final newItems = await _repo.filterProperties(
        from,
        from + 14,
        cityId: _filterCityId,
        propertyTypeId: _filterPropertyTypeId,
        governorateId: _filterGovernorateId,
        listingTypeId: _filterListingTypeId,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
        assignedTo: _filterAssignedTo,
        fromDate: _filterFromDate,
        toDate: _filterToDate,
        isArchived: _filterIsArchived,
      );
      emit(
        current.copyWith(
          filteredProperties: [...current.filteredProperties, ...newItems],
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل تحميل المزيد: $e"));
    } finally {
      _isLoadingMoreFiltered = false;
    }
  }

  Future<void> search(String term, {String type = 'general', String? assignedTo}) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (term.isEmpty) {
      clearSearch();
      return;
    }
    emit(PropertiesLoading());
    try {
      final results = await _repo.searchProperties(term, type: type, assignedTo: assignedTo);
      emit(
        current.copyWith(
          searchedProperties: results, 
          isSearching: true,
          hasMoreSmartSearch: false, // Traditional search has no paging
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل البحث: $e"));
    }
  }

  Future<void> smartSearch(
    String query, {
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    num? minPrice,
    num? maxPrice,
    String? assignedTo,
    bool loadMore = false,
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    if (loadMore) {
      if (_isLoadingMoreSmartSearch || !_hasMoreSmartSearch) return;
      _smartSearchOffset += 10;
      _isLoadingMoreSmartSearch = true;
    } else {
      _smartSearchOffset = 0;
      _lastSmartSearchQuery = query;
      _hasMoreSmartSearch = true;
      _cachedQueryEmbedding = null;
      emit(PropertiesLoading());
    }

    try {
      List<double> vector;
      if (loadMore && _cachedQueryEmbedding != null) {
        vector = _cachedQueryEmbedding!;
      } else {
        vector = await _repo.generateQueryEmbedding(query);
        _cachedQueryEmbedding = vector;
      }

      final useFilters = current.isFiltering;
      final results = await _repo.searchWithAi(
        vector: vector,
        propertyTypeId:
            propertyTypeId ?? (useFilters ? _filterPropertyTypeId : null),
        listingTypeId:
            listingTypeId ?? (useFilters ? _filterListingTypeId : null),
        governorateId:
            governorateId ?? (useFilters ? _filterGovernorateId : null),
        cityId: cityId ?? (useFilters ? _filterCityId : null),
        minPrice: minPrice ?? (useFilters ? _filterMinPrice : null),
        maxPrice: maxPrice ?? (useFilters ? _filterMaxPrice : null),
        assignedTo: assignedTo ?? (useFilters ? _filterAssignedTo : null),
        limit: 10,
        offset: _smartSearchOffset,
      );

      _hasMoreSmartSearch = results.length == 10;
      final updatedList = loadMore
          ? [...current.searchedProperties, ...results]
          : results;

      emit(
        current.copyWith(
          searchedProperties: updatedList,
          isSearching: true,
          hasMoreSmartSearch: _hasMoreSmartSearch,
        ),
      );
    } catch (e, stackTrace) {
      print("========== SMART SEARCH ERROR ==========");
      print(e.toString());
      print(stackTrace.toString());
      print("========================================");
      emit(PropertiesError(e.toString()));
      emit(current);
    } finally {
      if (loadMore) {
        _isLoadingMoreSmartSearch = false;
      }
    }
  }

  Future<void> loadMoreSmartSearch() async {
    await smartSearch(_lastSmartSearchQuery, loadMore: true);
  }

  void clearSearch() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      _smartSearchOffset = 0;
      _lastSmartSearchQuery = "";
      _hasMoreSmartSearch = true;
      _cachedQueryEmbedding = null;
      emit(current.copyWith(isSearching: false, searchedProperties: []));
    }
  }

  void clearFilter() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      _filterCityId = null;
      _filterPropertyTypeId = null;
      _filterGovernorateId = null;
      _filterListingTypeId = null;
      _filterMinPrice = null;
      _filterMaxPrice = null;
      _filterFromDate = null;
      _filterToDate = null;
      _filterAssignedTo = null;
      _filterIsArchived = null;
      emit(current.copyWith(isFiltering: false, filteredProperties: []));
    }
  }

  Future<void> addProperty(
    PropertyModel p,
    List<Uint8List> imgs, {
    List<String> platformIds = const [],
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      final newProp = await _repo.createFullProperty(
        p,
        imgs,
        platformIds: platformIds,
      );
      di.sl<PropertyTasksCubit>()
        ..invalidateTasks()
        ..invalidateApprovals();
      emit(
        current.copyWith(
          myProperties: [newProp, ...current.myProperties],
          myTotalCount: current.myTotalCount + 1,
        ),
      );
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
      final updatedList = current.myProperties
          .where((p) => p.id != id)
          .toList();
      final filteredList = current.filteredProperties
          .where((p) => p.id != id)
          .toList();
      final searchedList = current.searchedProperties
          .where((p) => p.id != id)
          .toList();
      emit(
        current.copyWith(
          myProperties: updatedList,
          filteredProperties: filteredList,
          searchedProperties: searchedList,
          myTotalCount: current.myTotalCount > 0 ? current.myTotalCount - 1 : 0,
          filteredTotalCount: current.filteredTotalCount > 0
              ? current.filteredTotalCount - 1
              : 0,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل الحذف: $e"));
      emit(current);
    }
  }

  Future<void> togglePropertyPin(PropertyModel p) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      final updated = await _repo.togglePin(p.id, !p.isPinned);

      final updatedList = List<PropertyModel>.from(current.myProperties);
      final index = updatedList.indexWhere((x) => x.id == p.id);
      if (index != -1) {
        updatedList[index] = updated;

        // إعادة ترتيب القائمة لرفع المثبت للأعلى
        updatedList.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          final dateA = a.createdAt ?? DateTime.now();
          final dateB = b.createdAt ?? DateTime.now();
          return dateB.compareTo(dateA);
        });

        emit(current.copyWith(myProperties: updatedList));
      }
    } catch (e) {
      emit(PropertiesError(e.toString()));
      emit(current);
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
      final List<String> delIds =
          imagesToDelete?.map((e) => e.id!).toList() ?? [];
      final List<String> delUrls =
          imagesToDelete?.map((e) => e.imageUrl).toList() ?? [];

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

  Future<void> archiveProperty(String propertyId, bool isArchived) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      await _repo.archiveProperty(propertyId, isArchived);

      // إزالة من القوائم بغض النظر عن الأرشفة أو الاستعادة، لأن في الحالتين العقار بيسيب الصفحة الحالية
      final myProps = current.myProperties
          .where((e) => e.id != propertyId)
          .toList();
      final filteredProps = current.filteredProperties
          .where((e) => e.id != propertyId)
          .toList();
      final searchedProps = current.searchedProperties
          .where((e) => e.id != propertyId)
          .toList();

      emit(
        current.copyWith(
          myProperties: myProps,
          filteredProperties: filteredProps,
          searchedProperties: searchedProps,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل تحديث الأرشيف: $e"));
      emit(current);
    }
  }

  Future<void> sharePropertyInternal({
    required String propertyId,
    required String receiverId,
    String? note,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw Exception("U.O3OOO_U. OrUSO1 U.O3O_U, O_OU^U,");

    await _repo.sharePropertyInternal(
      propertyId: propertyId,
      senderId: session.user.id,
      receiverId: receiverId,
      note: note,
    );
  }

  /// جلب تفاصيل عقار محدد وتحديثه في الكاش
  /// [includeImages] = false عند الاستدعاء من الـ realtime (الصور في كاش منفصل)
  Future<void> fetchPropertyDetails(String propertyId, {bool includeImages = true}) async {
    if (state is PropertiesSuccess) {
      final st = state as PropertiesSuccess;
      try {
        final detailedProperty = await _repo.getPropertyById(propertyId);

        // هل موجود في القوائم؟ لو لا → أضفه في myProperties
        final existsInMy = st.myProperties.any((p) => p.id == propertyId);
        final existsInFiltered = st.filteredProperties.any((p) => p.id == propertyId);
        final existsInSearched = st.searchedProperties.any((p) => p.id == propertyId);

        final updatedMyProps = existsInMy
            ? st.myProperties.map((p) => p.id == propertyId ? detailedProperty : p).toList()
            : [detailedProperty, ...st.myProperties];

        final updatedFilteredProps = existsInFiltered
            ? st.filteredProperties.map((p) => p.id == propertyId ? detailedProperty : p).toList()
            : st.filteredProperties;

        final updatedSearchedProps = existsInSearched
            ? st.searchedProperties.map((p) => p.id == propertyId ? detailedProperty : p).toList()
            : st.searchedProperties;

        emit(st.copyWith(
          myProperties: updatedMyProps,
          filteredProperties: updatedFilteredProps,
          searchedProperties: updatedSearchedProps,
        ));
      } catch (e) {
        // تجاهل الخطأ — لا نريد crash بسبب حدث realtime
      }
    }
  }
}
