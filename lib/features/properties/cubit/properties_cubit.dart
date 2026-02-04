import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/property_image_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import 'properties_state.dart';


class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyRepository _repo;
  PropertiesCubit(this._repo) : super(PropertiesInitial());

  // 1. جلب عقارات الموظف (Infinite Scroll)
  Future<void> fetchMyProperties({bool isRefresh = false, required String userId}) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();

    // منع الطلبات المتكررة إذا وصلنا للنهاية
    if (!isRefresh && current.myProperties.length >= current.myTotalCount && current.myTotalCount != 0) return;

    try {
      if (isRefresh) emit(PropertiesLoading());

      final count = await _repo.fetchMyCount(userId);
      final newItems = await _repo.getMyProperties(
          userId,
          isRefresh ? 0 : current.myProperties.length,
          (isRefresh ? 0 : current.myProperties.length) + 14
      );

      emit(current.copyWith(
        myProps: isRefresh ? newItems : [...current.myProperties, ...newItems],
        myCount: count,
      ));
    } catch (e) {
      emit(PropertiesError("فشل تحميل عقاراتي: $e"));
    }
  }

  // 2. الفلترة العامة
  Future<void> applyFilter({String? city, String? type}) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();
    emit(PropertiesLoading());
    try {
      final count = await _repo.fetchFilterCount(c: city, ty: type);
      final newItems = await _repo.filterProperties(0, 14, c: city, ty: type);
      emit(current.copyWith(
          filterProps: newItems,
          fCount: count
      ));
    } catch (e) {
      emit(PropertiesError("فشل الفلترة: $e"));
    }
  }

  // 3. البحث (يحدث قائمة البحث فقط دون لمس عقاراتي)
  Future<void> search(String term) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();
    if (term.isEmpty) {
      emit(current.copyWith(searchProps: []));
      return;
    }
    try {
      final results = await _repo.searchProperties(term);
      emit(current.copyWith(searchProps: results));
    } catch (e) {
      emit(PropertiesError("فشل البحث: $e"));
    }
  }

  /*// 4. إضافة عقار (التي استدعيناها في الـ Form)
  Future<void> addProperty(PropertyModel p, List<Uint8List> imgs) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();
    try {
      final newProp = await _repo.createFullProperty(p, imgs);
      emit(current.copyWith(
        myProps: [newProp, ...current.myProperties],
        myCount: current.myTotalCount + 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل إضافة العقار: $e"));
    }
  }*/
  Future<void> addProperty(PropertyModel p, List<Uint8List> imgs) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();

    // 1. إرسال حالة التحميل فوراً لتغيير شكل الزر في الواجهة
    emit(PropertiesLoading());

    try {
      final newProp = await _repo.createFullProperty(p, imgs);
      emit(current.copyWith(
        myProps: [newProp, ...current.myProperties],
        myCount: current.myTotalCount + 1,
      ));
    } catch (e) {
      // 2. إرسال الخطأ
      emit(PropertiesError("فشل إضافة العقار: $e"));
      // 3. إعادة الحالة السابقة (Success) عشان الزرار يرجع يظهر تاني والبيانات متضيعش
      emit(current);
    }
  }



  // 5. حذف عقار (التي استدعيناها في الـ UI)
  Future<void> deleteFullProperty(String id) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();
    try {
      await _repo.deleteFullProperty(id);

      // تحديث القائمة محلياً فوراً لحذف العنصر من الـ UI
      final updatedList = current.myProperties.where((p) => p.id != id).toList();
      emit(current.copyWith(
        myProps: updatedList,
        myCount: current.myTotalCount - 1,
      ));
    } catch (e) {
      emit(PropertiesError("فشل حذف العقار: $e"));
    }
  }



  /*// 6. تحديث عقار (تحديث موضعي في القائمة)
  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<String>? imagesToDelete,
  }) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();

    // إظهار حالة التحميل اختياري، لكن يفضل لراحة المستخدم
    emit(PropertiesLoading());

    try {
      // استدعاء الريبوزيتوري للتحديث في قاعدة البيانات
      final updatedProp = await _repo.updateFullProperty(
          p: property,
          newImgs: newImages,
          delImgs: imagesToDelete
      );

      // تحديث العنصر في القائمة المحلية (myProperties) دون إعادة تحميل الكل
      final updatedList = current.myProperties.map((p) {
        return p.id == updatedProp.id ? updatedProp : p;
      }).toList();

      emit(current.copyWith(myProps: updatedList));
    } catch (e) {
      emit(PropertiesError("فشل تحديث العقار: $e"));
      // إعادة الحالة السابقة في حال الخطأ لضمان استمرار عمل الواجهة
      emit(current);
    }
  }*/
  Future<void> updateProperty({
    required PropertyModel property,
    required List<Uint8List> newImages,
    List<PropertyImageModel>? imagesToDelete, // تعديل النوع هنا
  }) async {
    final current = state is PropertiesSuccess ? state as PropertiesSuccess : PropertiesSuccess();

    emit(PropertiesLoading());

    try {
      // فصل الـ IDs والـ URLs قبل إرسالهم للـ Repository
      final List<String> delIds = imagesToDelete?.map((e) => e.id!).toList() ?? [];
      final List<String> delUrls = imagesToDelete?.map((e) => e.imageUrl).toList() ?? [];

      final updatedProp = await _repo.updateFullProperty(
          p: property,
          newImgs: newImages,
          delImgsIds: delIds,   // نمرر الـ IDs للداتا بيز
          delImgsUrls: delUrls  // نمرر الـ URLs للستوريدج
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