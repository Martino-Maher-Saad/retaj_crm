import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/design_model.dart';
import '../../../data/repositories/design_repository.dart';

abstract class DesignsState {}

class DesignsInitial extends DesignsState {}
class DesignsLoading extends DesignsState {}
class DesignsLoaded extends DesignsState {
  final List<DesignModel> designs;
  final bool hasReachedMax;
  final bool isSearching;
  
  DesignsLoaded({
    required this.designs, 
    required this.hasReachedMax,
    this.isSearching = false,
  });
}
class DesignsError extends DesignsState {
  final String message;
  DesignsError(this.message);
}

class DesignsCubit extends Cubit<DesignsState> {
  final DesignRepository _repo;
  final int _limit = 20;

  DesignsCubit(this._repo) : super(DesignsInitial());

  Future<void> fetchDesigns({bool refresh = false, String? roomTypeId, String? styleId, String? addedByProfileId}) async {
    try {
      if (state is DesignsLoading) return;
      
      List<DesignModel> currentDesigns = [];
      if (state is DesignsLoaded && !refresh) {
        currentDesigns = (state as DesignsLoaded).designs;
        if ((state as DesignsLoaded).hasReachedMax) return; // لا مزيد من البيانات
      }

      if (currentDesigns.isEmpty) {
        emit(DesignsLoading());
      }

      final newDesigns = await _repo.getDesigns(
        limit: _limit,
        offset: currentDesigns.length,
        roomTypeId: roomTypeId,
        styleId: styleId, addedByProfileId: addedByProfileId,
      );

      emit(DesignsLoaded(
        designs: currentDesigns + newDesigns,
        hasReachedMax: newDesigns.length < _limit,
      ));
    } catch (e, s) {
      print('🔴 ERROR in fetchDesigns: $e');
      print('🔴 STACKTRACE: $s');
      emit(DesignsError('فشل جلب التشطيبات: $e'));
    }
  }

  Future<void> searchDesigns(String query, {String? roomTypeId, String? styleId, String? addedByProfileId}) async {
    if (query.trim().isEmpty) {
      return fetchDesigns(refresh: true, roomTypeId: roomTypeId, styleId: styleId, addedByProfileId: addedByProfileId);
    }
    
    try {
      emit(DesignsLoading());
      final results = await _repo.searchDesignsByAi(query, roomTypeId: roomTypeId, styleId: styleId);
      emit(DesignsLoaded(
        designs: results,
        hasReachedMax: true, // البحث الذكي يرجع نتيجة واحدة ثابتة ولا يدعم الـ Pagination العادي
        isSearching: true,
      ));
    } catch (e) {
      emit(DesignsError('فشل البحث الذكي: $e'));
    }
  }

  Future<void> deleteDesign(String id) async {
    if (state is! DesignsLoaded) return;
    final currentState = state as DesignsLoaded;
    
    try {
      await _repo.deleteDesign(id);
      final newDesigns = currentState.designs.where((d) => d.id != id).toList();
      emit(DesignsLoaded(
        designs: newDesigns,
        hasReachedMax: currentState.hasReachedMax,
        isSearching: currentState.isSearching,
      ));
    } catch (e) {
      // إرسال رسالة خطأ مؤقتة ثم العودة للحالة السابقة (يمكن التقاطها بـ BlocListener)
      emit(DesignsError('فشل الحذف: $e'));
      emit(currentState);
    }
  }

  // إضافة تصميم للقائمة محلياً (بعد إضافته بنجاح من الـ Form)
  void addDesignLocally(DesignModel newDesign) {
    if (state is DesignsLoaded) {
      final current = state as DesignsLoaded;
      emit(DesignsLoaded(
        designs: [newDesign, ...current.designs],
        hasReachedMax: current.hasReachedMax,
        isSearching: current.isSearching,
      ));
    }
  }

  // تحديث تصميم بالقائمة محلياً
  void updateDesignLocally(DesignModel updatedDesign) {
    if (state is DesignsLoaded) {
      final current = state as DesignsLoaded;
      final newDesigns = current.designs.map((d) {
        return d.id == updatedDesign.id ? updatedDesign : d;
      }).toList();
      emit(DesignsLoaded(
        designs: newDesigns,
        hasReachedMax: current.hasReachedMax,
        isSearching: current.isSearching,
      ));
    }
  }
}
