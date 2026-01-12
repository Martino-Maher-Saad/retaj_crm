import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:retaj_crm/features/properties/cubit/properties_state.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';


class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertiesRepository _repository;
  PropertiesCubit(this._repository) : super(PropertiesInitial());

  // جلب صفحة معينة مع الفلاتر
  Future<void> fetchPage({
    required int page,
    required String userId,
    required String role,
    String? city,
    String? type,
    bool sortByPrice = false,
  }) async {
    emit(PropertiesLoading());
    try {
      final result = await _repository.fetchPropertiesWithPagination(
        page: page, userId: userId, role: role,
        city: city, type: type, sortByPrice: sortByPrice,
      );
      emit(PropertiesSuccess(
        properties: result['properties'],
        currentPage: page,
        totalCount: result['totalCount'],
        city: city, type: type, sortByPrice: sortByPrice,
      ));
    } catch (e) {
      emit(PropertiesError("خطأ في التحميل: $e"));
    }
  }


  // 2. تحديث محلي (Local Update)
  // تُستخدم لتحديث واجهة المستخدم فوراً بعد نجاح تعديل عقار معين
  void updatePropertyLocally(PropertyModel updatedProperty) {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      // نقوم بإنشاء قائمة جديدة مع استبدال العقار القديم بالجديد بناءً على الـ ID
      final updatedList = currentState.properties.map((property) {
        return property.id == updatedProperty.id ? updatedProperty : property;
      }).toList();

      // نحدث الـ State بالقائمة الجديدة دون تغيير بقية البيانات (مثل رقم الصفحة أو العدد الكلي)
      emit(currentState.copyWith(properties: updatedList));
    }
  }


  // إضافة عقار: يظهر فوق فوراً لو إحنا في أول صفحة
  Future<void> addProperty(PropertyModel newProp, List<Uint8List> images) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      if (currentState.currentPage != 0) return;

      // 1. لا نستخدم PropertiesLoading الشاملة لكي لا تختفي القائمة
      // بل نعتمد على استجابة السيرفر مع بقاء الواجهة نشطة
      try {
        // نصيحة: يفضل ضغط الصور قبل تمريرها لهذه الدالة
        final createdProperty = await _repository.createProperty(
            property: newProp,
            imageFiles: images
        );

        final List<PropertyModel> updatedList = List.from(currentState.properties);
        updatedList.insert(0, createdProperty);

        if (updatedList.length > 15) {
          updatedList.removeLast();
        }

        emit(currentState.copyWith(
            properties: updatedList,
            totalCount: currentState.totalCount + 1
        ));

      } catch (e) {
        emit(PropertiesError("فشل في إضافة العقار: $e"));
        emit(currentState);
      }
    }
  }

  // حذف لحظي
  Future<void> deleteProperty(String id) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      try {
        await _repository.deleteProperty(id);
        final newList = currentState.properties.where((p) => p.id != id).toList();
        emit(currentState.copyWith(properties: newList, totalCount: currentState.totalCount - 1));
      } catch (e) { /* Error handling */ }
    }
  }


  // داخل PropertiesCubit

  Future<void> updateProperty(PropertyModel updatedProp, List<Uint8List> newImages) async {
    try {
      // نكلم الـ Repo وننتظر النتيجة المحدثة
      final result = await _repository.updateProperty(
          property: updatedProp,
          newImages: newImages
      );

      // نحدث الحالة محلياً فوراً (Local Update)
      updatePropertyLocally(result);

    } catch (e) {
      emit(PropertiesError("خطأ أثناء التعديل: $e"));
      rethrow;
    }
  }

}