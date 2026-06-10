import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';

/// شاشة الحالة الفارغة — تظهر عند عدم وجود عملاء أو نتائج
class LeadEmptyState extends StatelessWidget {
  final String? message;
  final IconData? icon;

  const LeadEmptyState({
    super.key,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
          ],
          Text(message ?? "لا يوجد عملاء حالياً", style: AppTextStyles.tableCellSub),
        ],
      ),
    );
  }
}
