import '../models/form_field_model.dart';
import '../services/form_field_service.dart';

class FormFieldRepository {
  final FormFieldService _service;

  FormFieldRepository(this._service);

  Future<List<FormFieldModel>> getFormFields(String entityType) =>
      _service.getFormFields(entityType);

  Future<FormFieldModel> createFormField(Map<String, dynamic> data) =>
      _service.createFormField(data);

  Future<FormFieldModel> updateFormField(String id, Map<String, dynamic> data) =>
      _service.updateFormField(id, data);

  Future<void> deleteFormField(String id) => _service.deleteFormField(id);

  Future<void> updateFieldsOrder(List<Map<String, dynamic>> orderUpdates) =>
      _service.updateFieldsOrder(orderUpdates);
}
