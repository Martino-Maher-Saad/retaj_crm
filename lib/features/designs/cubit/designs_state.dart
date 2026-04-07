import '../../../data/models/design_model.dart';

abstract class DesignsState {}

class DesignsInitial extends DesignsState {}

class DesignsLoading extends DesignsState {}

class DesignsLoaded extends DesignsState {
  final List<DesignModel> designs;
  final bool hasReachedMax;

  DesignsLoaded({required this.designs, required this.hasReachedMax});

  DesignsLoaded copyWith({
    List<DesignModel>? designs,
    bool? hasReachedMax,
  }) {
    return DesignsLoaded(
      designs: designs ?? this.designs,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class DesignsError extends DesignsState {
  final String message;
  DesignsError(this.message);
}

class DesignsSearching extends DesignsState {}

class DesignsSearchLoaded extends DesignsState {
  final List<DesignModel> searchResults;
  DesignsSearchLoaded(this.searchResults);
}
