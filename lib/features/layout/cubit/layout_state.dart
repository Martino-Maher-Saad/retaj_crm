abstract class LayoutState {}

class LayoutNavigationChanged extends LayoutState {
  final int selectedIndex;
  final String pageTitle;

  LayoutNavigationChanged(this.selectedIndex, this.pageTitle);
}