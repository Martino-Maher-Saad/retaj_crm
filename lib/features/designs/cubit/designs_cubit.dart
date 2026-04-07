import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/design_model.dart';
import '../../../data/repositories/design_repository.dart';
import 'designs_state.dart';

class DesignsCubit extends Cubit<DesignsState> {
  final DesignRepository _repository;
  
  static const int _limit = 14;
  int _currentFrom = 0;
  bool _isFetching = false;
  
  List<DesignModel> _currentDesigns = [];
  List<DesignModel> _searchedDesigns = [];
  bool _isSearchMode = false;

  DesignsCubit(this._repository) : super(DesignsInitial());

  Future<void> fetchDesigns({bool isRefresh = false}) async {
    if (_isFetching) return;
    
    if (isRefresh) {
      _currentFrom = 0;
      _currentDesigns.clear();
      _isSearchMode = false;
      emit(DesignsLoading());
    }

    _isFetching = true;

    try {
      final int to = _currentFrom + _limit;
      final newDesigns = await _repository.getDesigns(from: _currentFrom, to: to);

      _currentDesigns.addAll(newDesigns);
      _currentFrom = to + 1;

      emit(DesignsLoaded(
        designs: List.from(_currentDesigns),
        hasReachedMax: newDesigns.length <= _limit,
      ));
    } catch (e) {
      if (isRefresh) emit(DesignsError(e.toString()));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> searchDesigns(String query) async {
    if (query.isEmpty) {
      _isSearchMode = false;
      emit(DesignsLoaded(designs: _currentDesigns, hasReachedMax: false)); // We could recalculate hasReachedMax but this is fine for exiting search
      return;
    }

    _isSearchMode = true;
    emit(DesignsSearching());
    try {
      final results = await _repository.searchDesignsSemantic(query);
      _searchedDesigns = results;
      emit(DesignsSearchLoaded(results));
    } catch (e) {
      emit(DesignsError(e.toString()));
    }
  }

  Future<void> addDesign(DesignModel design, List<Uint8List> images) async {
    emit(DesignsLoading());
    try {
      final newDesign = await _repository.createFullDesign(baseDesign: design, rawImages: images);
      
      // Optimistic update
      _currentDesigns.insert(0, newDesign);
      
      if (!_isSearchMode) {
        emit(DesignsLoaded(designs: List.from(_currentDesigns), hasReachedMax: false));
      } else {
        emit(DesignsSearchLoaded(_searchedDesigns)); 
      }
    } catch (e) {
      emit(DesignsError(e.toString()));
      if (!_isSearchMode) {
         emit(DesignsLoaded(designs: List.from(_currentDesigns), hasReachedMax: false));
      }
      rethrow;
    }
  }

  Future<void> removeDesign(String id) async {
    try {
      await _repository.deleteFullDesign(id);
      
      _currentDesigns.removeWhere((d) => d.id == id);
      if (_isSearchMode) {
         _searchedDesigns.removeWhere((d) => d.id == id);
         emit(DesignsSearchLoaded(List.from(_searchedDesigns)));
      } else {
         emit(DesignsLoaded(designs: List.from(_currentDesigns), hasReachedMax: false));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDesign({
    required String designId,
    required Map<String, dynamic> updatedFields,
    required List<Uint8List> newImagesBytes,
    required List<String> imagesToDeleteIds,
  }) async {
    emit(DesignsLoading());
    try {
      final updatedDesign = await _repository.updateFullDesign(
        designId: designId,
        updatedFields: updatedFields,
        newImagesBytes: newImagesBytes,
        imagesToDeleteIds: imagesToDeleteIds,
      );

      final index = _currentDesigns.indexWhere((d) => d.id == designId);
      if (index != -1) {
        _currentDesigns[index] = updatedDesign;
      }
      
      if (_isSearchMode) {
        final searchIndex = _searchedDesigns.indexWhere((d) => d.id == designId);
        if (searchIndex != -1) {
          _searchedDesigns[searchIndex] = updatedDesign;
        }
        emit(DesignsSearchLoaded(List.from(_searchedDesigns)));
      } else {
        emit(DesignsLoaded(designs: List.from(_currentDesigns), hasReachedMax: false)); // Using false, pagination handles the rest
      }
    } catch (e) {
      emit(DesignsError("فشل تحديث التصميم: $e"));
      if (!_isSearchMode) {
         emit(DesignsLoaded(designs: List.from(_currentDesigns), hasReachedMax: false));
      }
      rethrow;
    }
  }
}
