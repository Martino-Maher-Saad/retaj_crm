import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_roles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/lead_sync_notifier.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../../../data/services/realtime_sync_service.dart';
import 'leads_state.dart';

class LeadCubit extends Cubit<LeadState> {
  final LeadRepository _repository;
  final LeadSyncNotifier _sync;
  final RealtimeSyncService _realtime;

  Timer? _heartbeatTimer;

  // Logs are now eagerly loaded with leads, no need for separate cache.

  LeadCubit(this._repository, this._sync, this._realtime) : super(LeadInitial()) {
    _sync.addListener(_onSyncEvent);
    _realtime.events.listen(_handleRealtimeEvent);
    _startHeartbeatTimer();
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state is LeadLoaded) {
        // Just trigger a re-emit to update time-based UI (like delayed leads)
        // More complex logic can be added here to physically move leads between tabs if needed
        final currentState = state as LeadLoaded;
        emit(currentState.copyWith());
      }
    });
  }

  void _handleRealtimeEvent(RealtimePayload payload) {
    if (kDebugMode) {
      print('REALTIME_DEBUG_CUBIT: Handling event for ${payload.table}, type: ${payload.type}, IsLoaded: ${state is LeadLoaded}');
    }
    if (state is! LeadLoaded) return;
    final currentState = state as LeadLoaded;

    if (payload.table == 'leads') {
      if (payload.type == RealtimeOpType.update || payload.type == RealtimeOpType.insert) {
        final rawId = payload.newRecord['id']?.toString();
        if (rawId == null) return;

        final assignedTo = payload.newRecord['assigned_to']?.toString();
        final isMine = assignedTo == _realtimeUserId;
        final isManager = AppRole.fromString(_realtimeRole ?? '').isAtLeast(AppRole.manager);

        // هل العميل موجود حالياً في الكاش المحلي؟
        final existsInCache = currentState.allLeads.any((l) => l.id == rawId);
        final fetchLogs = payload.newRecord['fetch_logs'] as bool? ?? true;
        if (kDebugMode) print('REALTIME_DEBUG_LEADS: existsInCache=$existsInCache, fetchLogs=$fetchLogs');

        if (existsInCache) {
          // موجود → حدّثه وأضف وميض
          if (!isMine && !isManager) {
            if (kDebugMode) print('REALTIME_DEBUG_LEADS: Not mine and not manager, removing from lists.');
            // لم يعد مُسنداً لنا → احذفه من القوائم
            final allLeads = currentState.allLeads.where((l) => l.id != rawId).toList();
            final filteredLeads = currentState.filteredLeads.where((l) => l.id != rawId).toList();
            emit(currentState.copyWith(allLeads: allLeads, filteredLeads: filteredLeads, flashingIds: {}));
            return;
          }
          if (kDebugMode) print('REALTIME_DEBUG_LEADS: Fetching details for existing lead...');
          if (fetchLogs) {
            fetchLeadDetails(rawId).then((_) => _flashItem(rawId));
          } else {
            fetchLeadDetailsBasic(rawId).then((_) => _flashItem(rawId));
          }
        } else {
          // مش موجود في الكاش
          if (isMine || isManager) {
            // مُسنَد لي أو أنا مدير → اجلبه وأضفه
            fetchLeadDetails(rawId).then((_) => _flashItem(rawId));
          }
          // موظف عادي وليس مُسنداً له → تجاهل (لا داعي لطلب DB)
        }
      } else if (payload.type == RealtimeOpType.delete) {
        final deletedId = payload.oldRecord['id']?.toString();
        if (deletedId == null) return;
        final allLeads = currentState.allLeads.where((l) => l.id != deletedId).toList();
        final filteredLeads = currentState.filteredLeads.where((l) => l.id != deletedId).toList();
        emit(currentState.copyWith(allLeads: allLeads, filteredLeads: filteredLeads, flashingIds: {}));
        // Logs will automatically be refreshed if fetchLeadDetails is called again, no cache to invalidate.
      }
    } else if (payload.table == 'lead_logs') {
      if (payload.type == RealtimeOpType.insert) {
        final leadId = payload.newRecord['lead_id']?.toString();
        if (leadId != null) {
          final leadIndex = currentState.allLeads.indexWhere((l) => l.id == leadId);
          if (leadIndex != -1) {
            final lead = currentState.allLeads[leadIndex];
            final newLog = LeadLogEntryModel.fromJson(payload.newRecord);
            
            final updatedLead = lead.copyWith(
              logs: [newLog, ...lead.logs]
            );

            _updateLeadInList(updatedLead);
            _flashItem(leadId);
          }
        }
      }
    } else if (payload.table == 'lead_notes') {
      if (payload.type == RealtimeOpType.insert) {
        final leadId = payload.newRecord['lead_id']?.toString();
        if (leadId != null && currentState.allLeads.any((l) => l.id == leadId)) {
          fetchLeadDetails(leadId).then((_) => _flashItem(leadId));
        }
      }
    }
  }

  void _onSyncEvent() {
    if (state is! LeadLoaded) return;
    
    if (_sync.consumeRefresh()) {
      if (_realtimeUserId != null && _realtimeRole != null) {
        getAllLeads(
          role: _realtimeRole!,
          userId: _realtimeUserId!,
          isRefresh: true,
          filterByEmployeeId: _currentFilterByEmployeeId,
          platformId: _currentPlatformId,
          leadStatusId: _currentLeadStatusId,
          propertyTypeId: _currentPropertyTypeId,
          listingTypeId: _currentListingTypeId,
          cityId: _currentCityId,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          isTrash: _currentIsTrash,
          statusIds: _currentStatusIds,
          isTransferred: _currentIsTransferred,
          delayFilter: _currentDelayFilter,
        );
      }
    } else {
      final updatedLead = _sync.consumeUpdate();
      if (updatedLead != null) {
        _updateLeadInList(updatedLead);
      }
    }
  }

  void _updateLeadInList(LeadModel newLead) {
    if (state is! LeadLoaded) return;
    final currentState = state as LeadLoaded;
    final allLeads = List<LeadModel>.from(currentState.allLeads);
    final filteredLeads = List<LeadModel>.from(currentState.filteredLeads);
    
    final allIndex = allLeads.indexWhere((l) => l.id == newLead.id);
    if (allIndex != -1) allLeads[allIndex] = newLead;
    
    final filterIndex = filteredLeads.indexWhere((l) => l.id == newLead.id);
    if (filterIndex != -1) filteredLeads[filterIndex] = newLead;
    
    emit(currentState.copyWith(
      allLeads: allLeads,
      filteredLeads: filteredLeads,
    ));
  }

  bool _matchesFilters(LeadModel lead) {
    if (_currentFilterByEmployeeId != null && lead.assignedTo != _currentFilterByEmployeeId) return false;
    if (_currentPlatformId != null && lead.platformId != _currentPlatformId) return false;
    if (_currentLeadStatusId != null && lead.statusId != _currentLeadStatusId) return false;
    if (_currentPropertyTypeId != null && lead.propertyTypeId != _currentPropertyTypeId) return false;
    if (_currentListingTypeId != null && lead.listingTypeId != _currentListingTypeId) return false;
    if (_currentCityId != null && lead.cityId != _currentCityId.toString()) return false;
    
    // In DB, if isTrash is not true, it queries deleted_at IS NULL (meaning isArchived MUST be false)
    final expectedIsTrash = _currentIsTrash ?? false;
    if (lead.isArchived != expectedIsTrash) return false;

    if (_currentStatusIds != null && lead.statusId != null && !_currentStatusIds!.contains(lead.statusId)) return false;
    if (_currentIsTransferred == true && lead.transferredFrom == null) return false;
    if (_currentFromDate != null && lead.createdAt != null && lead.createdAt!.isBefore(_currentFromDate!)) return false;
    if (_currentToDate != null && lead.createdAt != null && lead.createdAt!.isAfter(_currentToDate!)) return false;
    
    // Delayed logic could be complex, for now assume delayed filter might not match purely in memory easily
    if (_currentDelayFilter == true) {
      if (lead.lastActionAt == null) return false;
      final days = DateTime.now().difference(lead.lastActionAt!).inDays;
      if (days < 2) return false; // assuming delay is 2 days
    }

    return true;
  }

  @override
  void emit(LeadState state) {
    if (!isClosed) super.emit(state);
  }

  /// يضيف وميضاً لحظياً على العنصر المحدَّث — يختفي بعد ثانية
  void _flashItem(String id) {
    if (state is! LeadLoaded) return;
    final st = state as LeadLoaded;
    emit(st.copyWith(flashingIds: {id}));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (state is LeadLoaded && !isClosed) {
        emit((state as LeadLoaded).copyWith(flashingIds: {}));
      }
    });
  }
  
  String? _realtimeUserId;
  String? _realtimeRole;

  @override
  Future<void> close() {
    _heartbeatTimer?.cancel();
    _sync.removeListener(_onSyncEvent);
    return super.close();
  }

  // تخزين الفلاتر الحالية بالـ IDs للـ pagination
  String? _currentPlatformId;
  String? _currentLeadStatusId;
  String? _currentPropertyTypeId;
  String? _currentListingTypeId;
  int? _currentCityId;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  String? _currentFilterByEmployeeId;
  bool? _currentIsTrash;
  List<String>? _currentStatusIds;
  bool? _currentIsTransferred;
  bool? _currentDelayFilter;

  // Public Getters for Filters
  String? get currentPlatformId => _currentPlatformId;
  String? get currentLeadStatusId => _currentLeadStatusId;
  String? get currentPropertyTypeId => _currentPropertyTypeId;
  String? get currentListingTypeId => _currentListingTypeId;
  int? get currentCityId => _currentCityId;
  DateTime? get currentFromDate => _currentFromDate;
  DateTime? get currentToDate => _currentToDate;
  String? get currentFilterByEmployeeId => _currentFilterByEmployeeId;
  bool? get currentIsTrash => _currentIsTrash;
  List<String>? get currentStatusIds => _currentStatusIds;
  bool? get currentIsTransferred => _currentIsTransferred;
  bool? get currentDelayFilter => _currentDelayFilter;

  // لحفظ حالة التبويب الأساسية (RAM Caching) قبل تطبيق الفلاتر المتقدمة
  LeadLoaded? _baseTabState;

  // لتمييز إن كانت هذه الدالة تم استدعاؤها من الفلتر المتقدم أم من تغيير التبويب
  bool _hasAdvancedFilters = false;
  bool get hasAdvancedFilters => _hasAdvancedFilters;

  Future<void> getAllLeads({
    required String role,
    required String userId,
    bool isRefresh = false,
    String? filterByEmployeeId,
    String? platformId,
    String? leadStatusId,
    String? propertyTypeId,
    String? listingTypeId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isTrash,
    List<String>? statusIds,
    bool? isTransferred,
    bool? delayFilter,
    bool? isDuplicate,
    bool isAdvancedFilter = false,
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;

    if (isRefresh || currentState == null) emit(LeadLoading());

    _hasAdvancedFilters = isAdvancedFilter;

    _currentFilterByEmployeeId = filterByEmployeeId;
    _currentPlatformId = platformId;
    _currentLeadStatusId = leadStatusId;
    _currentPropertyTypeId = propertyTypeId;
    _currentListingTypeId = listingTypeId;
    _currentCityId = cityId;
    _currentFromDate = fromDate;
    _currentToDate = toDate;
    _currentIsTrash = isTrash;
    _currentStatusIds = statusIds;
    _currentIsTransferred = isTransferred;
    _currentDelayFilter = delayFilter;
    
    _realtimeUserId = userId;
    _realtimeRole = role;

    try {
      final totalCount = await _repository.getLeadsCount(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        platformId: platformId,
        leadStatusId: leadStatusId,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
        isTrash: isTrash,
        statusIds: statusIds,
        isTransferred: isTransferred,
        delayFilter: delayFilter,
      );
      final leads = await _repository.getAllLeads(
        role: role,
        userId: userId,
        from: 0,
        to: 24,
        filterByEmployeeId: filterByEmployeeId,
        platformId: platformId,
        leadStatusId: leadStatusId,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
        isTrash: isTrash,
        statusIds: statusIds,
        isTransferred: isTransferred,
        delayFilter: delayFilter,
      );

      List<LeadModel> finalLeads = leads;
      if (isDuplicate == true) {
        final Map<String, List<LeadModel>> phoneGroups = {};
        for (var lead in finalLeads) {
          final phone = lead.primaryPhone;
          if (phone != null && phone.isNotEmpty) {
            phoneGroups.putIfAbsent(phone, () => []).add(lead);
          }
        }
        finalLeads = phoneGroups.values
            .where((group) => group.length > 1)
            .expand((group) => group)
            .toList();
      }

      final employees = AppRole.fromString(role).isAtLeast(AppRole.manager)
          ? await _repository.getAllEmployees()
          : <ProfileModel>[];

      final newState = LeadLoaded(
        allLeads: finalLeads,
        filteredLeads: finalLeads,
        totalCount: totalCount,
        currentFilter: 'الكل',
        employees: employees.isNotEmpty
            ? employees
            : (currentState?.employees ?? []),
      );

      // حفظ حالة التبويب الأساسية إذا لم يكن هذا فلتر متقدم
      if (!isAdvancedFilter || _baseTabState == null) {
        _baseTabState = newState;
      }

      emit(newState);
    } catch (e, stacktrace) {
      debugPrint('=== ERROR IN getAllLeads ===');
      debugPrint(e.toString());
      debugPrint(stacktrace.toString());
      emit(LeadError(e.toString()));
    }
  }

  Future<void> clearAdvancedFilters() async {
    if (_baseTabState != null) {
      _hasAdvancedFilters = false;
      _currentPlatformId = null;
      _currentLeadStatusId = null;
      _currentPropertyTypeId = null;
      _currentListingTypeId = null;
      _currentCityId = null;
      _currentFromDate = null;
      _currentToDate = null;
      // We do not clear employee filter if it was part of base state, but wait,
      // the base state has its own data, we just emit it.
      emit(_baseTabState!);
    }
  }

  Future<void> loadSingleLeadAndEmployees(LeadModel lead, String role) async {
    emit(LeadLoading());
    try {
      final employees = AppRole.fromString(role).isAtLeast(AppRole.manager)
          ? await _repository.getAllEmployees()
          : <ProfileModel>[];

      emit(
        LeadLoaded(
          allLeads: [lead],
          filteredLeads: [lead],
          totalCount: 1,
          currentFilter: 'الكل',
          employees: employees,
        ),
      );
    } catch (e, stacktrace) {
      debugPrint('=== ERROR IN loadSingleLeadAndEmployees ===');
      debugPrint(e.toString());
      debugPrint(stacktrace.toString());
      emit(LeadError(e.toString()));
    }
  }

  Future<void> search(
    String query, {
    required String role,
    required String userId,
    String type = 'phone',
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null) return;

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    emit(LeadLoading());
    try {
      final results = await _repository.searchLeads(
        query,
        type: type,
        role: role,
        userId: userId,
      );

      emit(currentState.copyWith(filteredLeads: results, isSearching: true));
    } catch (e) {
      emit(LeadError(e.toString()));
      emit(currentState);
    }
  }



  Future<void> transferLead({
    required String leadId,
    required String fromEmployeeId,
    required String toEmployeeId,
    required String changedBy,
    String? notes,
  }) async {
    try {
      await _repository.transferLead(
        leadId: leadId,
        fromEmployeeId: fromEmployeeId,
        toEmployeeId: toEmployeeId,
        changedBy: changedBy,
        notes: notes,
      );
      
      _realtime.broadcastLeadUpdated(leadId, toEmployeeId);
      
      await fetchLeadDetails(leadId);
    } catch (e) {
      emit(LeadError(e.toString()));
      rethrow;
    }
  }

  Future<void> addLeadAction({
    required String leadId,
    required String comment,
    required String nextStatusId,
    DateTime? scheduledAt,
    String? meetingTypeId,
    String? meetingPurposeId,
    String? meetingLocation,
    String? exclusionReasonId,
    String? propertyCode,
    double? companyProfit,
    required String role,
    required String userId,
  }) async {
    try {
      await _repository.addLeadAction(
        leadId: leadId,
        comment: comment,
        nextStatusId: nextStatusId,
        scheduledAt: scheduledAt,
        meetingTypeId: meetingTypeId,
        meetingPurposeId: meetingPurposeId,
        meetingLocation: meetingLocation,
        exclusionReasonId: exclusionReasonId,
        propertyCode: propertyCode,
        companyProfit: companyProfit,
      );
      
      // إرسال Broadcast للجميع ليتحدث السجل لحظياً دون العودة لقاعدة البيانات
      _realtime.broadcastLeadUpdated(leadId, ""); // Using broadcastLeadUpdated with fetch_logs: true instead of log_added

      await fetchLeadDetails(leadId);
    } catch (e) {
      print('====================================');
      print('ADD ACTION ERROR: $e');
      print('====================================');
      emit(LeadError(e.toString()));
      rethrow;
    }
  }

  Future<void> fetchLeadDetails(String leadId) async {
    if (state is LeadLoaded) {
      final st = state as LeadLoaded;
      try {
        final detailedLead = await _repository.getLeadById(leadId);
        
        // Handle allLeads
        bool existsInAll = st.allLeads.any((l) => l.id == leadId);
        List<LeadModel> updatedAllLeads;
        if (existsInAll) {
          updatedAllLeads = st.allLeads.map((l) => l.id == leadId ? detailedLead : l).toList();
        } else {
          updatedAllLeads = [detailedLead, ...st.allLeads];
        }

        // Handle filteredLeads
        bool existsInFiltered = st.filteredLeads.any((l) => l.id == leadId);
        List<LeadModel> updatedFilteredLeads;
        if (existsInFiltered) {
          if (_matchesFilters(detailedLead)) {
            updatedFilteredLeads = st.filteredLeads.map((l) => l.id == leadId ? detailedLead : l).toList();
          } else {
            updatedFilteredLeads = st.filteredLeads.where((l) => l.id != leadId).toList();
          }
        } else {
          if (_matchesFilters(detailedLead)) {
            updatedFilteredLeads = [detailedLead, ...st.filteredLeads];
          } else {
            updatedFilteredLeads = st.filteredLeads;
          }
        }

        emit(st.copyWith(allLeads: updatedAllLeads, filteredLeads: updatedFilteredLeads));
        } catch (e, st) {
          if (kDebugMode) {
            print('REALTIME_DEBUG_ERROR: Error fetching lead details: $e');
            print(st);
          }
        }
    }
  }

  Future<void> fetchLeadDetailsBasic(String leadId, {int retryCount = 0}) async {
    try {
      await Future.delayed(Duration(milliseconds: 200 + (retryCount * 500)));
      final detailedLead = await _repository.getLeadByIdBasic(leadId);
      
      if (state is! LeadLoaded) return;
      final st = state as LeadLoaded;

      // Merge logs from old lead!
      final oldLead = st.allLeads.firstWhere((l) => l.id == leadId, orElse: () => detailedLead);
      final mergedLead = detailedLead.copyWith(logs: oldLead.logs);
      
      bool existsInAll = st.allLeads.any((l) => l.id == leadId);
      List<LeadModel> updatedAllLeads;
      if (existsInAll) {
        updatedAllLeads = st.allLeads.map((l) => l.id == leadId ? mergedLead : l).toList();
      } else {
        updatedAllLeads = [mergedLead, ...st.allLeads];
      }

      bool existsInFiltered = st.filteredLeads.any((l) => l.id == leadId);
      List<LeadModel> updatedFilteredLeads;
      if (existsInFiltered) {
        if (_matchesFilters(mergedLead)) {
          updatedFilteredLeads = st.filteredLeads.map((l) => l.id == leadId ? mergedLead : l).toList();
        } else {
          updatedFilteredLeads = st.filteredLeads.where((l) => l.id != leadId).toList();
        }
      } else {
        if (_matchesFilters(mergedLead)) {
          updatedFilteredLeads = [mergedLead, ...st.filteredLeads];
        } else {
          updatedFilteredLeads = st.filteredLeads;
        }
      }

      emit(st.copyWith(allLeads: updatedAllLeads, filteredLeads: updatedFilteredLeads));
    } catch (e, stackTrace) {
      if (retryCount < 3) {
        if (kDebugMode) {
          print('REALTIME_DEBUG_ERROR: Lead (Basic) not found yet, retrying... ($retryCount) - $e');
        }
        await fetchLeadDetailsBasic(leadId, retryCount: retryCount + 1);
      } else {
        if (kDebugMode) {
          print('REALTIME_DEBUG_ERROR: Error fetching lead (Basic) details after retries: $e');
          print(stackTrace);
        }
      }
    }
  }

  void clearSearch() {
    if (state is LeadLoaded) {
      final current = state as LeadLoaded;
      emit(
        current.copyWith(filteredLeads: current.allLeads, isSearching: false),
      );
    }
  }

  Future<void> filterByQuickStatus(
    String? statusId, {
    required String role,
    required String userId,
  }) async {
    // Simply fetch all leads with the specific statusId, using our current filters if any
    await getAllLeads(
      role: role,
      userId: userId,
      leadStatusId: statusId,
      filterByEmployeeId: _currentFilterByEmployeeId,
      platformId: _currentPlatformId,
      propertyTypeId: _currentPropertyTypeId,
      listingTypeId: _currentListingTypeId,
      cityId: _currentCityId,
      fromDate: _currentFromDate,
      toDate: _currentToDate,
      isTrash: _currentIsTrash,
      isTransferred: _currentIsTransferred,
      delayFilter: _currentDelayFilter,
    );
  }

  Future<List<LeadModel>> exportFilteredLeads({
    required String role,
    required String userId,
  }) async {
    try {
      // نستخدم fetchDashboardExcelLeads لجلب كل العملاء بدون limit (Pagination) مع تطبيق جميع الفلاتر
      return await _repository.fetchDashboardExcelLeads(
        role: role,
        userId: userId,
        filterByEmployeeId: _currentFilterByEmployeeId,
        listingTypeId: _currentListingTypeId,
        propertyTypeId: _currentPropertyTypeId,
        cityId: _currentCityId,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
      );
    } catch (e) {
      debugPrint('Export Error: $e');
      throw 'حدث خطأ أثناء جلب البيانات للتصدير: $e';
    }
  }

  Future<void> smartSearch(
    String query, {
    String? propertyTypeId,
    String? listingTypeId,
    int? cityId,
    required String role,
    required String userId,
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null) return;

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    emit(LeadLoading());
    try {
      final useFilters = currentState.currentFilter != 'الكل';
      final results = await _repository.searchLeadsWithAi(
        query: query,
        propertyTypeId:
            propertyTypeId ?? (useFilters ? _currentPropertyTypeId : null),
        listingTypeId:
            listingTypeId ?? (useFilters ? _currentListingTypeId : null),
        cityId: cityId ?? (useFilters ? _currentCityId : null),
        role: role,
        userId: userId,
      );
      emit(currentState.copyWith(filteredLeads: results, isSearching: true));
    } catch (e) {
      emit(LeadError(e.toString()));
      emit(currentState);
    }
  }

  Future<List<LeadModel>> checkDuplicates(List<String> phones) async {
    try {
      return await _repository.checkDuplicateLeadPhones(phones);
    } catch (e) {
      return [];
    }
  }

  Future<void> loadMoreLeads({
    required String role,
    required String userId,
  }) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;

      if (currentState.isLoadingMore ||
          currentState.allLeads.length >= currentState.totalCount)
        return;

      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final nextLeads = await _repository.getAllLeads(
          role: role,
          userId: userId,
          from: currentState.allLeads.length,
          to: currentState.allLeads.length + 24,
          filterByEmployeeId: _currentFilterByEmployeeId,
          platformId: _currentPlatformId,
          leadStatusId: _currentLeadStatusId,
          propertyTypeId: _currentPropertyTypeId,
          listingTypeId: _currentListingTypeId,
          cityId: _currentCityId,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          isTrash: _currentIsTrash,
          statusIds: _currentStatusIds,
          isTransferred: _currentIsTransferred,
          delayFilter: _currentDelayFilter,
        );

        final updatedAll = [...currentState.allLeads, ...nextLeads];

        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
            isLoadingMore: false,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> addLead(
    LeadModel newLead,
    List<LeadPhoneModel> phones, {
    String? newNote,
  }) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final notes = (newNote != null && newNote.trim().isNotEmpty)
            ? [LeadNoteModel(noteText: newNote.trim())]
            : <LeadNoteModel>[];

        final addedLead = await _repository.addNewLead(
          newLead,
          phones,
          notes: notes,
        );
        
        _realtime.broadcastNewLead(addedLead.id!, addedLead.assignedTo);

        final updatedAll = [addedLead, ...currentState.allLeads];
        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
            totalCount: currentState.totalCount + 1,
          ),
        );
      } catch (e) {
        print('====================================');
        print('ADD LEAD ERROR: $e');
        print('====================================');
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  /// تحديث حالة العميل فقط
  Future<void> updateLeadStatus(String id, String statusId) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final excludedIds = di.sl<StaticDataManager>().getStatusIdsByBehavior(
          'exclusion',
        );
        final isExcluded = excludedIds.contains(statusId);
        final updatedLead = await _repository.updateLeadStatus(
          id,
          statusId,
          isExcluded: isExcluded,
        );
        final index = currentState.allLeads.indexWhere((l) => l.id == id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;
          emit(
            currentState.copyWith(
              allLeads: updatedList,
              filteredLeads: updatedList,
            ),
          );
          _sync.notifyUpdated(updatedLead);
        }
      } catch (e) {
        emit(LeadError(e.toString()));
      }
    }
  }

  Future<void> updateLeadStatusAndEmployee(
    String id,
    String statusId,
    String employeeId,
  ) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final excludedIds = di.sl<StaticDataManager>().getStatusIdsByBehavior(
          'exclusion',
        );
        final isExcluded = excludedIds.contains(statusId);
        final updatedLead = await _repository.updateLeadStatusAndEmployee(
          id,
          statusId,
          employeeId,
          isExcluded: isExcluded,
        );
        final index = currentState.allLeads.indexWhere((l) => l.id == id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;
          emit(
            currentState.copyWith(
              allLeads: updatedList,
              filteredLeads: updatedList,
            ),
          );
          _sync.notifyUpdated(updatedLead);
        }
      } catch (e) {
        emit(LeadError(e.toString()));
      }
    }
  }

  Future<void> restoreLeadFromArchive(String id) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.archiveLead(id, false);

        final lead = currentState.allLeads.firstWhere((l) => l.id == id);

        // إرسال Broadcast ليظهر عند الموظف أو يختفي من أرشيف الآخرين
        _realtime.broadcastLeadUpdated(id, lead.assignedTo ?? "");

        // يُزيل العميل من قائمة الأرشيف فوراً لأنه لم يعد ينتمي إليها
        final updatedList = currentState.allLeads
            .where((l) => l.id != id)
            .toList();
        emit(
          currentState.copyWith(
            allLeads: updatedList,
            filteredLeads: updatedList,
            totalCount: currentState.totalCount > 0
                ? currentState.totalCount - 1
                : 0,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> softDeleteLead(String id) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.archiveLead(id, true);

        final lead = currentState.allLeads.firstWhere((l) => l.id == id);

        // إرسال إشعار لحظي عبر Broadcast
        _realtime.broadcastLeadUpdated(id, lead.assignedTo ?? "");

        // يُزيل العميل من قائمة العملاء النشطين
        final updatedList = currentState.allLeads
            .where((l) => l.id != id)
            .toList();
        emit(
          currentState.copyWith(
            allLeads: updatedList,
            filteredLeads: updatedList,
            totalCount: currentState.totalCount > 0
                ? currentState.totalCount - 1
                : 0,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  /// حذف العميل نهائياً من الداتا بيز (Hard Delete)
  Future<void> hardDeleteLead(String id) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.deleteLeadById(id);

        // يُزيل العميل من واجهة المهملات
        final updatedList = currentState.allLeads
            .where((l) => l.id != id)
            .toList();
        emit(
          currentState.copyWith(
            allLeads: updatedList,
            filteredLeads: updatedList,
            totalCount: currentState.totalCount > 0
                ? currentState.totalCount - 1
                : 0,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> toggleLeadPin(LeadModel lead) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.togglePin(
          lead.id!,
          !lead.isPinned,
        );
        final index = currentState.allLeads.indexWhere((l) => l.id == lead.id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;

          // إعادة الترتيب حتى يظهر المثبت في الأعلى
          updatedList.sort((a, b) {
            if (a.isPinned && !b.isPinned) return -1;
            if (!a.isPinned && b.isPinned) return 1;
            // إذا كانا متساويين، نرتب بالأحدث
            final dateA = a.createdAt ?? DateTime.now();
            final dateB = b.createdAt ?? DateTime.now();
            return dateB.compareTo(dateA);
          });

          emit(
            currentState.copyWith(
              allLeads: updatedList,
              filteredLeads: updatedList,
            ),
          );
          _sync.notifyUpdated(updatedLead);
        }
      } catch (e) {
        emit(LeadError(e.toString()));
      }
    }
  }

  /// تحديث العميل كامل مع Smart Comparison — لو مفيش تغيير مبنبعتش للـ DB
  Future<void> updateFullLead(
    LeadModel updatedLead,
    List<LeadPhoneModel> phones, {
    String? newNote,
  }) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;

      // نجيب البيانات القديمة من الـ State
      final currentLead = currentState.allLeads.firstWhere(
        (l) => l.id == updatedLead.id,
        orElse: () => updatedLead,
      );

      final leadChanged = _hasLeadDataChanged(currentLead, updatedLead);
      final phonesChanged = _havePhonesChanged(currentLead.phones, phones);
      final hasNewNote = newNote != null && newNote.trim().isNotEmpty;

      // لو مفيش أي تغيير → مرجعش للـ DB خالص
      if (!leadChanged && !phonesChanged && !hasNewNote) return;

      try {
        final newLead = await _repository.updateLeadData(
          updatedLead.id!,
          updatedLead,
          phones,
          newNote: newNote,
        );
        
        // إرسال Broadcast للجميع ليتحدث الكاش لحظياً
        _realtime.broadcastLeadUpdated(newLead.id!, newLead.assignedTo);

        // We merge with OLD logs to prevent losing the cache
        final mergedLead = newLead.copyWith(logs: currentLead.logs);

        final updatedAll = currentState.allLeads.map((l) {
          return l.id == updatedLead.id ? mergedLead : l;
        }).toList();
        
        List<LeadModel> updatedFiltered = currentState.filteredLeads;
        if (currentState.filteredLeads.any((l) => l.id == mergedLead.id)) {
          updatedFiltered = currentState.filteredLeads.map((l) => l.id == mergedLead.id ? mergedLead : l).toList();
        }

        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedFiltered,
          ),
        );
        _sync.notifyUpdated(mergedLead);
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> addNote(String id, String noteText) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.addNote(id, noteText);
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? updatedLead : l;
        }).toList();
        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
          ),
        );
        _sync.notifyUpdated(updatedLead);
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> deleteLead(String id, String role) async {
    if (role != 'admin' && role != 'super_admin') return;
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.deleteLeadById(id);
        
        // إرسال Broadcast للحذف
        _realtime.broadcastLeadDeleted(id);

        final updatedAll = currentState.allLeads
            .where((l) => l.id != id)
            .toList();
        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
            totalCount: currentState.totalCount - 1,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> archiveLead(String id, bool isArchived) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.archiveLead(id, isArchived);
        
        // إرسال Broadcast ليختفي من عند الموظفين فوراً
        _realtime.broadcastLeadUpdated(id, "");

        // Remove from current list because its archive state changed
        final updatedAll = currentState.allLeads
            .where((l) => l.id != id)
            .toList();
        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
            totalCount: currentState.totalCount - 1,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  // ─── Helpers للمقارنة ───

  bool _hasLeadDataChanged(LeadModel old, LeadModel updated) {
    return old.clientName != updated.clientName ||
        old.statusId != updated.statusId ||
        old.platformId != updated.platformId ||
        old.propertyTypeId != updated.propertyTypeId ||
        old.listingTypeId != updated.listingTypeId ||
        old.channelId != updated.channelId ||
        old.cityId != updated.cityId ||
        old.propertyCode != updated.propertyCode ||
        old.descLeadNeed != updated.descLeadNeed ||
        old.assignedTo != updated.assignedTo;
  }

  bool _havePhonesChanged(
    List<LeadPhoneModel> oldPhones,
    List<LeadPhoneModel> newPhones,
  ) {
    if (oldPhones.length != newPhones.length) return true;
    final oldSet = oldPhones
        .map((p) => '${p.phoneNumber}:${p.isPrimary}')
        .toSet();
    final newSet = newPhones
        .map((p) => '${p.phoneNumber}:${p.isPrimary}')
        .toSet();
    return !oldSet.containsAll(newSet) || !newSet.containsAll(oldSet);
  }
}
