import 'package:flutter/material.dart';
import '../../../../core/widgets/retaj_page_header.dart';

/// رأس قائمة العقارات — يستخدم RetajPageHeader الموحّد
class PropertyListHeader extends StatelessWidget {
  final int totalCount;
  final VoidCallback onAdd;
  final VoidCallback? onFilter;

  final Widget? filterBar;
  final Widget? extraAction;

  const PropertyListHeader({
    super.key,
    required this.totalCount,
    required this.onAdd,
    this.onFilter,
    this.filterBar,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    return RetajPageHeader(
      title: 'مخزون العقارات',
      subtitle: 'إدارة وعرض جميع الوحدات العقارية المتاحة',
      addLabel: 'إضافة عقار',
      onAdd: onAdd,
      totalCount: totalCount,
      onFilter: onFilter,
      filterLabel: 'فلاتر متقدمة',
      filterBar: filterBar,
      extraAction: extraAction,
    );
  }
}
