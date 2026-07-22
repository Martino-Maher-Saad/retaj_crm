import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/form_field_repository.dart';
import 'form_field_state.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;

class FormFieldCubit extends Cubit<FormFieldState> {
  final FormFieldRepository _repo;

  FormFieldCubit(this._repo) : super(FormFieldInitial());

  String _currentEntityType = 'lead';

  Future<void> fetchFields({String entityType = 'lead'}) async {
    _currentEntityType = entityType;
    try {
      emit(FormFieldLoading());
      final fields = await _repo.getFormFields(entityType);
      
      if (entityType == 'lead') {
        final dataManager = di.sl<StaticDataManager>();
        await dataManager.refreshFormFields();
      }
      
      emit(FormFieldLoaded(fields: fields, entityType: entityType));
    } catch (e) {
      emit(FormFieldError(e.toString()));
    }
  }

  Future<void> addField(Map<String, dynamic> data) async {
    try {
      emit(FormFieldActionLoading());
      await _repo.createFormField(data);
      emit(const FormFieldActionSuccess('تم إضافة الحقل بنجاح'));
      await fetchFields(entityType: _currentEntityType);
    } catch (e) {
      emit(FormFieldError(e.toString()));
      await fetchFields(entityType: _currentEntityType); // restore view
    }
  }

  Future<void> updateField(String id, Map<String, dynamic> data) async {
    try {
      emit(FormFieldActionLoading());
      await _repo.updateFormField(id, data);
      emit(const FormFieldActionSuccess('تم تعديل الحقل بنجاح'));
      await fetchFields(entityType: _currentEntityType);
    } catch (e) {
      emit(FormFieldError(e.toString()));
      await fetchFields(entityType: _currentEntityType);
    }
  }

  Future<void> deleteField(String id) async {
    try {
      emit(FormFieldActionLoading());
      await _repo.deleteFormField(id);
      emit(const FormFieldActionSuccess('تم حذف الحقل بنجاح'));
      await fetchFields(entityType: _currentEntityType);
    } catch (e) {
      emit(FormFieldError(e.toString()));
      await fetchFields(entityType: _currentEntityType);
    }
  }

  Future<void> reorderFields(List<Map<String, dynamic>> orderUpdates) async {
    try {
      emit(FormFieldActionLoading());
      await _repo.updateFieldsOrder(orderUpdates);
      await fetchFields(entityType: _currentEntityType);
    } catch (e) {
      emit(FormFieldError(e.toString()));
      await fetchFields(entityType: _currentEntityType);
    }
  }
}
