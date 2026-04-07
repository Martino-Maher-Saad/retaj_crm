import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';

/// حقل نص نيون ذكي — يدعم:
/// - كشف اللغة تلقائياً: عربي → RTL | إنجليزي → LTR | أرقام → LTR دائماً
/// - التمدد التلقائي عمودياً مع الكتابة (maxLines: null)
/// - Neon Blue Glow عند التركيز
/// - النسخ/اللصق/تحديد النص والتحرك بالـ cursor بسهولة عبر TextFormField المدمج
class NeonTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool readOnly;
  final bool filled;
  final Color? fillColor;
  final int? maxLines;  // null = تمدد تلقائي
  final int minLines;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? initialValue;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  // لو true يُجبر على LTR دائماً (للأرقام والإيميل ونحوه)
  final bool forceLtr;

  const NeonTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffix,
    this.readOnly = false,
    this.filled = true,
    this.fillColor,
    this.maxLines = 1,  // افتراضي سطر واحد، null = تمدد تلقائي
    this.minLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.initialValue,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.forceLtr = false,
  });

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  /// الاتجاه الافتراضي: RTL (عربي) دائماً إلا لو forceLtr أو تم كشف إنجليزي
  TextDirection _textDirection = TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    // لو forceLtr (أرقام / إيميل) → LTR دائماً
    if (widget.forceLtr) {
      _textDirection = TextDirection.ltr;
    } else {
      // تحديد الاتجاه من النص الأولي
      final initial = widget.controller?.text ?? widget.initialValue ?? '';
      if (initial.isNotEmpty) {
        _textDirection = _detectDirection(initial);
      }
      // الافتراضي RTL لأن التطبيق عربي
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  /// كشف اتجاه النص بناءً على أول حرف غير فراغ
  TextDirection _detectDirection(String text) {
    if (widget.forceLtr) return TextDirection.ltr;
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final codeUnit = trimmed.codeUnitAt(0);
    // أرقام → LTR
    if (codeUnit >= 0x0030 && codeUnit <= 0x0039) return TextDirection.ltr;
    // عربي
    final isArabic = (codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
        (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
        (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
        (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  TextAlign get _textAlign =>
      _textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;

  /// نوع لوحة المفاتيح: إن كان متعدد الأسطر → multiline، وإلا من الخارج
  TextInputType get _resolvedKeyboardType {
    if (widget.obscureText) return TextInputType.visiblePassword;
    if (widget.keyboardType != null) return widget.keyboardType!;
    // لو maxLines null أو > 1 → نفعِّل multiline
    if (widget.maxLines == null || (widget.maxLines ?? 1) > 1) {
      return TextInputType.multiline;
    }
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.r8),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF2E3192).withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        initialValue:
            widget.controller == null ? widget.initialValue : null,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: _resolvedKeyboardType,

        // maxLines: null = تمدد تلقائي بلا حد
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.obscureText ? 1 : widget.minLines,

        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction ??
            (widget.maxLines == null ? TextInputAction.newline : TextInputAction.done),

        // الاتجاه والمحاذاة بناءً على كشف اللغة
        textAlign: _textAlign,
        textAlignVertical: TextAlignVertical.top,
        textDirection: _textDirection,

        inputFormatters: widget.inputFormatters,
        style: AppTextStyles.inputText,
        validator: widget.validator,

        // دعم عمليات النسخ/القص/اللصق والتحديد والـ cursor — مدمج في TextFormField
        enableInteractiveSelection: true,
        selectionControls: MaterialTextSelectionControls(),

        onChanged: (value) {
          if (!widget.forceLtr) {
            final newDir = _detectDirection(value);
            if (newDir != _textDirection) {
              setState(() => _textDirection = newDir);
            }
          }
          widget.onChanged?.call(value);
        },
        onFieldSubmitted: widget.onSubmitted,

        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: AppTextStyles.tableCellSub.copyWith(
            color: AppColors.textDisabled,
          ),
          hintTextDirection: TextDirection.rtl, // hint دائماً عربي
          labelStyle: AppTextStyles.inputLabel.copyWith(
            color: _isFocused
                ? AppColors.brandPrimary
                : AppColors.textSecondary,
          ),
          floatingLabelStyle: AppTextStyles.inputLabel.copyWith(
            color: AppColors.brandPrimary,
            fontSize: 12.sp,
          ),
          filled: widget.filled,
          fillColor: widget.fillColor ?? Colors.white,
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  size: 20.sp,
                  color: _isFocused
                      ? AppColors.brandPrimary
                      : AppColors.textSecondary,
                )
              : null,
          suffix: widget.suffix,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: widget.maxLines == null || (widget.maxLines ?? 1) > 1
                ? 16.h
                : 14.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
            borderSide:
                BorderSide(color: AppColors.brandPrimary, width: 2.w),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
            borderSide:
                const BorderSide(color: AppColors.brandAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.r8),
            borderSide:
                const BorderSide(color: AppColors.brandAccent, width: 2),
          ),
        ),
      ),
    );
  }
}
