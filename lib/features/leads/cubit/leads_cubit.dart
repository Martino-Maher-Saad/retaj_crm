import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import 'leads_state.dart';

class LeadCubit extends Cubit<LeadState> {
  final LeadRepository _repository;

  LeadCubit(this._repository) : super(LeadInitial());

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
      );

      final employees = (role == 'manager' || role == 'admin')
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
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? updatedLead : l;
        }).toList();
        emit(currentState.copyWith(allLeads: updatedAll, filteredLeads: updatedAll));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
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
