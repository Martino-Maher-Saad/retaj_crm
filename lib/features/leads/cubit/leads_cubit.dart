import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../../../core/utils/lead_sync_notifier.dart';
import 'leads_state.dart';

class LeadCubit extends Cubit<LeadState> {
  final LeadRepository _repository;
  final LeadSyncNotifier _sync;

  LeadCubit(this._repository, this._sync) : super(LeadInitial());

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
  String? _currentFilterByEmployeeId;
  bool? _currentIsArchived;
  bool? _currentIsStagnant;
  bool? _currentIsForTasks;

  // Public Getters for Filters
  String? get currentPlatformId => _currentPlatformId;
  String? get currentLeadStatusId => _currentLeadStatusId;
  String? get currentPropertyTypeId => _currentPropertyTypeId;
  String? get currentListingTypeId => _currentListingTypeId;
  int? get currentGovernorateId => _currentGovernorateId;
  int? get currentCityId => _currentCityId;
  DateTime? get currentFromDate => _currentFromDate;
  DateTime? get currentToDate => _currentToDate;
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
    bool? isArchived = false,
    bool? isStagnant,
    bool? isForTasks,
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;

    if (isRefresh || currentState == null) emit(LeadLoading());

    _currentFilterByEmployeeId = filterByEmployeeId;
    _currentPlatformId = platformId;
    _currentLeadStatusId = leadStatusId;
    _currentPropertyTypeId = propertyTypeId;
    _currentListingTypeId = listingTypeId;
    _currentGovernorateId = governorateId;
    _currentCityId = cityId;
    _currentFromDate = fromDate;
    _currentToDate = toDate;
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
        isArchived: isArchived,
        isStagnant: isStagnant,
        isForTasks: isForTasks,
      );

      final employees = (role == 'manager' || role == 'admin' || role == 'ceo')
          ? await _repository.getAllEmployees()
          : <ProfileModel>[];

      emit(LeadLoaded(
        allLeads: leads,
        filteredLeads: leads,
        totalCount: totalCount,
        currentFilter: 'الكل',
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

        final updatedAll = [...currentState.allLeads, ...nextLeads];

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
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
        final updatedAll = [addedLead, ...currentState.allLeads];
        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
          totalCount: currentState.totalCount + 1,
        ));
      } catch (e) {
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
        final updatedLead = await _repository.updateLeadStatus(id, statusId);
        final index = currentState.allLeads.indexWhere((l) => l.id == id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;
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

  Future<void> updateLeadStatusAndEmployee(String id, String statusId, String employeeId) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.updateLeadStatusAndEmployee(id, statusId, employeeId);
        final index = currentState.allLeads.indexWhere((l) => l.id == id);
        if (index != -1) {
          final updatedList = List<LeadModel>.from(currentState.allLeads);
          updatedList[index] = updatedLead;
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

      try {
        final newLead = await _repository.updateLeadData(
          updatedLead.id!,
          updatedLead,
          phones,
          newNote: newNote,
        );
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == updatedLead.id ? newLead : l;
        }).toList();
        emit(currentState.copyWith(allLeads: updatedAll, filteredLeads: updatedAll));
        _sync.notifyUpdated(newLead);
        _sync.notifyUpdated(newLead);
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
        emit(currentState.copyWith(allLeads: updatedAll, filteredLeads: updatedAll));
        _sync.notifyUpdated(updatedLead);
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> deleteLead(String id, String role) async {
    if (role != 'manager' && role != 'admin') return;
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.deleteLeadById(id);
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
        old.governorateId != updated.governorateId ||
        old.propertyCode != updated.propertyCode ||
        old.descLeadNeed != updated.descLeadNeed ||
        old.assignedTo != updated.assignedTo;
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
