import 'package:bloc/bloc.dart';
import 'layout_state.dart';

class LayoutCubit extends Cubit<LayoutState>{

  LayoutCubit() : super(LayoutNavigationChanged(0, "Dashboard"));

  void changeNavigation(int index, String role){
    List<String> titles = _getTitlesByRole(role);
    emit(LayoutNavigationChanged(index, titles[index]));
  }

  List<String> _getTitlesByRole(String role){
    if(role == 'manager'){
      return ['System Dashboard', 'All Properties', 'All Leads', 'All Designs', 'Employee Management'];
    }
    else{
      return ['System Dashboard', 'My Properties', 'My Leads', 'My Designs', 'My Profile'];
    }
  }

}