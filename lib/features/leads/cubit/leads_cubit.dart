import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/lead_model.dart';
import '../../../data/repositories/lead_repository.dart';
import 'leads_state.dart';


class LeadCubit extends Cubit<LeadState> {
  final LeadRepository _repository;

  LeadCubit(this._repository) : super(LeadInitial());

  // 1. جلب البيانات لأول مرة
  Future<void> getAllLeads() async {
    emit(LeadLoading());
    try {
      final leads = await _repository.getAllLeads();
      emit(LeadLoaded(allLeads: leads, filteredLeads: leads));
    } catch (e) {
      emit(LeadError(e.toString()));
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
        // الفلترة تتم بناءً على القيمة المخزنة في الـ database (Arabic)
        filtered = currentState.allLeads.where((l) => l.leadStatus == filter).toList();
      }

      emit(LeadLoaded(
        allLeads: currentState.allLeads,
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

        // جراحة القائمة: إضافة العميل الجديد في البداية
        final updatedAll = List<LeadModel>.from(currentState.allLeads)..insert(0, addedLead);

        emit(LeadLoaded(
          allLeads: updatedAll,
          filteredLeads: updatedAll, // نرجعه للكل مؤقتاً أو نطبق الفلتر الحالي
          currentFilter: 'الكل',
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        // نعيد حالة البيانات القديمة بعد إظهار الخطأ
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

        // جراحة القائمة: تحديث العنصر المطلوب فقط
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == id ? l.copyWith(leadStatus: newStatus) : l;
        }).toList();

        emit(LeadLoaded(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
          currentFilter: 'الكل',
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }


  // تحديث عميل (تحديث شامل لكل الحقول) - تم الإضافة
  Future<void> updateFullLead(LeadModel updatedLead) async {
    if (state is LeadLoaded) {
      final currentState = state as LeadLoaded;
      emit(LeadLoading()); // إظهار مؤشر التحميل
      try {
        // تحديث في السيرفر (نرسل الموديل كاملاً بعد تحويله لـ Map)
        await _repository.updateLeadData(updatedLead.id!, updatedLead.toJson());

        // تحديث القائمة المحلية (Local State Sync)
        final updatedAll = currentState.allLeads.map((l) {
          return l.id == updatedLead.id ? updatedLead : l;
        }).toList();

        emit(LeadLoaded(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
          currentFilter: 'الكل',
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState); // العودة للحالة السابقة عند الخطأ
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

        emit(LeadLoaded(
          allLeads: updatedAll,
          filteredLeads: updatedAll,
          currentFilter: 'الكل',
        ));
      } catch (e) {
        emit(LeadError(e.toString()));
        emit(currentState);
      }
    }
  }
}