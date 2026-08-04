import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/realtime_service.dart';
import 'marketing_state.dart';

class MarketingCubit extends Cubit<MarketingState> {
  final PropertyRepository _repo;
  final RealtimeService _realtimeService;
  late final StreamSubscription _realtimeSubscription;
  
  String? _excludeUserId;

  MarketingCubit(this._repo, this._realtimeService) : super(MarketingInitial()) {
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
  }

  @override
  Future<void> close() {
    _realtimeSubscription.cancel();
    return super.close();
  }

  void _handleRealtimeEvent(event) async {
    if (event.entity != 'property') return;
    
    final current = state is MarketingSuccess ? state as MarketingSuccess : null;
    if (current == null) return;
    
    if (event.action == 'update' || event.action == 'insert' || event.action == 'transfer') {
      try {
        final updatedProp = await _repo.getPropertyById(event.id);
        
        if (isClosed) return;
        final freshState = state is MarketingSuccess ? state as MarketingSuccess : null;
        if (freshState == null) return;

        // تجاهل لو المستخدم هو اللي ضافه/عنده العقار ده لأن الشاشة دي للإعلانات الخاصة بالشركة (ما عدا عقاراته)
        if (_excludeUserId != null && updatedProp.createdBy == _excludeUserId) return;

        if (event.action == 'insert') {
          // Add to pending to show the refresh button
          final idxPending = freshState.pendingProperties.indexWhere((p) => p.id == event.id);
          final idxProps = freshState.properties.indexWhere((p) => p.id == event.id);
          if (idxPending == -1 && idxProps == -1) {
            final newPending = List<PropertyModel>.from(freshState.pendingProperties)..insert(0, updatedProp);
            emit(freshState.copyWith(hasNewUpdates: true, pendingProperties: newPending));
          }
        } else {
          // If updating or transferring
          final existingIndex = freshState.properties.indexWhere((p) => p.id == event.id);
          final originalIndex = freshState.originalProperties.indexWhere((p) => p.id == event.id);
          
          List<PropertyModel> newList = List.from(freshState.properties);
          List<PropertyModel> newOriginalList = List.from(freshState.originalProperties);
          
          if (existingIndex != -1) {
            newList[existingIndex] = updatedProp;
          } else {
            newList.insert(0, updatedProp);
          }
          
          if (originalIndex != -1) {
            newOriginalList[originalIndex] = updatedProp;
          } else {
            newOriginalList.insert(0, updatedProp);
          }
          
          // Remove from pending if it somehow got there
          final newPending = freshState.pendingProperties.where((p) => p.id != event.id).toList();
          
          emit(freshState.copyWith(
            properties: newList, 
            originalProperties: newOriginalList,
            pendingProperties: newPending,
          ));
        }
      } catch (_) {}
    } else if (event.action == 'delete') {
      final freshState = state is MarketingSuccess ? state as MarketingSuccess : null;
      if (freshState == null) return;
      
      final newList = freshState.properties.where((p) => p.id != event.id).toList();
      emit(freshState.copyWith(properties: newList));
    }
  }

  void applyPendingUpdates() {
    if (state is! MarketingSuccess) return;
    final current = state as MarketingSuccess;
    if (current.pendingProperties.isEmpty) return;

    // دمج بدون تكرار
    final Map<String, PropertyModel> mergedMap = {};
    for (var p in current.properties) { mergedMap[p.id] = p; }
    for (var p in current.pendingProperties) { mergedMap[p.id] = p; } // يحل محل القديم
    
    final Map<String, PropertyModel> originalMergedMap = {};
    for (var p in current.originalProperties) { originalMergedMap[p.id] = p; }
    for (var p in current.pendingProperties) { originalMergedMap[p.id] = p; }
    
    // الترتيب: الجديد أولاً (بناءً على افتراض أن pending بيكون هو الأحدث)
    // أو نكتفي بتحويلهم إلى List، الأفضل وضع pending في الأول
    final finalProperties = [
      ...current.pendingProperties.where((p) => !current.properties.any((ex) => ex.id == p.id)),
      ...current.properties.map((p) => mergedMap[p.id]!)
    ];
    
    final finalOriginal = [
      ...current.pendingProperties.where((p) => !current.originalProperties.any((ex) => ex.id == p.id)),
      ...current.originalProperties.map((p) => originalMergedMap[p.id]!)
    ];

    emit(current.copyWith(
      properties: finalProperties,
      originalProperties: finalOriginal,
      pendingProperties: [],
      hasNewUpdates: false,
      totalCount: current.totalCount + current.pendingProperties.length,
    ));
  }

  static const int _pageSize = 20;

  /// تحميل عقارات صفحة إدارة الإعلانات (كل الشركة ما عدا عقارات المستخدم نفسه)
  Future<void> fetchProperties({
    required String excludeUserId,
    bool isRefresh = false,
    String? filterEmployeeId,
    String? filterApprovalStatusId,
    DateTime? filterFromDate,
    DateTime? filterToDate,
    String? filterPropertyCode,
    bool overwriteFilters = false,
    List<String>? assignedEmployeeIds,
  }) async {
    _excludeUserId = excludeUserId;
    final currentSuccess = state is MarketingSuccess ? state as MarketingSuccess : null;

    final appliedEmployeeId = overwriteFilters ? filterEmployeeId : (filterEmployeeId ?? currentSuccess?.filterEmployeeId);
    final appliedStatusId = overwriteFilters ? filterApprovalStatusId : (filterApprovalStatusId ?? currentSuccess?.filterApprovalStatusId);
    final appliedFromDate = overwriteFilters ? filterFromDate : (filterFromDate ?? currentSuccess?.filterFromDate);
    final appliedToDate = overwriteFilters ? filterToDate : (filterToDate ?? currentSuccess?.filterToDate);
    final appliedCode = overwriteFilters ? filterPropertyCode : (filterPropertyCode ?? currentSuccess?.filterPropertyCode);

    final from = isRefresh ? 0 : (currentSuccess?.properties.length ?? 0);

    try {
      if (isRefresh || (appliedEmployeeId != null || appliedStatusId != null || appliedFromDate != null || appliedToDate != null || (appliedCode != null && appliedCode.isNotEmpty))) {
        emit(MarketingLoading());
      }
      
      final count = await _repo.fetchAdsManagementCount(
        excludeUserId: excludeUserId,
        assignedToFilter: appliedEmployeeId,
        approvalStatusId: appliedStatusId,
        fromDate: appliedFromDate,
        toDate: appliedToDate,
        propertyCode: appliedCode,
        assignedEmployeeIds: assignedEmployeeIds,
      );

      final results = await _repo.fetchAdsManagementProperties(
        excludeUserId: excludeUserId,
        from: from,
        to: from + 19,
        assignedToFilter: appliedEmployeeId,
        approvalStatusId: appliedStatusId,
        fromDate: appliedFromDate,
        toDate: appliedToDate,
        propertyCode: appliedCode,
        assignedEmployeeIds: assignedEmployeeIds,
      );

      List<PropertyModel> merged;
      if (isRefresh || from == 0) {
        merged = results;
      } else {
        merged = [...currentSuccess?.properties ?? [], ...results];
      }

      final isFiltering = appliedEmployeeId != null ||
          appliedStatusId != null ||
          appliedFromDate != null ||
          appliedToDate != null ||
          (appliedCode != null && appliedCode.isNotEmpty);

      // If not filtering, and isRefresh or page 0, cache it as originalProperties
      final originalList = (!isFiltering && (isRefresh || from == 0)) 
          ? results 
          : (currentSuccess?.originalProperties ?? const []);
          
      final origCount = (!isFiltering && (isRefresh || from == 0)) 
          ? count 
          : (currentSuccess?.originalTotalCount ?? 0);

      emit(MarketingSuccess(
        originalProperties: originalList,
        properties: merged,
        pendingProperties: currentSuccess?.pendingProperties ?? const [],
        isFiltered: isFiltering,
        hasNewUpdates: currentSuccess?.hasNewUpdates ?? false,
        totalCount: count,
        originalTotalCount: origCount,
        hasMore: results.length == _pageSize,
        page: from ~/ _pageSize,
        filterEmployeeId: appliedEmployeeId,
        filterApprovalStatusId: appliedStatusId,
        filterFromDate: appliedFromDate,
        filterToDate: appliedToDate,
        filterPropertyCode: appliedCode,
      ));
    } catch (e) {
      emit(MarketingError(e.toString()));
    }
  }

  Future<void> loadMore(String excludeUserId) async {
    if (state is! MarketingSuccess) return;
    final current = state as MarketingSuccess;
    if (!current.hasMore) return;
    await fetchProperties(excludeUserId: excludeUserId);
  }

  /// تحديث عقار واحد في القائمة بعد حفظ تعديل المنصات
  void patchProperty(PropertyModel updated) {
    if (state is! MarketingSuccess) return;
    final current = state as MarketingSuccess;
    final newList = current.properties.map((p) => p.id == updated.id ? updated : p).toList();
    emit(current.copyWith(properties: newList));
  }

  void clearFilters(String excludeUserId) {
    if (state is MarketingSuccess) {
      final current = state as MarketingSuccess;
      emit(current.copyWith(
        properties: current.originalProperties,
        totalCount: current.originalTotalCount,
        isFiltered: false,
        clearEmployeeFilter: true,
        clearStatusFilter: true,
        clearFromDate: true,
        clearToDate: true,
        clearCodeFilter: true,
      ));
    }
  }
}
