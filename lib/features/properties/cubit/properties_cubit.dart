import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:retaj_crm/features/properties/cubit/properties_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertiesRepository _repository;
  PropertiesCubit(this._repository) : super(PropertiesInitial());

  // --- 1. جلب البيانات مع الكاش ---
  Future<void> fetchPage({
    required int page,
    required String userId,
    required String role,
    String? city,
    String? type,
    bool sortByPrice = false,
  }) async {
    final currentState = state;

    // فحص تغير الفلاتر
    bool filterChanged = false;
    if (currentState is PropertiesSuccess) {
      if (currentState.city != city || currentState.type != type || currentState.sortByPrice != sortByPrice) {
        filterChanged = true;
      } else if (currentState.propertyCache.containsKey(page)) {
        emit(currentState.copyWith(currentPage: page));
        return;
      }
    }

    emit(PropertiesLoading());

    try {
      final result = await _repository.fetchPropertiesWithPagination(
        page: page, userId: userId, role: role, city: city, type: type, sortByPrice: sortByPrice,
      );

      final List<PropertyModel> fetchedProperties = result['properties'];
      final int totalCount = result['totalCount'];

      if (currentState is PropertiesSuccess && !filterChanged) {
        final updatedCache = Map<int, List<PropertyModel>>.from(currentState.propertyCache);
        updatedCache[page] = fetchedProperties;
        emit(currentState.copyWith(propertyCache: updatedCache, currentPage: page, totalCount: totalCount));
      } else {
        emit(PropertiesSuccess(
          propertyCache: {page: fetchedProperties},
          currentPage: page,
          totalCount: totalCount,
          city: city,
          type: type,
          sortByPrice: sortByPrice,
        ));
      }
    } catch (e) {
      emit(PropertiesError("خطأ في التحميل: $e"));
    }
  }

  // --- 2. إضافة عقار مع "الدفع لأسفل" (Push Down Shifting) ---
  Future<void> addProperty(PropertyModel newProp, List<Uint8List> images) async {
    final currentState = state;
    if (currentState is! PropertiesSuccess) return;

    emit(PropertiesLoading());
    try {
      final createdProperty = await _repository.createProperty(property: newProp, imageFiles: images);

      final updatedCache = Map<int, List<PropertyModel>>.from(currentState.propertyCache);

      // نبدأ التشفيت من الصفحة الأولى دائماً لأن الإضافة تكون في البداية
      PropertyModel? carryOver = createdProperty;

      for (int i = 0; i < updatedCache.length; i++) {
        if (carryOver == null) break;

        List<PropertyModel> pageList = List.from(updatedCache[i]!);
        pageList.insert(0, carryOver); // إضافة العنصر في البداية

        if (pageList.length > AppConstants.pageSize) {
          carryOver = pageList.removeLast(); // العنصر الأخير يرحل للصفحة التالية
          updatedCache[i] = pageList;
        } else {
          updatedCache[i] = pageList;
          carryOver = null; // توقف التشفيت لأن الصفحة لم تكتمل بعد
        }
      }

      emit(currentState.copyWith(
        propertyCache: updatedCache,
        totalCount: currentState.totalCount + 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل الإضافة: $e"));
      emit(currentState);
    }
  }

  // --- 3. تحديث عقار (تحديث موضعي) ---
  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<String>? imagesToDelete,
  }) async {
    final currentState = state;
    if (currentState is! PropertiesSuccess) return;

    emit(PropertiesLoading());
    try {
      final result = await _repository.updateProperty(
        property: property, newImages: newImages, imagesToDelete: imagesToDelete,
      );

      final updatedCache = Map<int, List<PropertyModel>>.from(currentState.propertyCache);
      updatedCache.forEach((key, list) {
        final index = list.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          final newList = List<PropertyModel>.from(list);
          newList[index] = result;
          updatedCache[key] = newList;
        }
      });

      emit(currentState.copyWith(propertyCache: updatedCache));
    } catch (e) {
      emit(PropertiesError("خطأ التعديل: $e"));
      emit(currentState);
    }
  }

  // --- 4. حذف عقار مع "السحب للأعلى" (Pull Up Shifting) ---
  Future<void> deleteProperty(String id) async {
    final currentState = state;
    if (currentState is! PropertiesSuccess) return;

    try {
      await _repository.deleteProperty(id);
      final updatedCache = Map<int, List<PropertyModel>>.from(currentState.propertyCache);
      int startPage = -1;

      // 1. حذف العنصر وتحديد مكان البدء
      updatedCache.forEach((key, list) {
        if (list.any((p) => p.id == id)) {
          startPage = key;
          final newList = List<PropertyModel>.from(list)..removeWhere((p) => p.id == id);
          updatedCache[key] = newList;
        }
      });

      if (startPage == -1) return;

      // 2. عملية السحب (Pull Up) من الصفحات التالية
      for (int i = startPage; i < updatedCache.length - 1; i++) {
        if (updatedCache.containsKey(i + 1) && updatedCache[i + 1]!.isNotEmpty) {
          List<PropertyModel> currentList = List.from(updatedCache[i]!);
          List<PropertyModel> nextList = List.from(updatedCache[i + 1]!);

          currentList.add(nextList.removeAt(0)); // سحب أول عنصر من الصفحة التالية

          updatedCache[i] = currentList;
          updatedCache[i + 1] = nextList;
        }
      }

      // 3. معالجة النقص إذا كانت الصفحة التالية غير موجودة في الكاش
      if (updatedCache[currentState.currentPage]!.length < AppConstants.pageSize &&
          currentState.totalCount > (startPage + 1) * AppConstants.pageSize) {
        // هنا نقوم بعمل Fetch خلفي بسيط لملء الفراغ إذا لزم الأمر
        // أو نتركها للمستخدم عند عمل Refresh
      }

      emit(currentState.copyWith(
        propertyCache: updatedCache,
        totalCount: currentState.totalCount - 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل الحذف: $e"));
    }
  }
}