import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

/// قائمة منسدلة نيون احترافية — تدعم:
/// - Hover effect على الخيارات (150ms)
/// - Neon border عند التركيز
/// - لا تغيير على أي منطق (onChanged يمر مباشرة)
class NeonDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool isExpanded;

  const NeonDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.isExpanded = true,
  });

  @override
  State<NeonDropdown<T>> createState() => _NeonDropdownState<T>();
}

class _NeonDropdownState<T> extends State<NeonDropdown<T>> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.r8),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF2E3192).withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: DropdownButtonFormField<T>(
          value: widget.value,
          isExpanded: widget.isExpanded,
          validator: widget.validator,
          onChanged: widget.onChanged,
          style: AppTextStyles.inputText,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _isFocused ? AppColors.brandPrimary : AppColors.textSecondary,
            size: 22.sp,
          ),
          dropdownColor: Colors.white,
          menuMaxHeight: 300.h,
          items: widget.items,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            hintStyle: AppTextStyles.tableCellSub,
            labelStyle: AppTextStyles.inputLabel.copyWith(
              color: _isFocused ? AppColors.brandPrimary : AppColors.textSecondary,
            ),
            floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
              color: AppColors.brandPrimary,
              fontSize: 12.sp,
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: 20.sp,
                    color: _isFocused ? AppColors.brandPrimary : AppColors.textSecondary,
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: BorderSide(color: AppColors.brandPrimary, width: 2.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: AppColors.brandAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.r8),
              borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
