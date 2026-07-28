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
  final bool isSearching;
  final bool isFiltering;
  final bool hasMoreSmartSearch;
  final bool hasNewUpdates;
  final String? blinkItemId;
  final List<PropertyModel> pendingProperties;

  PropertiesSuccess({
    this.myProperties = const [],
    this.filteredProperties = const [],
    this.searchedProperties = const [],
    this.myTotalCount = 0,
    this.filteredTotalCount = 0,
    this.isSearching = false,
    this.isFiltering = false,
    this.hasMoreSmartSearch = true,
    this.hasNewUpdates = false,
    this.blinkItemId,
    this.pendingProperties = const [],
  });

  PropertiesSuccess copyWith({
    List<PropertyModel>? myProperties,
    List<PropertyModel>? filteredProperties,
    List<PropertyModel>? searchedProperties,
    int? myTotalCount,
    int? filteredTotalCount,
    bool? isSearching,
    bool? isFiltering,
    bool? hasMoreSmartSearch,
    bool? hasNewUpdates,
    String? blinkItemId,
    List<PropertyModel>? pendingProperties,
  }) {
    return PropertiesSuccess(
      myProperties: myProperties ?? this.myProperties,
      filteredProperties: filteredProperties ?? this.filteredProperties,
      searchedProperties: searchedProperties ?? this.searchedProperties,
      myTotalCount: myTotalCount ?? this.myTotalCount,
      filteredTotalCount: filteredTotalCount ?? this.filteredTotalCount,
      isSearching: isSearching ?? this.isSearching,
      isFiltering: isFiltering ?? this.isFiltering,
      hasMoreSmartSearch: hasMoreSmartSearch ?? this.hasMoreSmartSearch,
      hasNewUpdates: hasNewUpdates ?? this.hasNewUpdates,
      blinkItemId: blinkItemId,
      pendingProperties: pendingProperties ?? this.pendingProperties,
    );
  }
}

class PropertiesError extends PropertiesState {
  final String message;
  PropertiesError(this.message);
}
