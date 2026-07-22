import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exceptions.dart';
import '../models/form_field_model.dart';

class FormFieldService {
  final SupabaseClient _supabase;

  FormFieldService(this._supabase);

  Future<List<FormFieldModel>> getFormFields(String entityType) async {
    try {
      final response = await _supabase
          .from('form_field_definitions')
          .select()
          .eq('entity_type', entityType)
          .order('field_order', ascending: true);

      return (response as List).map((e) => FormFieldModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('فشل جلب الحقول: $e');
    }
  }

  Future<FormFieldModel> createFormField(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('form_field_definitions')
          .insert(data)
          .select()
          .single();

      return FormFieldModel.fromJson(response);
    } catch (e) {
      throw ServerException('فشل إضافة الحقل: $e');
    }
  }

  Future<FormFieldModel> updateFormField(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _supabase
          .from('form_field_definitions')
          .update(data)
          .eq('id', id)
          .select()
          .single();

      return FormFieldModel.fromJson(response);
    } catch (e) {
      throw ServerException('فشل تحديث الحقل: $e');
    }
  }

  Future<void> deleteFormField(String id) async {
    try {
      await _supabase.from('form_field_definitions').delete().eq('id', id);
    } catch (e) {
      throw ServerException('فشل حذف الحقل: $e');
    }
  }

  Future<void> updateFieldsOrder(
    List<Map<String, dynamic>> orderUpdates,
  ) async {
    try {
      for (var update in orderUpdates) {
        await _supabase
            .from('form_field_definitions')
            .update({'field_order': update['field_order']})
            .eq('id', update['id']);
      }
    } catch (e) {
      throw ServerException('فشل تحديث ترتيب الحقول: $e');
    }
  }
}
