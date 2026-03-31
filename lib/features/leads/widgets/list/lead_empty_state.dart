import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

/// شاشة الحالة الفارغة — تظهر عند عدم وجود عملاء أو نتائج
class LeadEmptyState extends StatelessWidget {
  const LeadEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("لا يوجد عملاء حالياً", style: AppTextStyles.tableCellSub),
    );
  }
}
