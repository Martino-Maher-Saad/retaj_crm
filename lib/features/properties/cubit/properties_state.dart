import '../../../data/models/property_model.dart';


sealed class PropertiesState {}


class PropertiesInitial extends PropertiesState {}


class PropertiesLoading extends PropertiesState {}


class PropertiesError extends PropertiesState {
  final String message;
  PropertiesError(this.message);
}


class PropertiesSuccess extends PropertiesState {
  final List<PropertyModel> properties;
  final int currentPage;
  final bool hasMore;
  final bool isPaginationLoading;

  PropertiesSuccess({
    required this.properties,
    required this.currentPage,
    required this.hasMore,
    this.isPaginationLoading = false,
  });

  PropertiesSuccess copyWith({
    List<PropertyModel>? properties,
    int? currentPage,
    bool? hasMore,
    bool? isPaginationLoading,
  }) {
    return PropertiesSuccess(
      properties: properties ?? this.properties,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isPaginationLoading: isPaginationLoading ?? this.isPaginationLoading,
    );
  }
}

