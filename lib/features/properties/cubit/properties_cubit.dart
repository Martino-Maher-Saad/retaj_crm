import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:retaj_crm/features/properties/cubit/properties_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertiesRepository _repository;
  PropertiesCubit(this._repository) : super(PropertiesInitial());

  Future<void> addProperty(PropertyModel newProp, List<Uint8List> images) async {
    final currentState = state;
    if (currentState is! PropertiesSuccess) return;

    emit(PropertiesLoading());
    try {
      final createdProperty = await _repository.createProperty(property: newProp, imageFiles: images);

      // إضافة في رأس القائمة
      List<PropertyModel> updatedList = [createdProperty, ...currentState.properties];

      // الحفاظ على سعة الصفحة (15 عنصر كحد أقصى)
      if (updatedList.length > AppConstants.pageSize) {
        updatedList = updatedList.sublist(0, AppConstants.pageSize);
      }

      emit(currentState.copyWith(
        properties: updatedList,
        totalCount: currentState.totalCount + 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل الإضافة: $e"));
      emit(currentState);
    }
  }

  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<String>? imagesToDelete, // الباراميتر الجديد
  }) async {
    final currentState = state;
    if (currentState is! PropertiesSuccess) return;

    emit(PropertiesLoading());
    try {
      // ننتظر نتيجة التعديل من الـ Repository
      final result = await _repository.updateProperty(
        property: property,
        newImages: newImages,
        imagesToDelete: imagesToDelete,
      );

      // تحديث العنصر داخل القائمة المحلية فقط دون إعادة تحميل الكل
      final updatedList = currentState.properties.map((p) => p.id == result.id ? result : p).toList();

      emit(currentState.copyWith(properties: updatedList));
    } catch (e) {
      emit(PropertiesError("خطأ أثناء التعديل: $e"));
      emit(currentState); // استعادة الحالة السابقة لفتح الأزرار
    }
  }

  Future<void> fetchPage({required int page, required String userId, required String role, String? city, String? type, bool sortByPrice = false}) async {
    emit(PropertiesLoading());
    try {
      final result = await _repository.fetchPropertiesWithPagination(page: page, userId: userId, role: role, city: city, type: type, sortByPrice: sortByPrice);
      emit(PropertiesSuccess(properties: result['properties'], currentPage: page, totalCount: result['totalCount'], city: city, type: type, sortByPrice: sortByPrice));
    } catch (e) { emit(PropertiesError("خطأ في التحميل: $e")); }
  }

  Future<void> deleteProperty(String id) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      try {
        await _repository.deleteProperty(id);
        final newList = currentState.properties.where((p) => p.id != id).toList();
        emit(currentState.copyWith(properties: newList, totalCount: currentState.totalCount - 1));
      } catch (e) { emit(PropertiesError("فشل الحذف: $e")); }
    }
  }
}