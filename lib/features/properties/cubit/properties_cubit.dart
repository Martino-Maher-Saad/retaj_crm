import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../tasks/cubit/property_tasks_cubit.dart';
import '../../../data/models/property_image_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/realtime_service.dart';
import 'dart:async';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyRepository _repo;
  final RealtimeService _realtimeService;
  late final StreamSubscription _realtimeSubscription;

  String? _currentUserId;
  String? _currentUserRole;

  PropertiesCubit(this._repo, this._realtimeService) : super(PropertiesInitial()) {
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
  }

  bool _isManagerOrAdmin() {
    if (_currentUserRole == null) return false;
    final r = _currentUserRole!.toLowerCase();
    return r == 'manager' || r == 'admin' || r == 'ceo';

  }

  final Set<String> _myRecentActions = {};
  
  void _markActionByMe(String id) {
    _myRecentActions.add(id);
    Future.delayed(const Duration(seconds: 10), () {
      _myRecentActions.remove(id);
    });
  }



  void _handleRealtimeEvent(event) async {
    if (event.entity != 'property') return;
    
    final currentState = state is PropertiesSuccess ? state as PropertiesSuccess : null;
    if (currentState == null) return;

    if (event.action == 'insert') {
      try {
        bool canView = true;
        if (!_isManagerOrAdmin() && !_searchAll) {
          if (event.createdBy != _currentUserId) canView = false;
        } else {
          if (_filterAssignedTo != null && event.createdBy != _filterAssignedTo) canView = false;
        }

        if (!canView) return;

        // تأخير متعمد عشان ندي فرصة للصور تترفع على الـ Storage وتتضاف في الداتا بيز
        // الـ Delay ده مش هيوقف التطبيق لأنه async، ومهم جداً عشان العقار ميجيش فاضي للمدير
        await Future.delayed(const Duration(milliseconds: 2000));

        final newProp = await _repo.getPropertyById(event.id);
        
        if (isClosed) return;
        final freshState = state is PropertiesSuccess ? state as PropertiesSuccess : null;
        if (freshState == null) return;

        if (freshState.myProperties.any((p) => p.id == event.id) ||
            freshState.pendingProperties.any((p) => p.id == event.id)) {
          return;
        }

        final isMine = newProp.createdBy == _currentUserId || _myRecentActions.contains(event.id);

        if (isMine) {
           final newMy = List<PropertyModel>.from(freshState.myProperties)..insert(0, newProp);
           final newFiltered = List<PropertyModel>.from(freshState.filteredProperties)..insert(0, newProp);
           final newPending = freshState.pendingProperties.where((p) => p.id != event.id).toList();
           emit(freshState.copyWith(
              myProperties: newMy,
              filteredProperties: newFiltered,
              pendingProperties: newPending,
              myTotalCount: freshState.myTotalCount + 1,
           ));
        } else {
           final newPending = List<PropertyModel>.from(freshState.pendingProperties)..insert(0, newProp);
           emit(freshState.copyWith(hasNewUpdates: true, pendingProperties: newPending));
        }
      } catch (e) {
        // Ignore silently, don't show banner if fetch fails
      }
    } else if (event.action == 'update' || event.action == 'transfer') {
      try {
        final updatedProperty = await _repo.getPropertyById(event.id); 

        if (isClosed) return;
        final freshState = state is PropertiesSuccess ? state as PropertiesSuccess : null;
        if (freshState == null) return;

        bool canView = true;
        if (!_isManagerOrAdmin() && !_searchAll) {
          if (updatedProperty.createdBy != _currentUserId) canView = false;
        } else {
          if (_filterAssignedTo != null && updatedProperty.createdBy != _filterAssignedTo) canView = false;
        }

        final newMy = List<PropertyModel>.from(freshState.myProperties);
        final idxMy = newMy.indexWhere((p) => p.id == event.id);

        final newFiltered = List<PropertyModel>.from(freshState.filteredProperties);
        final idxFiltered = newFiltered.indexWhere((p) => p.id == event.id);
        
        final idxPending = freshState.pendingProperties.indexWhere((p) => p.id == event.id);

        if (idxMy == -1 && idxFiltered == -1) {
           if (!canView) {
              if (idxPending != -1) {
                 final newPending = List<PropertyModel>.from(freshState.pendingProperties)..removeAt(idxPending);
                 emit(freshState.copyWith(pendingProperties: newPending));
              }
              return;
           }
           
           final isMine = _myRecentActions.contains(event.id);

           if (isMine) {
              final newMy = List<PropertyModel>.from(freshState.myProperties)..insert(0, updatedProperty);
              final newFiltered = List<PropertyModel>.from(freshState.filteredProperties)..insert(0, updatedProperty);
              final newPending = freshState.pendingProperties.where((p) => p.id != event.id).toList();
              emit(freshState.copyWith(
                 myProperties: newMy,
                 filteredProperties: newFiltered,
                 pendingProperties: newPending,
                 myTotalCount: freshState.myTotalCount + 1,
              ));
           } else {
              final newPending = List<PropertyModel>.from(freshState.pendingProperties);
              if (idxPending != -1) {
                 newPending[idxPending] = updatedProperty;
              } else {
                 newPending.insert(0, updatedProperty);
              }
              emit(freshState.copyWith(hasNewUpdates: true, pendingProperties: newPending));
           }
           return;
        }

        bool lostOwnership = !canView;

        if (idxMy != -1) newMy[idxMy] = updatedProperty;
        if (idxFiltered != -1) newFiltered[idxFiltered] = updatedProperty;

        final newPending = List<PropertyModel>.from(freshState.pendingProperties);
        if (idxPending != -1) newPending[idxPending] = updatedProperty;

        emit(freshState.copyWith(
          myProperties: newMy,
          filteredProperties: newFiltered,
          pendingProperties: newPending,
          blinkItemId: event.id,
        ));

        if (lostOwnership) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!isClosed) {
              final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
              if (st != null) {
                final myProps = st.myProperties.where((p) => p.id != event.id).toList();
                final filProps = st.filteredProperties.where((p) => p.id != event.id).toList();
                emit(st.copyWith(myProperties: myProps, filteredProperties: filProps, blinkItemId: null, myTotalCount: st.myTotalCount - 1));
              }
            }
          });
        } else {
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (!isClosed) {
              final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
              if (st != null && st.blinkItemId == event.id) {
                emit(st.copyWith(blinkItemId: null));
              }
            }
          });
        }
      } catch (e) {
        // If it fails (e.g. RLS blocks them because they lost ownership), blink and remove it!
        if (event.action == 'transfer' || event.action == 'update') {
           final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
           if (st != null) {
              emit(st.copyWith(blinkItemId: event.id));
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!isClosed) {
                  final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
                  if (st != null) {
                    final myProps = st.myProperties.where((p) => p.id != event.id).toList();
                    final filProps = st.filteredProperties.where((p) => p.id != event.id).toList();
                    emit(st.copyWith(myProperties: myProps, filteredProperties: filProps, blinkItemId: null, myTotalCount: st.myTotalCount > 0 ? st.myTotalCount - 1 : 0));
                  }
                }
              });
           }
        }
      }
    } else if (event.action == 'delete') {
      // Blink and remove
      final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
      if (st != null) {
        emit(st.copyWith(blinkItemId: event.id));
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!isClosed) {
            final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
            if (st != null) {
              final newMy = st.myProperties.where((p) => p.id != event.id).toList();
              final newFiltered = st.filteredProperties.where((p) => p.id != event.id).toList();
              emit(st.copyWith(
                myProperties: newMy, 
                filteredProperties: newFiltered, 
                blinkItemId: null,
                myTotalCount: st.myTotalCount > 0 ? st.myTotalCount - 1 : 0,
                filteredTotalCount: st.filteredTotalCount > 0 ? st.filteredTotalCount - 1 : 0,
              ));
            }
          }
        });
      }
    } else if (event.action == 'bulk_transfer') {
      emit(currentState.copyWith(hasNewUpdates: true));
    }
  }

  void applyPendingUpdates() {
    final currentState = state is PropertiesSuccess ? state as PropertiesSuccess : null;
    if (currentState == null || currentState.pendingProperties.isEmpty) return;

    final newMy = [...currentState.pendingProperties, ...currentState.myProperties];
    final newFiltered = [...currentState.pendingProperties, ...currentState.filteredProperties];
    
    emit(currentState.copyWith(
      myProperties: newMy,
      filteredProperties: newFiltered,
      pendingProperties: [],
      hasNewUpdates: false,
      blinkItemId: currentState.pendingProperties.first.id,
      myTotalCount: currentState.myTotalCount + currentState.pendingProperties.length,
      filteredTotalCount: currentState.filteredTotalCount + currentState.pendingProperties.length,
    ));

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!isClosed) {
        final st = state is PropertiesSuccess ? state as PropertiesSuccess : null;
        if (st != null && st.blinkItemId == currentState.pendingProperties.first.id) {
          emit(st.copyWith(blinkItemId: null));
        }
      }
    });
  }

  @override
  Future<void> close() {
    _realtimeSubscription.cancel();
    return super.close();
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
  String? _filterApprovalStatusId;

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
  String? get filterApprovalStatusId => _filterApprovalStatusId;

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

  Future<void> fetchMyProperties({
    bool isRefresh = false,
    required String userId,
    required String role,
  }) async {
    _currentUserId = userId;
    _currentUserRole = role;

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
          role == 'manager' || role == 'admin' || role == 'ceo';
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
    String? approvalStatusId,
    bool searchAll = false,
    required String role,
    required String currentUserId,
  }) async {
    _currentUserId = currentUserId;
    _currentUserRole = role;

    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    emit(PropertiesLoading());
    try {
      String? filterUserId;
      if (role == 'manager' || role == 'admin' || role == 'ceo') {
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
      _filterApprovalStatusId = approvalStatusId;
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
        approvalStatusId: approvalStatusId,
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
        approvalStatusId: approvalStatusId,
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

  Future<bool> checkPropertyCodeExists(String code) async {
    try {
      return await _repo.checkPropertyCodeExists(code);
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllEmployees() async {
    try {
      return await _repo.fetchAllEmployees();
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
        approvalStatusId: _filterApprovalStatusId,
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
        
      if (current.myProperties.any((e) => e.id == newProp.id)) return;
      final updated = [newProp, ...current.myProperties];
      emit(
        current.copyWith(
          myProperties: updated,
          filteredProperties: updated,
          myTotalCount: current.myTotalCount + 1,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل إضافة العقار: $e"));
      emit(current);
    }
  }

  Future<void> deleteFullProperty(String id) async {
    _markActionByMe(id);
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
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
  }

  Future<void> togglePropertyPin(PropertyModel p) async {
    _markActionByMe(p.id!);
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      try {
        final updated = await _repo.togglePin(p.id, !p.isPinned);

        final updatedList = List<PropertyModel>.from(current.myProperties);
        final index = updatedList.indexWhere((x) => x.id == p.id);
        if (index != -1) {
          updatedList[index] = updated;

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
  }

  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<PropertyImageModel>? imagesToDelete,
    List<String> platformIds = const [],
    Map<String, dynamic>? partialUpdates,
    bool updateEmbeddings = false,
  }) async {
    _markActionByMe(property.id!);
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
        partialUpdates: partialUpdates,
        updateEmbeddings: updateEmbeddings,
      );
      final updatedList = current.myProperties.map((p) {
        return p.id == updatedProp.id ? updatedProp : p;
      }).toList();
      emit(current.copyWith(
        myProperties: updatedList,
        filteredProperties: updatedList,
      ));
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

  Future<List<PropertyModel>> fetchAllForExport({required String role, required String userId}) async {
    try {
      if (role == 'manager' || role == 'admin' || role == 'ceo') {
        return await _repo.filterProperties(
          0, 50000,
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
          approvalStatusId: _filterApprovalStatusId,
        );
      } else {
        return await _repo.getMyProperties(userId, 0, 50000);
      }
    } catch (e) {
      print('Properties export fetch error: $e');
      return [];
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
}
