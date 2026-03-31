import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../properties/widgets/property_form_card.dart';
import '../../widgets/lead_field_builders.dart';


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
    return PropertyFormCard(
      title: "المعلومات الأساسية",
      icon: Icons.person_outline,
      child: Column(
        children: [
          LeadFieldBuilders.buildTextField(
            controller: nameController,
            label: "اسم العميل بالكامل *",
            icon: Icons.person_add_alt_1_outlined,
            isRequired: true,
          ),
          SizedBox(height: 16.h),
          const Divider(),
          SizedBox(height: 8.h),
          ..._buildPhoneFields(),
        ],
      ),
    );
  }

  List<Widget> _buildPhoneFields() {
    return phoneControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LeadFieldBuilders.buildTextField(
                controller: entry.value,
                label: idx == 0 ? "أرقام التواصل *" : "رقم إضافي",
                icon: Icons.phone_android_rounded,
                isRequired: idx == 0,
                keyboardType: TextInputType.phone,
              ),
            ),
            SizedBox(width: 8.w),
            if (idx == 0)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: LeadFieldBuilders.buildCircularAction(
                  Icons.add,
                  AppColors.success,
                  onAddPhone,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: LeadFieldBuilders.buildCircularAction(
                  Icons.remove,
                  AppColors.brandAccent,
                  () => onRemovePhone(idx),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }
}
