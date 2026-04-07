import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';

/// زر مخصص احترافي مع تأثير Hover + Neon Glow
/// لا تغيير على منطق onTap — التعديل على التصميم فقط
class CustomButton extends StatefulWidget {
  final bool isCenter;
  final double? buttonWidth;
  final double? buttonHeight;
  final Color? buttonColor;
  final double? buttonBorderRad;
  final Color? buttonBorderColor;
  final double? borderWidth;
  final Widget? icon;
  final String title;
  final VoidCallback? onTap;
  final double? titleSize;
  final Color? titleColor;
  final FontWeight? titleWeight;

  const CustomButton({
    super.key,
    required this.isCenter,
    required this.title,
    this.onTap,
    this.titleSize,
    this.titleColor,
    this.icon,
    this.buttonWidth,
    this.buttonHeight,
    this.buttonColor,
    this.buttonBorderRad,
    this.buttonBorderColor,
    this.borderWidth,
    this.titleWeight,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.buttonColor ?? AppColors.brandPrimary;
    final double radius = widget.buttonBorderRad ?? AppConstants.r8;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.buttonHeight ?? 50.h,
        width: widget.buttonWidth ?? double.infinity,
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.01))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isHovering
              ? (bgColor == Colors.white
                  ? bgColor
                  : Color.lerp(bgColor, Colors.white, 0.12))
              : bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: widget.buttonBorderColor ??
                (bgColor == Colors.white
                    ? AppColors.brandPrimary
                    : Colors.transparent),
            width: widget.borderWidth ?? 1.5.w,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            mainAxisAlignment: widget.isCenter
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              if (widget.icon != null) ...[
                SizedBox(width: 12.w),
                widget.icon!,
                SizedBox(width: 10.w),
              ],
              Text(
                widget.title,
                style: AppTextStyles.buttonLarge.copyWith(
                  color: widget.titleColor ?? Colors.white,
                  fontSize: widget.titleSize?.sp ?? 15.sp,
                  fontWeight: widget.titleWeight ?? FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}