import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';

class LeadFieldBuilders {
  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
          child: Text(label, style: AppTextStyles.inputLabel),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.brandPrimary, size: 20.sp),
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: EdgeInsets.all(16.w),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: (val) => isRequired && (val == null || val.isEmpty) ? "هذا الحقل مطلوب" : null,
        ),
      ],
    );
  }

  static Widget buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h, right: 4.w),
          child: Text(label, style: AppTextStyles.inputLabel),
        ),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.brandPrimary),
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: AppColors.brandPrimary, size: 20.sp) : null,
            filled: true,
            fillColor: AppColors.bgSurface,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  static Widget buildCircularAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20.sp),
      ),
    );
  }
}
