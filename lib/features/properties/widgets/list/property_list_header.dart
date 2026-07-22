import 'package:flutter/material.dart';
import '../../../../core/widgets/retaj_page_header.dart';

/// رأس قائمة العقارات — يستخدم RetajPageHeader الموحّد
class PropertyListHeader extends StatelessWidget {
  final int totalCount;
  final VoidCallback onAdd;
  final VoidCallback? onFilter;

  const PropertyListHeader({
    super.key,
    required this.totalCount,
    required this.onAdd,
    this.onFilter,
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
      filterLabel: 'فلاتر',
    );
  }
}
