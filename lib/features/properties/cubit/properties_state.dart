import '../../../data/models/property_model.dart';

sealed class PropertiesState {}
class PropertiesInitial extends PropertiesState {}
class PropertiesLoading extends PropertiesState {}

class PropertiesSuccess extends PropertiesState {
  final List<PropertyModel> myProperties;
  final List<PropertyModel> filteredProperties;
  final List<PropertyModel> searchedProperties;
  final int myTotalCount;
  final int filteredTotalCount;

  PropertiesSuccess({
    this.myProperties = const [],
    this.filteredProperties = const [],
    this.searchedProperties = const [],
    this.myTotalCount = 0,
    this.filteredTotalCount = 0,
  });

  PropertiesSuccess copyWith({
    List<PropertyModel>? myProps,
    List<PropertyModel>? filterProps,
    List<PropertyModel>? searchProps,
    int? myCount,
    int? fCount,
  }) {
    return PropertiesSuccess(
      myProperties: myProps ?? this.myProperties,
      filteredProperties: filterProps ?? this.filteredProperties,
      searchedProperties: searchProps ?? this.searchedProperties,
      myTotalCount: myCount ?? this.myTotalCount,
      filteredTotalCount: fCount ?? this.filteredTotalCount,
    );
  }
}

class PropertiesError extends PropertiesState {
  final String message;
  PropertiesError(this.message);
}