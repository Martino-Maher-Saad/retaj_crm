import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/neon_text_field.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';

class ClientBasicSection extends StatelessWidget {
  final TextEditingController nameController;
  final List<TextEditingController> phoneControllers;
  final VoidCallback onAddPhone;
  final Function(int) onRemovePhone;

  const ClientBasicSection({
    super.key,
    required this.nameController,
    required this.phoneControllers,
    required this.onAddPhone,
    required this.onRemovePhone,
  });

  @override
  Widget build(BuildContext context) {
    return RetajSectionCard(
      title: 'بيانات العميل الأساسية',
      icon: Icons.person_outline,
      iconColor: const Color(0xFF2E3192),
      children: [
        // اسم العميل — صف كامل (نص مهم)
        NeonTextField(
          controller: nameController,
          label: 'اسم العميل بالكامل',
          prefixIcon: Icons.person_add_alt_1_outlined,
          validator: (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
        ),

        // ─── حقول الهاتف الديناميكية ───
        ..._buildPhoneFields(context),
      ],
    );
  }

  List<Widget> _buildPhoneFields(BuildContext context) {
    return phoneControllers.asMap().entries.map((entry) {
      final int idx = entry.key;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: NeonTextField(
              controller: entry.value,
              label: idx == 0 ? 'رقم الهاتف الأساسي' : 'رقم إضافي ${idx + 1}',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              forceLtr: true,
              validator: idx == 0
                  ? (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null
                  : null,
            ),
          ),
          SizedBox(width: 8.w),
          _circularAction(
            icon: idx == 0 ? Icons.add_rounded : Icons.remove_rounded,
            color: idx == 0 ? AppColors.success : AppColors.brandAccent,
            onTap: idx == 0 ? onAddPhone : () => onRemovePhone(idx),
          ),
        ],
      );
    }).toList();
  }

  Widget _circularAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.r8),
      child: Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.r8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: color, size: 18.sp),
      ),
    );
  }
}
