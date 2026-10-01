import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../../../data/services/dropdown_service.dart';
import '../../../core/utils/lead_sync_notifier.dart';
import '../../../data/services/realtime_service.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:async';
import 'leads_state.dart';

class LeadCubit extends Cubit<LeadState> {
  final LeadRepository _repository;
  final LeadSyncNotifier _sync;
  final RealtimeService _realtimeService;
  late final StreamSubscription _realtimeSubscription;

  LeadCubit(this._repository, this._sync, this._realtimeService) : super(LeadInitial()) {
    _realtimeSubscription = _realtimeService.eventStream.listen(_handleRealtimeEvent);
  }

  bool _isManagerOrAdmin() {
    if (_currentUserRole == null) return false;
    final r = _currentUserRole!.toLowerCase();
    return r == 'manager' || r == 'admin' || r == 'ceo';
  }

  int _originalTotalCount = 0;

  void cancelFilters() {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null) return;
    
    _currentFilterByEmployeeId = null;
    _currentPlatformId = null;
    _currentLeadStatusId = null;
    _currentPropertyTypeId = null;
    _currentListingTypeId = null;
    _currentGovernorateId = null;
    _currentCityId = null;
    _currentFromDate = null;
    _currentToDate = null;
    _currentLastCommentFromDate = null;
    _currentLastCommentToDate = null;
    _currentIsArchived = false;
    _currentIsStagnant = false;
    _currentIsForTasks = false;

    emit(currentState.copyWith(
      filteredLeads: currentState.allLeads,
      totalCount: _originalTotalCount,
    ));
  }

  final Set<String> _myRecentActions = {};
  
  void _markActionByMe(String id) {
    _myRecentActions.add(id);
    Future.delayed(const Duration(seconds: 10), () {
      _myRecentActions.remove(id);
    });
  }

  void _handleRealtimeEvent(event) async {
    if (event.entity != 'lead') return;
    
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null) return;

    if (event.action == 'insert') {
      try {
        bool canView = true;
        if (!_isManagerOrAdmin()) {
          if (event.assignedTo != _currentUserId) canView = false;
        } else {
          if (_currentFilterByEmployeeId != null && event.assignedTo != _currentFilterByEmployeeId) canView = false;
        }

        if (!canView) return;

        if (!canView) return;

        final newLead = await _repository.getLeadById(event.id);
        
        if (isClosed) return;
        final freshState = state is LeadLoaded ? state as LeadLoaded : null;
        if (freshState == null) return;

        if (freshState.allLeads.any((l) => l.id == event.id) ||
            freshState.pendingLeads.any((l) => l.id == event.id)) {
          return; // Ignore local echo if already processed
        }

        bool matchesFilters = true;
        if (_currentPlatformId != null && newLead.platformId != _currentPlatformId) matchesFilters = false;
        if (_currentLeadStatusId != null && newLead.statusId != _currentLeadStatusId) matchesFilters = false;
        if (_currentPropertyTypeId != null && newLead.propertyTypeId != _currentPropertyTypeId) matchesFilters = false;
        if (_currentListingTypeId != null && newLead.listingTypeId != _currentListingTypeId) matchesFilters = false;
        if (_currentCityId != null && newLead.cityId != _currentCityId) matchesFilters = false;

        if (!matchesFilters) return;

        final isMine = _myRecentActions.contains(event.id);

        if (isMine) {
            final newAll = List<LeadModel>.from(freshState.allLeads)..insert(0, newLead);
            final newFiltered = filterLeadsByQuickFilter(newAll, _activeQuickFilter);
            final newPending = freshState.pendingLeads.where((l) => l.id != event.id).toList();
            emit(freshState.copyWith(
              allLeads: newAll, 
              filteredLeads: newFiltered, 
              currentFilter: _activeQuickFilter,
              pendingLeads: newPending,
              totalCount: freshState.totalCount + 1,
            ));
        } else {
            final newPending = List<LeadModel>.from(freshState.pendingLeads)..insert(0, newLead);
            emit(freshState.copyWith(hasNewUpdates: true, pendingLeads: newPending));
        }
      } catch (e) {
        // Ignore silently, don't show banner if fetch fails
      }
    } else if (event.action == 'update' || event.action == 'transfer') {
      try {
        final updatedLead = await _repository.getLeadById(event.id);
        
        if (isClosed) return;
        final freshState = state is LeadLoaded ? state as LeadLoaded : null;
        if (freshState == null) return;
        
        bool canView = true;
        if (!_isManagerOrAdmin()) {
          if (updatedLead.assignedTo != _currentUserId) canView = false;
        } else {
          if (_currentFilterByEmployeeId != null && updatedLead.assignedTo != _currentFilterByEmployeeId) canView = false;
        }

        // Find index and update
        final newAll = List<LeadModel>.from(freshState.allLeads);
        final indexAll = newAll.indexWhere((l) => l.id == event.id);
        
        final indexPending = freshState.pendingLeads.indexWhere((l) => l.id == event.id);

        if (indexAll == -1) {
          if (!canView) {
             if (indexPending != -1) {
                final newPending = List<LeadModel>.from(freshState.pendingLeads)..removeAt(indexPending);
                emit(freshState.copyWith(pendingLeads: newPending));
             }
             return; 
          }
          
          bool matchesFilters = true;
          if (_currentPlatformId != null && updatedLead.platformId != _currentPlatformId) matchesFilters = false;
          if (_currentLeadStatusId != null && updatedLead.statusId != _currentLeadStatusId) matchesFilters = false;
          if (_currentPropertyTypeId != null && updatedLead.propertyTypeId != _currentPropertyTypeId) matchesFilters = false;
          if (_currentListingTypeId != null && updatedLead.listingTypeId != _currentListingTypeId) matchesFilters = false;
          if (_currentCityId != null && updatedLead.cityId != _currentCityId) matchesFilters = false;

          if (!matchesFilters) return;

          final isMine = _myRecentActions.contains(event.id);

          if (isMine) {
             final newAll = List<LeadModel>.from(freshState.allLeads)..insert(0, updatedLead);
             final newFiltered = filterLeadsByQuickFilter(newAll, _activeQuickFilter);
             final newPending = freshState.pendingLeads.where((l) => l.id != event.id).toList();
             emit(freshState.copyWith(
               allLeads: newAll, 
               filteredLeads: newFiltered, 
               currentFilter: _activeQuickFilter,
               pendingLeads: newPending,
               totalCount: freshState.totalCount + 1,
             ));
          } else {
             final newPending = List<LeadModel>.from(freshState.pendingLeads);
             if (!newPending.any((l) => l.id == event.id)) {
                 newPending.insert(0, updatedLead);
             }
             emit(freshState.copyWith(hasNewUpdates: true, pendingLeads: newPending));
          }
          return;
        }

        bool lostOwnership = !canView;

        if (indexAll != -1) newAll[indexAll] = updatedLead;
        final newFiltered = filterLeadsByQuickFilter(newAll, _activeQuickFilter);

        final newPending = List<LeadModel>.from(freshState.pendingLeads);
        if (indexPending != -1) newPending[indexPending] = updatedLead;

        emit(freshState.copyWith(
          allLeads: newAll,
          filteredLeads: newFiltered,
          currentFilter: _activeQuickFilter,
          pendingLeads: newPending,
          blinkItemId: event.id,
        ));
        
        if (lostOwnership) {
          // Blink and remove
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!isClosed) {
              final st = state is LeadLoaded ? state as LeadLoaded : null;
              if (st != null) {
                final all = st.allLeads.where((l) => l.id != event.id).toList();
                final filtered = st.filteredLeads.where((l) => l.id != event.id).toList();
                emit(st.copyWith(allLeads: all, filteredLeads: filtered, blinkItemId: null, totalCount: st.totalCount - 1));
              }
            }
          });
        } else {
          // Just reset blink
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (!isClosed) {
              final st = state is LeadLoaded ? state as LeadLoaded : null;
              if (st != null && st.blinkItemId == event.id) {
                emit(st.copyWith(blinkItemId: null));
              }
            }
          });
        }
      } catch (e) {
        // If it fails (e.g. RLS blocks them because they lost ownership), blink and remove it!
        if (event.action == 'transfer' || event.action == 'update') {
           final st = state is LeadLoaded ? state as LeadLoaded : null;
           if (st != null) {
              emit(st.copyWith(blinkItemId: event.id));
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (!isClosed) {
                  final st = state is LeadLoaded ? state as LeadLoaded : null;
                  if (st != null) {
                    final all = st.allLeads.where((l) => l.id != event.id).toList();
                    final filtered = st.filteredLeads.where((l) => l.id != event.id).toList();
                    emit(st.copyWith(allLeads: all, filteredLeads: filtered, blinkItemId: null, totalCount: st.totalCount - 1));
                  }
                }
              });
           }
        }
      }
    } else if (event.action == 'delete') {
      // Blink and remove
      final st = state is LeadLoaded ? state as LeadLoaded : null;
      if (st != null) {
        emit(st.copyWith(blinkItemId: event.id));
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!isClosed) {
            final st = state is LeadLoaded ? state as LeadLoaded : null;
            if (st != null) {
              final newAll = st.allLeads.where((l) => l.id != event.id).toList();
              final newFiltered = st.filteredLeads.where((l) => l.id != event.id).toList();
              emit(st.copyWith(allLeads: newAll, filteredLeads: newFiltered, blinkItemId: null, totalCount: st.totalCount - 1));
            }
          }
        });
      }
    } else if (event.action == 'bulk_transfer') {
      emit(currentState.copyWith(hasNewUpdates: true));
    }
  }

  void applyPendingUpdates() {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null || currentState.pendingLeads.isEmpty) return;

    final newAll = [...currentState.pendingLeads, ...currentState.allLeads];
    final newFiltered = [...currentState.pendingLeads, ...currentState.filteredLeads];
    
    emit(currentState.copyWith(
      allLeads: newAll,
      filteredLeads: newFiltered,
      pendingLeads: [],
      hasNewUpdates: false,
      blinkItemId: currentState.pendingLeads.first.id,
      totalCount: currentState.totalCount + currentState.pendingLeads.length,
    ));

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!isClosed) {
        final st = state is LeadLoaded ? state as LeadLoaded : null;
        if (st != null && st.blinkItemId == currentState.pendingLeads.first.id) {
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

  @override
  void emit(LeadState state) {
    if (!isClosed) super.emit(state);
  }

  // تخزين الفلاتر الحالية بالـ IDs للـ pagination
  String? _currentPlatformId;
  String? _currentLeadStatusId;
  String? _currentPropertyTypeId;
  String? _currentListingTypeId;
  int? _currentGovernorateId;
  int? _currentCityId;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  DateTime? _currentLastCommentFromDate;
  DateTime? _currentLastCommentToDate;
  String? _currentFilterByEmployeeId;
  bool? _currentIsArchived;
  bool? _currentIsStagnant;
  bool? _currentIsForTasks;
  String? _currentUserId;
  String? _currentUserRole;

  // Public Getters for Filters
  String? get currentPlatformId => _currentPlatformId;
  String? get currentLeadStatusId => _currentLeadStatusId;
  String? get currentPropertyTypeId => _currentPropertyTypeId;
  String? get currentListingTypeId => _currentListingTypeId;
  int? get currentGovernorateId => _currentGovernorateId;
  int? get currentCityId => _currentCityId;
  DateTime? get currentFromDate => _currentFromDate;
  DateTime? get currentToDate => _currentToDate;
  DateTime? get currentLastCommentFromDate => _currentLastCommentFromDate;
  DateTime? get currentLastCommentToDate => _currentLastCommentToDate;
  String? get currentFilterByEmployeeId => _currentFilterByEmployeeId;
  bool? get currentIsArchived => _currentIsArchived;
  bool? get currentIsStagnant => _currentIsStagnant;
  bool? get currentIsForTasks => _currentIsForTasks;

  Future<void> getAllLeads({
    required String role,
    required String userId,
    bool isRefresh = false,
    String? filterByEmployeeId,
    String? platformId,
    String? leadStatusId,
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? lastCommentFromDate,
    DateTime? lastCommentToDate,
    bool? isArchived = false,
    bool? isStagnant,
    bool? isForTasks,
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;

    if (isRefresh || currentState == null) emit(LeadLoading());

    _currentUserId = userId;
    _currentUserRole = role;
    _currentFilterByEmployeeId = filterByEmployeeId;
    _currentPlatformId = platformId;
    _currentLeadStatusId = leadStatusId;
    _currentPropertyTypeId = propertyTypeId;
    _currentListingTypeId = listingTypeId;
    _currentGovernorateId = governorateId;
    _currentCityId = cityId;
    _currentFromDate = fromDate;
    _currentToDate = toDate;
    _currentLastCommentFromDate = lastCommentFromDate;
    _currentLastCommentToDate = lastCommentToDate;
    _currentIsArchived = isArchived;
    _currentIsStagnant = isStagnant;
    _currentIsForTasks = isForTasks;

    try {
      final totalCount = await _repository.getLeadsCount(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        platformId: platformId,
        leadStatusId: leadStatusId,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        governorateId: governorateId,
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
        lastCommentFromDate: lastCommentFromDate,
        lastCommentToDate: lastCommentToDate,
        isArchived: isArchived,
        isStagnant: isStagnant,
        isForTasks: isForTasks,
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
        governorateId: governorateId,
        cityId: cityId,
        fromDate: fromDate,
        toDate: toDate,
        lastCommentFromDate: lastCommentFromDate,
        lastCommentToDate: lastCommentToDate,
        isArchived: isArchived,
        isStagnant: isStagnant,
        isForTasks: isForTasks,
      );

      final employees = (role == 'manager' || role == 'admin' || role == 'ceo')
          ? await _repository.getAllEmployees()
          : <ProfileModel>[];

      final hasFilters = filterByEmployeeId != null || platformId != null || leadStatusId != null || propertyTypeId != null || listingTypeId != null || governorateId != null || cityId != null || fromDate != null || toDate != null || lastCommentFromDate != null || lastCommentToDate != null || isArchived == true || isStagnant == true || isForTasks == true;

      if (!hasFilters) {
        _originalTotalCount = totalCount;
      }

      final allList = (hasFilters && currentState != null) ? currentState.allLeads : leads;
      final filteredList = filterLeadsByQuickFilter(leads, _activeQuickFilter);

      emit(LeadLoaded(
        allLeads: allList,
        filteredLeads: filteredList,
        totalCount: totalCount,
        currentFilter: _activeQuickFilter,
        employees: employees.isNotEmpty ? employees : (currentState?.employees ?? []),
      ));
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  Future<void> loadSingleLeadAndEmployees(LeadModel lead, String role) async {
    emit(LeadLoading());
    try {
      final employees = (role == 'manager' || role == 'admin' || role == 'ceo')
          ? await _repository.getAllEmployees()
          : <ProfileModel>[];

      emit(LeadLoaded(
        allLeads: [lead],
        filteredLeads: [lead],
        totalCount: 1,
        currentFilter: 'الكل',
        employees: employees,
      ));
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  Future<List<LeadModel>> fetchAllForExport({
    required String role,
    required String userId,
  }) async {
    try {
      return await _repository.getAllLeads(
        role: role,
        userId: userId,
        filterByEmployeeId: _currentFilterByEmployeeId,
        platformId: _currentPlatformId,
        leadStatusId: _currentLeadStatusId,
        propertyTypeId: _currentPropertyTypeId,
        listingTypeId: _currentListingTypeId,
        governorateId: _currentGovernorateId,
        cityId: _currentCityId,
        fromDate: _currentFromDate,
        toDate: _currentToDate,
        lastCommentFromDate: _currentLastCommentFromDate,
        lastCommentToDate: _currentLastCommentToDate,
        isArchived: _currentIsArchived,
        isStagnant: _currentIsStagnant,
        isForTasks: _currentIsForTasks,
        from: 0,
        to: 50000,
      );
    } catch (e) {
      print('Export fetch error: $e');
      return [];
    }
  }

  Future<void> search(String query, {required String role, required String userId, String type = 'phone'}) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null) return;
    
    if (query.isEmpty) { clearSearch(); return; }
    
    emit(LeadLoading());
    try {
      final results = await _repository.searchLeads(query, type: type, role: role, userId: userId);
      
      emit(currentState.copyWith(
        filteredLeads: results,
        isSearching: true,
      ));
    } catch (e) {
      emit(LeadError(e.toString()));
      emit(currentState);
    }
  }

  void clearSearch() {
    if (state is LeadLoaded) {
      final current = state as LeadLoaded;
      emit(current.copyWith(filteredLeads: current.allLeads, isSearching: false));
    }
  }

  Future<void> smartSearch(
    String query, {
    String? propertyTypeId,
    String? listingTypeId,
    int? governorateId,
    int? cityId,
    required String role,
    required String userId,
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    if (currentState == null) return;

    if (query.isEmpty) { clearSearch(); return; }
    
    emit(LeadLoading());
    try {
      final useFilters = currentState.currentFilter != 'الكل';
      final results = await _repository.searchLeadsWithAi(
        query: query,
        propertyTypeId: propertyTypeId ?? (useFilters ? _currentPropertyTypeId : null),
        listingTypeId: listingTypeId ?? (useFilters ? _currentListingTypeId : null),
        governorateId: governorateId ?? (useFilters ? _currentGovernorateId : null),
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
          currentState.allLeads.length >= currentState.totalCount) return;

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
          governorateId: _currentGovernorateId,
          cityId: _currentCityId,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
          isArchived: _currentIsArchived,
          isStagnant: _currentIsStagnant,
          isForTasks: _currentIsForTasks,
        );
        final hasFilters = _currentFilterByEmployeeId != null || _currentPlatformId != null || _currentLeadStatusId != null || _currentPropertyTypeId != null || _currentListingTypeId != null || _currentGovernorateId != null || _currentCityId != null || _currentFromDate != null || _currentToDate != null || _currentLastCommentFromDate != null || _currentLastCommentToDate != null || _currentIsArchived == true || _currentIsStagnant == true || _currentIsForTasks == true;

        final updatedAll = [...currentState.allLeads, ...nextLeads];
        final updatedFiltered = filterLeadsByQuickFilter(updatedAll, _activeQuickFilter);

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedFiltered,
          isLoadingMore: false,
        ));
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

        final addedLead = await _repository.addNewLead(newLead, phones, notes: notes);
        _markActionByMe(addedLead.id!);
        
        final freshState = state is LeadLoaded ? state as LeadLoaded : null;
        if (freshState != null) {
          if (freshState.allLeads.any((l) => l.id == addedLead.id)) return;
          final updatedAll = [addedLead, ...freshState.allLeads];
          final updatedFiltered = filterLeadsByQuickFilter(updatedAll, _activeQuickFilter);
          emit(freshState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedFiltered,
            currentFilter: _activeQuickFilter,
            totalCount: freshState.totalCount + 1,
          ));
        }
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  /// تحديث حالة العميل فقط
  Future<void> updateLeadStatus(String id, String statusId) async {
    _markActionByMe(id);
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.updateLeadStatus(id, statusId);
        final index = currentState.allLeads.indexWhere((l) => l.id == id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;
          final updatedFiltered = filterLeadsByQuickFilter(updatedList, _activeQuickFilter);
          emit(currentState.copyWith(
            allLeads: updatedList,
            filteredLeads: updatedFiltered,
            currentFilter: _activeQuickFilter,
          ));
          _sync.notifyUpdated(updatedLead);
        }
      } catch (e) {
        emit(LeadError(e.toString()));
      }
    }
  }

  Future<void> updateLeadStatusAndEmployee(String id, String statusId, String employeeId) async {
    _markActionByMe(id);
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.updateLeadStatusAndEmployee(id, statusId, employeeId);
        final index = currentState.allLeads.indexWhere((l) => l.id == id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;
          final updatedFiltered = filterLeadsByQuickFilter(updatedList, _activeQuickFilter);
          emit(currentState.copyWith(
            allLeads: updatedList,
            filteredLeads: updatedFiltered,
            currentFilter: _activeQuickFilter,
          ));
          _sync.notifyUpdated(updatedLead);
        }
      } catch (e) {
        emit(LeadError(e.toString()));
      }
    }
  }

  /// استعادة عميل من الأرشيف — يُزيله فوراً من قائمة الأرشيف

  Future<void> restoreLeadFromArchive(String id, String statusId, {String? employeeId}) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final LeadModel updatedLead;
        if (employeeId != null) {
          updatedLead = await _repository.updateLeadStatusAndEmployee(id, statusId, employeeId);
        } else {
          updatedLead = await _repository.updateLeadStatus(id, statusId);
        }
        // يُزيل العميل من قائمة الأرشيف فوراً لأنه لم يعد ينتمي إليها
        final updatedList = currentState.allLeads.where((l) => l.id != id).toList();
        emit(currentState.copyWith(
          allLeads: updatedList,
          filteredLeads: updatedList,
          totalCount: currentState.totalCount > 0 ? currentState.totalCount - 1 : 0,
        ));
        _sync.notifyUpdated(updatedLead);
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
        final updatedLead = await _repository.togglePin(lead.id!, !lead.isPinned);
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

          emit(currentState.copyWith(
            allLeads: updatedList,
            filteredLeads: updatedList,
          ));
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

      final bool updateEmbeddings = currentLead.descLeadNeed != updatedLead.descLeadNeed;

      try {
        final newLead = await _repository.updateLeadData(
          updatedLead.id!,
          updatedLead,
          phones,
          newNote: newNote,
          updateEmbeddings: updateEmbeddings,
        );
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == updatedLead.id ? newLead : l;
        }).toList();
        final updatedFiltered = filterLeadsByQuickFilter(updatedAll, _activeQuickFilter);
        emit(currentState.copyWith(allLeads: updatedAll, filteredLeads: updatedFiltered));
        _sync.notifyUpdated(newLead);
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  String _activeQuickFilter = 'الكل';
  String get activeQuickFilter => _activeQuickFilter;

  List<LeadModel> filterLeadsByQuickFilter(List<LeadModel> list, String filter) {
    if (filter == 'الكل') return list;

    // لم يتم التواصل: يشمل أي عميل ليس له تعليق حتى لو حالته مهتم + أي عميل حالته لم يتم التواصل (بالـ id أو الاسم)
    if (filter == 'لم يتم التواصل' || filter == 'لم يتم التواصل معه' || filter == 'بدون تعليق') {
      return list.where((l) {
        final noComment = l.lastComment == null || l.lastComment!.trim().isEmpty;
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        final notContacted = statusId == AppConstants.leadStatusNoContact ||
            status == 'لم يتم اتلواصل معه' ||
            status == 'لم يتم التواصل معه' ||
            status == 'لم يتم التواصل' ||
            status == 'جديد' ||
            status.isEmpty;
        return noComment || notContacted;
      }).toList();
    }

    if (filter == 'تم التواصل' || filter == 'تم التواصل على الواتس' || filter == 'واتساب' || filter == 'اخري' || filter == 'أخرى') {
      return list.where((l) {
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        final comment = (l.lastComment ?? '').trim();
        return statusId == AppConstants.leadStatusContacted ||
            statusId == AppConstants.leadStatusOther ||
            status == 'تم التواصل' ||
            status.contains('واتس') ||
            status.contains('اخري') ||
            status.contains('أخرى') ||
            l.lastCommentId == AppConstants.leadStatusContacted ||
            l.lastCommentId == AppConstants.leadStatusOther ||
            comment.contains('واتس') ||
            l.lastWhatsappAt != null;
      }).toList();
    }

    if (filter == 'مهتم' || filter == 'عميل مهتم') {
      return list.where((l) {
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        return statusId == AppConstants.leadStatusInterested ||
            statusId == AppConstants.leadStatusInterestedClient ||
            status == 'عميل مهتم' ||
            status == 'مهتم' ||
            (status.contains('مهتم') && !status.contains('غير'));
      }).toList();
    }

    if (filter == 'غير مهتم') {
      return list.where((l) {
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        return statusId == AppConstants.leadStatusNotInterested ||
            status == 'غير مهتم';
      }).toList();
    }

    if (filter == 'لم يرد' || filter == 'لم يتم الرد') {
      return list.where((l) {
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        return statusId == AppConstants.leadStatusNoReply ||
            status == 'لم يرد' ||
            status == 'لم يتم الرد' ||
            status == 'لا يرد';
      }).toList();
    }

    if (filter == 'VIP' || filter == 'مهم') {
      return list.where((l) {
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        return statusId == AppConstants.leadStatusImportant ||
            status == 'مهم' ||
            status.toLowerCase() == 'vip';
      }).toList();
    }

    if (filter == 'بروكر' || filter == 'broker') {
      return list.where((l) {
        final statusId = (l.statusId ?? '').trim();
        final status = (l.leadStatus ?? '').trim();
        return statusId == AppConstants.leadStatusBroker ||
            status.contains('بروكر') ||
            status.toLowerCase().contains('broker');
      }).toList();
    }

    return list.where((l) => (l.leadStatus ?? '').trim() == filter || (l.statusId ?? '').trim() == filter).toList();
  }

  void applyQuickFilter(String filter) {
    if (state is! LeadLoaded) return;
    final currentState = state as LeadLoaded;
    _activeQuickFilter = filter;

    final filtered = filterLeadsByQuickFilter(currentState.allLeads, filter);
    emit(currentState.copyWith(
      filteredLeads: filtered,
      currentFilter: filter,
    ));
  }

  Future<List<LookupOptionModel>> getQuickComments() async {
    return await _repository.getQuickComments();
  }

  Future<void> addNote(String id, String noteText, {String? quickCommentId, String? newStatusId}) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.addNote(
          id,
          noteText,
          quickCommentId: quickCommentId,
          newStatusId: newStatusId,
        );
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? updatedLead : l;
        }).toList();

        // إعادة تطبيق الفلتر السريع النشط: إذا كان الفلتر "لم يتم التواصل"، سيختفي العميل من الشاشة فوراً
        final updatedFiltered = filterLeadsByQuickFilter(updatedAll, _activeQuickFilter);

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedFiltered,
          currentFilter: _activeQuickFilter,
        ));
        _sync.notifyUpdated(updatedLead);
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> deleteLead(String id, String role) async {
    if (role != 'manager' && role != 'admin' && role != 'ceo' && role != 'sales') return;
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.deleteLeadById(id);
        final updatedAll = currentState.allLeads.where((l) => l.id != id).toList();
        final updatedFiltered = filterLeadsByQuickFilter(updatedAll, _activeQuickFilter);
        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedFiltered,
          currentFilter: _activeQuickFilter,
          totalCount: currentState.totalCount - 1,
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> bulkDeleteLeads(List<String> ids) async {
    if (ids.isEmpty) return;
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.bulkDeleteLeads(ids);
        final idsSet = ids.toSet();
        final updatedAll = currentState.allLeads.where((l) => !idsSet.contains(l.id)).toList();
        final updatedFiltered = currentState.filteredLeads.where((l) => !idsSet.contains(l.id)).toList();
        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedFiltered,
          totalCount: (currentState.totalCount - ids.length).clamp(0, 999999999),
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
        rethrow;
      }
    }
  }

  Future<void> archiveLead(String id, bool isArchived) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.archiveLead(id, isArchived);
        // Remove from current list because its archive state changed
        final updatedAll = currentState.allLeads.where((l) => l.id != id).toList();
        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
          totalCount: currentState.totalCount - 1,
        ));
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
        old.assignedTo != updated.assignedTo ||
        old.budgetFrom != updated.budgetFrom ||
        old.budgetTo != updated.budgetTo ||
        old.exclusionReasonId != updated.exclusionReasonId ||
        old.isPinned != updated.isPinned;
  }

  bool _havePhonesChanged(
    List<LeadPhoneModel> oldPhones,
    List<LeadPhoneModel> newPhones,
  ) {
    if (oldPhones.length != newPhones.length) return true;
    final oldSet = oldPhones.map((p) => '${p.phoneNumber}:${p.isPrimary}').toSet();
    final newSet = newPhones.map((p) => '${p.phoneNumber}:${p.isPrimary}').toSet();
    return !oldSet.containsAll(newSet) || !newSet.containsAll(oldSet);
  }
}
