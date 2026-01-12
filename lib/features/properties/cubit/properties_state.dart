import '../../../data/models/property_model.dart';

sealed class PropertiesState {}

class PropertiesInitial extends PropertiesState {}
class PropertiesLoading extends PropertiesState {}

class PropertiesSuccess extends PropertiesState {
  final List<PropertyModel> properties;
  final int currentPage;
  final int totalCount;
  final String? city;
  final String? type;
  final bool sortByPrice;

  PropertiesSuccess({
    required this.properties,
    required this.currentPage,
    required this.totalCount,
    this.city,
    this.type,
    this.sortByPrice = false,
  });

  int get totalPages => (totalCount / 15).ceil();

  PropertiesSuccess copyWith({
    List<PropertyModel>? properties,
    int? currentPage,
    int? totalCount,
    String? city,
    String? type,
    bool? sortByPrice,
  }) {
    return PropertiesSuccess(
      properties: properties ?? this.properties,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      city: city ?? this.city,
      type: type ?? this.type,
      sortByPrice: sortByPrice ?? this.sortByPrice,
    );
  }
}

class PropertiesError extends PropertiesState {
  final String message;
  PropertiesError(this.message);
}