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
    if (!isClosed) {
      super.emit(state);
    }
  }

  // تخزين الفلاتر الحالية لكي نقوم باستخدامها في الـ pagination
  String? _currentPlatform;
  String? _currentLeadStatus;
  String? _currentPropertyType;
  String? _currentListingType;
  String? _currentGovernorate;
  String? _currentCity;
  DateTime? _currentFromDate;
  DateTime? _currentToDate;
  String? _currentFilterByEmployeeId;

  // 1. جلب البيانات (مع فلاتر)
  Future<void> getAllLeads({
    required String role,
    required String userId,
    bool isRefresh = false,
    String? filterByEmployeeId,
    String? platform,
    String? leadStatus,
    String? propertyType,
    String? listingType,
    String? governorate,
    String? city,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;

    if (isRefresh || currentState == null) {
      emit(LeadLoading());
    }

    // حفظ الفلاتر
    _currentFilterByEmployeeId = filterByEmployeeId;
    _currentPlatform = platform;
    _currentLeadStatus = leadStatus;
    _currentPropertyType = propertyType;
    _currentListingType = listingType;
    _currentGovernorate = governorate;
    _currentCity = city;
    _currentFromDate = fromDate;
    _currentToDate = toDate;

    try {
      final totalCount = await _repository.getLeadsCount(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        platform: platform,
        leadStatus: leadStatus,
        propertyType: propertyType,
        listingType: listingType,
        governorate: governorate,
        city: city,
        fromDate: fromDate,
        toDate: toDate,
      );
      final leads = await _repository.getAllLeads(
        role: role,
        userId: userId,
        from: 0,
        to: 24, // 25 elements per page as requested
        filterByEmployeeId: filterByEmployeeId,
        platform: platform,
        leadStatus: leadStatus,
        propertyType: propertyType,
        listingType: listingType,
        governorate: governorate,
        city: city,
        fromDate: fromDate,
        toDate: toDate,
      );

      final employees = (role == 'manager' || role == 'admin')
          ? await _repository.getAllEmployees()
          : <ProfileModel>[];

      emit(
        LeadLoaded(
          allLeads: leads,
          filteredLeads: leads, // لم نعد نستخدم الـ local filter، بل الفلتر بالسيرفر
          totalCount: totalCount,
          currentFilter: 'الكل',
          employees: employees.isNotEmpty ? employees : (currentState?.employees ?? []),
        ),
      );
    } catch (e, stackTrace) {
      print('=== ERROR IN LEADS CUBIT (getAllLeads) ===');
      print(e);
      print(stackTrace);
      print('==========================================');
      emit(LeadError(e.toString()));
    }
  }

  // جلب المزيد
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
          platform: _currentPlatform,
          leadStatus: _currentLeadStatus,
          propertyType: _currentPropertyType,
          listingType: _currentListingType,
          governorate: _currentGovernorate,
          city: _currentCity,
          fromDate: _currentFromDate,
          toDate: _currentToDate,
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

  // 3. إضافة عميل
  Future<void> addLead(LeadModel newLead) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final addedLead = await _repository.addNewLead(newLead);
        final updatedAll = [addedLead, ...currentState.allLeads];

        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
            totalCount: currentState.totalCount + 1,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  // 4. تحديث حالة
  Future<void> updateLeadStatus(String id, String newStatus) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.updateLeadData(id, {'lead_status': newStatus});

        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? updatedLead : l;
        }).toList();

        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> updateFullLead(LeadModel updatedLead) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final newLead = await _repository.updateLeadData(updatedLead.id!, updatedLead.toJson(isUpdate: true));

        final updatedAll = currentState.allLeads.map((l) {
          return l.id == updatedLead.id ? newLead : l;
        }).toList();

        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  // 5. إضافة تعليق
  Future<void> addComment(String id, String comment) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final updatedLead = await _repository.appendComment(id, comment);
        
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? updatedLead : l;
        }).toList();

        emit(
          currentState.copyWith(
            allLeads: updatedAll,
            filteredLeads: updatedAll,
          ),
        );
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  // 6. حذف عميل
  Future<void> deleteLead(String id, String role) async {
    if (role != 'manager' && role != 'admin') return; // حماية إضافية في الكيوبيت
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.deleteLeadById(id);
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
}
