import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retaj_crm/features/properties/cubit/properties_state.dart';
import 'dart:typed_data';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';



class PropertiesCubit extends Cubit<PropertiesState> {
  final PropertiesRepository _repository;
  final int _pageSize = 15;

  PropertiesCubit(this._repository) : super(PropertiesInitial());


  void addPropertyToList(PropertyModel newProperty) {
    if (state is PropertiesSuccess) {
      final currentState = state as PropertiesSuccess;
      final updatedList = [newProperty, ...currentState.properties];
      emit(currentState.copyWith(properties: updatedList));
    } else {
      fetchProperties(userId: newProperty.createdBy, role: 'admin');
    }
  }


  Future<void> fetchProperties({
    required String userId,
    required String role,
    bool isRefresh = false,
    String? city,
    double? minPrice,
    double? maxPrice,
  }) async {
    emit(PropertiesLoading());
    try {
      final properties = await _repository.fetchProperties(
        page: 0,
        pageSize: _pageSize,
        userId: userId,
        role: role,
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      emit(PropertiesSuccess(
        properties: properties,
        currentPage: 0,
        hasMore: properties.length == _pageSize,
      ));
    } catch (e) {
      emit(PropertiesError("Error happened during fetching data$e"));
    }
  }


  Future<void> changePage(int newPage, String userId, String role) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      emit(currentState.copyWith(isPaginationLoading: true));
      try {
        final properties = await _repository.fetchProperties(
          page: newPage,
          pageSize: _pageSize,
          userId: userId,
          role: role,
        );
        emit(PropertiesSuccess(
          properties: properties,
          currentPage: newPage,
          hasMore: properties.length == _pageSize,
        ));
      } catch (e) {
        emit(PropertiesError("Failed to load screen"));
      }
    }
  }


  Future<void> addProperty(PropertyModel newProperty, List<Uint8List> images) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      try {
        if (images.length > 10) throw "your limit is 10 images";
        await _repository.createProperty(property: newProperty, imageFiles: images);
        final List<PropertyModel> updatedList = [newProperty, ...currentState.properties];
        if (updatedList.length > _pageSize) updatedList.removeLast();
        emit(currentState.copyWith(properties: updatedList));
      } catch (e) {
        emit(PropertiesError(e.toString()));
      }
    }
  }


  Future<void> updateProperty(PropertyModel updatedProperty) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      try {
        await _repository.updatePropertyData(updatedProperty);
        final List<PropertyModel> updatedList = currentState.properties.map((p) {
          return p.id == updatedProperty.id ? updatedProperty : p;
        }).toList();

        emit(currentState.copyWith(properties: updatedList));
      } catch (e) {
        emit(PropertiesError("failed to update data in server"));
      }
    }
  }


  Future<void> deleteImageFromProperty(String imageUrl, String propertyId) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      try {
        await _repository.deleteSingleImage(imageUrl);

        final updatedList = currentState.properties.map((p) {
          if (p.id == propertyId) {
            final newImages = List<String>.from(p.images)..remove(imageUrl);
            return p.copyWith(images: newImages);
          }
          return p;
        }).toList();

        emit(currentState.copyWith(properties: updatedList));
      } catch (e) {
        emit(PropertiesError('$e'));
      }
    }
  }


  Future<void> deleteProperty(String propertyId) async {
    final currentState = state;
    if (currentState is PropertiesSuccess) {
      try {
        await _repository.deleteProperty(propertyId);
        final updatedList = currentState.properties.where((p) => p.id != propertyId).toList();
        emit(currentState.copyWith(properties: updatedList));
      } catch (e) {
        emit(PropertiesError("failed to delete property"));
      }
    }
  }


  Future<void> saveFullProperty({
    required PropertyModel property,
    required List<Uint8List> imageBytesList,
  }) async {
    try {
      if (property.id == null) {
        await _repository.createProperty(property: property, imageFiles: imageBytesList);
      } else {
        await _repository.updatePropertyData(property);
        if (imageBytesList.isNotEmpty) {
          await _repository.uploadAdditionalImages(
            propertyId: property.id!,
            currentImagesCount: property.images.length,
            newImageFiles: imageBytesList,
          );
        }
      }
      await fetchProperties(userId: property.createdBy, role: 'admin');
    } catch (e) {
      emit(PropertiesError("error in saving $e"));
      rethrow;
    }
  }

}