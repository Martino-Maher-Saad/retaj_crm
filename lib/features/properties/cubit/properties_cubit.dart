import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/property_image_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import 'properties_state.dart';

class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertyRepository _repo;
  PropertiesCubit(this._repo) : super(PropertiesInitial());

  // ─────────────────────────────────────────────────────────────
  // Pagination state for advanced filters (to avoid mixing lists)
  // ─────────────────────────────────────────────────────────────
  String? _filterAssignedTo;
  String? _filterCity;
  String? _filterType;
  String? _filterGovernorate;
  String? _filterListingType;
  num? _filterMinPrice;
  num? _filterMaxPrice;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;

  bool _isLoadingMoreFiltered = false;

  @override
  void emit(PropertiesState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

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

      final isManagerOrAdmin = role == 'manager' || role == 'admin';
      final count = isManagerOrAdmin 
          ? await _repo.fetchFilterCount() 
          : await _repo.fetchMyCount(userId);
          
      final newItems = isManagerOrAdmin
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
          myProperties: isRefresh
              ? newItems
              : [...current.myProperties, ...newItems],
          myTotalCount: count,
        ),
      );
    } catch (e, stackTrace) {
      print('=== ERROR IN PROPERTIES CUBIT (fetchMyProperties) ===');
      print(e);
      print(stackTrace);
      print('=====================================================');
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
    DateTime? fromDate,
    DateTime? toDate,
    required String role,
    required String currentUserId,
  }) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    emit(PropertiesLoading());
    try {
      // تفريق الفلترة بين الموظف والمدير/الأدمن
      final filterUserId =
          (role == 'manager' || role == 'admin') ? selectedEmployee : currentUserId;

      // تخزين شروط الفلتر علشان loadMore يكمل بنفس الشروط
      _filterCity = city;
      _filterType = type;
      _filterGovernorate = governorate;
      _filterListingType = listingType;
      _filterMinPrice = minPrice;
      _filterMaxPrice = maxPrice;
      _filterFromDate = fromDate;
      _filterToDate = toDate;
      _filterAssignedTo = filterUserId;

      final count = await _repo.fetchFilterCount(
        c: city, 
        ty: type,
        governorate: governorate,
        listingType: listingType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        assignedTo: filterUserId,
        fromDate: fromDate,
        toDate: toDate,
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
        fromDate: fromDate,
        toDate: toDate,
      );
      // استخدام filteredProperties بدلاً من مسح القائمة الأساسية وتفعيل وضع الفلتر
      emit(
        current.copyWith(
          myProperties: current.myProperties, // keep current base list
          searchedProperties: const [],
          isSearching: false,
          filteredProperties: newItems,
          filteredTotalCount: count,
          isFiltering: true,
        ),
      );
    } catch (e) {
      emit(PropertiesError("فشل الفلترة: $e"));
    }
  }

  /// Infinite-scroll for `filteredProperties` while `isFiltering == true`.
  Future<void> loadMoreFilteredProperties() async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();

    if (_isLoadingMoreFiltered) return;

    // إذا خلصنا كل العناصر المطلوبة، لا نكرر الطلب
    if (current.filteredProperties.length >= current.filteredTotalCount &&
        current.filteredTotalCount != 0) return;

    _isLoadingMoreFiltered = true;
    try {
      final from = current.filteredProperties.length;
      final to = from + 14; // 15 items/page (range inclusive)

      final newItems = await _repo.filterProperties(
        from,
        to,
        c: _filterCity,
        ty: _filterType,
        governorate: _filterGovernorate,
        listingType: _filterListingType,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
        assignedTo: _filterAssignedTo,
        fromDate: _filterFromDate,
        toDate: _filterToDate,
      );

      emit(
        current.copyWith(
          filteredProperties: [...current.filteredProperties, ...newItems],
        ),
      );
    } catch (e) {
      // نرجع الـ UI بدون ما نكسر التجربة
      emit(PropertiesError("فشل تحميل المزيد للـ فلتر: $e"));
    } finally {
      _isLoadingMoreFiltered = false;
    }
  }

  // 3. البحث (يحدث قائمة البحث فقط دون لمس عقاراتي)
  Future<void> search(String term) async {
    final current = state is PropertiesSuccess
        ? state as PropertiesSuccess
        : PropertiesSuccess();
    if (term.isEmpty) {
      emit(current.copyWith(searchedProperties: []));
      return;
    }
    try {
      final results = await _repo.searchProperties(term);
      emit(current.copyWith(myProperties: results, myTotalCount: results.length));
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
      emit(current.copyWith(searchedProperties: results, isSearching: true));
    } catch (e) {
      emit(PropertiesError(e.toString()));
      emit(current);
    }
  }

  // 4. إلغاء الفلتر ومسح البحث
  void clearSearch() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      emit(current.copyWith(isSearching: false, searchedProperties: []));
    }
  }

  void clearFilter() {
    if (state is PropertiesSuccess) {
      final current = state as PropertiesSuccess;
      emit(current.copyWith(isFiltering: false, filteredProperties: []));
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
          myProperties: [newProp, ...current.myProperties],
          myTotalCount: current.myTotalCount + 1,
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
          myProperties: updatedList,
          myTotalCount: current.myTotalCount - 1,
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

      emit(current.copyWith(myProperties: updatedList));
    } catch (e) {
      emit(PropertiesError("فشل تحديث العقار: $e"));
      emit(current);
    }
  }
}
