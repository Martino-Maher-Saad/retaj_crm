import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
class AdminSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final bool status;
  final Function(bool) onStatusChanged;

  const AdminSection({
    super.key,
    required this.controllers,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RetajSectionCard(
      title: 'الإدارة والمالك',
      icon: Icons.admin_panel_settings_outlined,
      iconColor: const Color(0xFFB45309),
      children: [
        // اسم المالك + رقمه في صف واحد
        RetajFieldRow(
          first: RetajTextField(
            controller: controllers['ownerName'],
            label: 'اسم المالك',
          ),
          second: RetajTextField(
            controller: controllers['ownerPhone'],
            label: 'رقم المالك',
            keyboardType: TextInputType.phone,
            forceLtr: true,
          ),
        ),

        // الملاحظات الإدارية — حقل مطاطي
        RetajTextArea(
          controller: controllers['internalNotes']!,
          label: 'ملاحظات إدارية (خاصة)',
          minLines: 3,
          prefixIcon: Icons.sticky_note_2_outlined,
        ),

        // toggle الحالة النشطة
        Container(
          decoration: BoxDecoration(
            color: status
                ? const Color(0xFF2D6A4F).withValues(alpha: 0.06)
                : const Color(0xFFE31E24).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: status
                  ? const Color(0xFF2D6A4F).withValues(alpha: 0.2)
                  : const Color(0xFFE31E24).withValues(alpha: 0.2),
            ),
          ),
          child: SwitchListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
            title: Text(
              status ? 'نشط — يظهر للعملاء' : 'غير نشط — مخفي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: status
                    ? const Color(0xFF2D6A4F)
                    : const Color(0xFFE31E24),
              ),
            ),
            subtitle: Text(
              status ? 'العقار ظاهر في القوائم' : 'العقار مخفي ولا يظهر للمستخدمين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.sp,
                color: const Color(0xFF64748B),
              ),
            ),
            value: status,
            onChanged: onStatusChanged,
            activeColor: const Color(0xFF2D6A4F),
          ),
        ),
      ],
    );
  }
}
