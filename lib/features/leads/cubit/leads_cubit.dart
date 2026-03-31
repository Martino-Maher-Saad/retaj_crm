import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/lead_model.dart';
import '../../../data/repositories/lead_repository.dart';
import 'leads_state.dart';


class LeadCubit extends Cubit<LeadState> {
  final LeadRepository _repository;

  LeadCubit(this._repository) : super(LeadInitial());

  // 1. جلب البيانات مع دعم ترقيم الصفحات (Pagination)
  Future<void> getAllLeads({
    required String role, 
    required String userId, 
    bool isRefresh = false
  }) async {
    final currentState = state is LeadLoaded ? state as LeadLoaded : null;
    
    if (isRefresh) {
      emit(LeadLoading());
    }

    try {
      final totalCount = await _repository.getLeadsCount(role: role, userId: userId);
      final leads = await _repository.getAllLeads(
        role: role, 
        userId: userId, 
        from: 0, 
        to: 14,
      );

      emit(LeadLoaded(
        allLeads: leads,
        filteredLeads: leads,
        totalCount: totalCount,
        currentFilter: 'الكل',
      ));
    } catch (e) {
      emit(LeadError(e.toString()));
    }
  }

  // جلب المزيد من البيانات
  Future<void> loadMoreLeads({required String role, required String userId}) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      
      // توقف إذا كنا نحمل بالفعل أو وصلنا للنهاية
      if (currentState.isLoadingMore || currentState.allLeads.length >= currentState.totalCount) return;

      emit(currentState.copyWith(isLoadingMore: true));

      try {
        final nextLeads = await _repository.getAllLeads(
          role: role,
          userId: userId,
          from: currentState.allLeads.length,
          to: currentState.allLeads.length + 14,
        );

        final updatedAll = [...currentState.allLeads, ...nextLeads];
        
        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: currentState.currentFilter == 'الكل' 
              ? updatedAll 
              : updatedAll.where((l) => l.leadStatus == currentState.currentFilter).toList(),
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  // 2. الفلترة المحلية (Local Filtering) باللغة العربية
  void filterLeads(String filter) {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      List<LeadModel> filtered;

      if (filter == 'الكل') {
        filtered = currentState.allLeads;
      } else {
        filtered = currentState.allLeads.where((l) => l.leadStatus == filter).toList();
      }

      emit(currentState.copyWith(
        filteredLeads: filtered,
        currentFilter: filter,
      ));
    }
  }

  // 3. إضافة عميل (تحديث جراحي)
  Future<void> addLead(LeadModel newLead) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        final addedLead = await _repository.addNewLead(newLead);
        final updatedAll = [addedLead, ...currentState.allLeads];

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
          currentFilter: 'الكل',
          totalCount: currentState.totalCount + 1,
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  // 4. تحديث عميل (تغيير حالة)
  Future<void> updateLeadStatus(String id, String newStatus) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.updateLeadData(id, {'lead_status': newStatus});

        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? l.copyWith(leadStatus: newStatus) : l;
        }).toList();

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: currentState.currentFilter == 'الكل'
              ? updatedAll
              : updatedAll.where((l) => l.leadStatus == currentState.currentFilter).toList(),
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }


  // تحديث عميل (تحديث شامل لكل الحقول)
  Future<void> updateFullLead(LeadModel updatedLead) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.updateLeadData(updatedLead.id!, updatedLead.toJson());

        final updatedAll = currentState.allLeads.map((l) {
          return l.id == updatedLead.id ? updatedLead : l;
        }).toList();

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: currentState.currentFilter == 'الكل'
              ? updatedAll
              : updatedAll.where((l) => l.leadStatus == currentState.currentFilter).toList(),
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }

  // 5. حذف عميل
  Future<void> deleteLead(String id) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      try {
        await _repository.deleteLeadById(id);
        final updatedAll = currentState.allLeads.where((l) => l.id != id).toList();

        emit(currentState.copyWith(
          allLeads: updatedAll,
          filteredLeads: currentState.currentFilter == 'الكل'
              ? updatedAll
              : updatedAll.where((l) => l.leadStatus == currentState.currentFilter).toList(),
          totalCount: currentState.totalCount - 1,
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }
}