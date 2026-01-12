abstract class LayoutState {}

class LayoutNavigationChanged extends LayoutState {
  final int selectedIndex;

  LayoutNavigationChanged(this.selectedIndex);
}