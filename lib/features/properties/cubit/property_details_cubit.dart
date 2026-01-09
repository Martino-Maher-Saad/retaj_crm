import 'package:flutter_bloc/flutter_bloc.dart';

class PropertyDetailsState {
  final int currentIndex;
  PropertyDetailsState({required this.currentIndex});
}

class PropertyDetailsCubit extends Cubit<PropertyDetailsState> {
  PropertyDetailsCubit() : super(PropertyDetailsState(currentIndex: 0));

  void updateImageIndex(int index) {
    emit(PropertyDetailsState(currentIndex: index));
  }
}