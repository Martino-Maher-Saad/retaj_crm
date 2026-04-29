import 'package:flutter/material.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';

/// حقل عرض بيانات قابل للنسخ والتحديد (Read-Only)
/// يستخدم نفس مكونات الـ NeonTextField ليطابق تصميم الإدخال بالكامل
class LeadCopyableField extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLong;
  final IconData? icon;

  const LeadCopyableField({
    super.key,
    required this.label,
    this.value,
    this.isLong = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final String displayText = value?.isNotEmpty == true ? value! : '---';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RetajCopyableDisplay(
        label: label,
        value: displayText,
        leadingIcon: icon,
      ),
    );
  }
}
