import 'package:bloc/bloc.dart';
import 'layout_state.dart';

class LayoutCubit extends Cubit<LayoutState>{

  LayoutCubit() : super(LayoutNavigationChanged(0));

  void changeNavigation(int index){
    emit(LayoutNavigationChanged(index));
  }

}