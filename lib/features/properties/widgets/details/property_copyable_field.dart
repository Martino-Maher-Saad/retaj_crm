import 'package:flutter/material.dart';
import '../../../../core/widgets/neon_text_field.dart';

/// حقل عرض بيانات قابل للنسخ والتحديد (Read-Only)
/// يستخدم نفس مكونات الـ NeonTextField ليطابق تصميم الإدخال بالكامل
class PropertyCopyableField extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLong;
  final IconData? icon;

  const PropertyCopyableField({
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
      child: NeonTextField(
        label: label,
        initialValue: displayText,
        readOnly: true,
        // تمدد تلقائي في كل الأحوال لتسهيل العرض
        maxLines: null,
        minLines: isLong ? 3 : 1,
        prefixIcon: icon,
        // forceLtr if numbers? Let NeonTextField detect automatically
      ),
    );
  }
}
