import 'package:flutter/material.dart';
import '../constants/app_colors.dart';



class CustomTextFormField extends StatefulWidget {

  final TextEditingController controller;
  final TextStyle? textStyle;
  final int? maxLines;
  final bool obscureText;
  final String? Function(String?) validator;

  final String labelText;
  final TextStyle? labelStyle;
  final Color? filledColor;

  final IconData? prefixIcon;
  final Color? prefixIconColor;
  final double? prefixIconSize;

  final IconData? suffixIcon;
  final Color? suffixIconColor;
  final double? suffixIconSize;
  final VoidCallback? onTabSuffix;

  final double? borderRad;
  final Color enabledBorderColor;
  final Color focusedBorderColor;


  const CustomTextFormField({
    super.key,
    required this.labelText,
    required this.controller,
    required this.obscureText,
    required this.validator,
    required this.enabledBorderColor,
    required this.focusedBorderColor,
    this.filledColor,
    this.textStyle,
    this.maxLines,
    this.prefixIcon,
    this.prefixIconColor,
    this.prefixIconSize,
    this.suffixIcon,
    this.suffixIconColor,
    this.suffixIconSize,
    this.borderRad,
    this.labelStyle,
    this.onTabSuffix,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(

      controller: widget.controller,
      style: widget.textStyle,
      maxLines: widget.maxLines ?? 1,
      obscureText: widget.obscureText,
      validator: widget.validator,
      textAlign: TextAlign.start,

      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: widget.labelStyle,
        filled: true,
        fillColor: widget.filledColor ?? AppColors.white,

        prefixIcon: widget.prefixIcon == null ? null : Icon(
          widget.prefixIcon,
          size: widget.prefixIconSize,
          color: widget.prefixIconColor,
        ),

        suffixIcon: widget.suffixIcon == null ? null : GestureDetector(
          onTap: widget.onTabSuffix,
          child: Icon(
            widget.suffixIcon,
            size: widget.suffixIconSize,
            color: widget.suffixIconColor,
          ),
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRad ?? 14),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRad ?? 14),
          borderSide: BorderSide(color: widget.enabledBorderColor, width: 2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRad ?? 14),
          borderSide: BorderSide(color: widget.focusedBorderColor, width: 2),
        ),
      ),
    );
  }
}
