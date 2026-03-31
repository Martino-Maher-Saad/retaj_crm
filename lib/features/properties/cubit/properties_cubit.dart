import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/property_image_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyRepository _repo;
  PropertiesCubit(this._repo) : super(PropertiesInitial());

  // 1. جلب عقارات الموظف (أو المدير) (Infinite Scroll)
  Future<void> fetchMyProperties({
    bool isRefresh = false,
    required String userId,
    required String role, 
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    // منع الطلبات المتكررة إذا وصلنا للنهاية
    if (!isRefresh &&
        current.myProperties.length >= current.myTotalCount &&
        current.myTotalCount != 0)
      return;

    try {
      if (isRefresh) emit(PropertiesLoading());

      final isManager = role == 'manager';
      final count = isManager 
          ? await _repo.fetchFilterCount() 
          : await _repo.fetchMyCount(userId);
          
      final newItems = isManager
          ? await _repo.filterProperties(
              isRefresh ? 0 : current.myProperties.length,
              (isRefresh ? 0 : current.myProperties.length) + 14,
            )
          : await _repo.getMyProperties(
              userId,
              isRefresh ? 0 : current.myProperties.length,
              (isRefresh ? 0 : current.myProperties.length) + 14,
            );

      emit(
        current.copyWith(
          myProps: isRefresh
              ? newItems
              : [...current.myProperties, ...newItems],
          myCount: count,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل تحميل العقارات: $e"));
    }
  }

  // 2. الفلترة العامة (المتقدمة)
  Future<void> applyAdvancedFilters({
    String? city,
    String? type,
    String? governorate,
    String? listingType,
    num? minPrice,
    num? maxPrice,
    String? selectedEmployee, // للمدير فقط
    required String role,
    required String currentUserId,
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    emit(PropertiesLoading());
    try {
      // تفريق الفلترة بين الموظف والمدير
      final filterUserId = role == 'manager' ? selectedEmployee : currentUserId;

      final count = await _repo.fetchFilterCount(
        c: city, 
        ty: type,
        governorate: governorate,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: filterUserId,
      );
      final newItems = await _repo.filterProperties(
        0, 14, 
        c: city, 
        ty: type,
        governorate: governorate,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: filterUserId,
      );
      // استخدام filterProps بدلاً من مسح القائمة الأساسية وتفعيل وضع الفلتر
      emit(current.copyWith(filterProps: newItems, fCount: count, isFiltering: true));
    } catch (e) {
      emit(PropertiesError("فشل الفلترة: $e"));
    }
  }

  // 3. البحث (يحدث قائمة البحث فقط دون لمس عقاراتي)
  Future<void> search(String term) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (term.isEmpty) {
      emit(current.copyWith(searchProps: []));
      return;
    }
    try {
      final results = await _repo.searchProperties(term);
      emit(current.copyWith(myProps: results, myCount: results.length));
    } catch (e) {
      emit(PropertiesError("فشل البحث: $e"));
    }
  }

  // البحث الذكي بالذكاء الاصطناعي
  Future<void> smartSearch(String query) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    
    emit(PropertiesLoading()); // إظهار الشيمر شاشة التحميل بدلا من التجميد

    try {
      final results = await _repo.searchWithAi(query);
      emit(current.copyWith(searchProps: results, isSearching: true));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      emit(current);
    }
  }

  // 4. إلغاء الفلتر ومسح البحث
  void clearSearch() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      emit(current.copyWith(isSearching: false, searchProps: []));
    }
  }

  void clearFilter() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      emit(current.copyWith(isFiltering: false, filterProps: []));
    }
  }

  Future<void> addProperty(PropertyModel p, List<Uint8List> imgs) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    // 1. إرسال حالة التحميل فوراً لتغيير شكل الزر في الواجهة
    //emit(PropertiesLoading());

    try {
      final newProp = await _repo.createFullProperty(p, imgs);
      emit(
        current.copyWith(
          myProps: [newProp, ...current.myProperties],
          myCount: current.myTotalCount + 1,
        ),
      );
    } catch (e) {
      // 2. إرسال الخطأ
      emit(PropertiesError("فشل إضافة العقار: $e"));
      // 3. إعادة الحالة السابقة (Success) عشان الزرار يرجع يظهر تاني والبيانات متضيعش
      emit(current);
    }
  }

  // 5. حذف عقار (التي استدعيناها في الـ UI)
  Future<void> deleteFullProperty(String id) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    try {
      await _repo.deleteFullProperty(id);

      // تحديث القائمة محلياً فوراً لحذف العنصر من الـ UI
      final updatedList = current.myProperties
          .where((p) => p.id != id)
          .toList();
      emit(
        current.copyWith(
          myProps: updatedList,
          myCount: current.myTotalCount - 1,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل حذف العقار: $e"));
    }
  }

  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<PropertyImageModel>? imagesToDelete, // تعديل النوع هنا
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    //emit(PropertiesLoading());

    try {
      // فصل الـ IDs والـ URLs قبل إرسالهم للـ Repository
      final List<String> delIds =
          imagesToDelete?.map((e) => e.id!).toList() ?? [];
      final List<String> delUrls =
          imagesToDelete?.map((e) => e.imageUrl).toList() ?? [];

      final updatedProp = await _repo.updateFullProperty(
        p: property,
        newImgs: newImages,
        delImgsIds: delIds, // نمرر الـ IDs للداتا بيز
        delImgsUrls: delUrls, // نمرر الـ URLs للستوريدج
      );

      final updatedList = current.myProperties.map((p) {
        return p.id == updatedProp.id ? updatedProp : p;
      }).toList();

      emit(current.copyWith(myProps: updatedList));
    } catch (e) {
      emit(PropertiesError("فشل تحديث العقار: $e"));
      emit(current);
    }
  }
}
