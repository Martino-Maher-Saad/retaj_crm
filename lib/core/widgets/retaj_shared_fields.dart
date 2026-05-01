import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
// ══════════════════════════════════════════════════════════════
//  RETAJ SHARED FIELDS — Neon-Minimalist Field Library
//  ⚠️ لا تعدّل أي منطق أعمال (controllers / onChanged / validators)
//     هذه المكتبة للـ UI/UX فقط.
// ══════════════════════════════════════════════════════════════

// ─── ألوان الـ Neon Glow ───────────────────────────────────────
const Color _kNeonBlue = AppColors.brandPrimary;
const Color _kBorderDefault = AppColors.borderSubtle;
const Color _kBorderFocused = AppColors.brandPrimary;
const Color _kFillColor = AppColors.bgSurface;
const Color _kLabelColor = AppColors.textSecondary;
const Color _kTextColor = AppColors.textPrimary;
const double _kRadius = 12;

// ─── BoxShadow عند التركيز (Neon Glow) ────────────────────────
BoxDecoration _glowDecoration(bool isFocused) => BoxDecoration(
      borderRadius: BorderRadius.circular(_kRadius),
      boxShadow: isFocused
          ? [
              BoxShadow(
                color: _kNeonBlue.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : [],
    );

// ─── InputDecoration مشتركة ────────────────────────────────────
InputDecoration _buildDecoration({
  required String label,
  required bool isFocused,
  bool isRequired = false,
  IconData? prefixIcon,
  Widget? suffix,
  bool isMultiline = false,
}) =>
    InputDecoration(
      labelText: isRequired ? '$label *' : label,
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 22.sp,
        color: isFocused ? _kNeonBlue : _kLabelColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 16.sp,
        color: _kNeonBlue,
        fontWeight: FontWeight.w600,
      ),
      hintTextDirection: TextDirection.rtl,
      filled: true,
      fillColor: _kFillColor,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              size: 28.sp,
              color: isFocused ? _kNeonBlue : _kLabelColor)
          : null,
      suffix: suffix,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 22.w,
        vertical: isMultiline ? 22.h : 20.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kBorderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: _kBorderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: BorderSide(color: _kBorderFocused, width: 2.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE31E24)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE31E24), width: 2),
      ),
    );

// ══════════════════════════════════════════════════════════════
//  1. RetajTextArea — الحقل النصي المطاطي (وصف / ملاحظات)
// ══════════════════════════════════════════════════════════════
class RetajTextArea extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final bool isRequired;
  final int minLines;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? prefixIcon;
  final FocusNode? focusNode;
  final bool readOnly;
  final String? initialValue;

  const RetajTextArea({
    super.key,
    this.controller,
    required this.label,
    this.initialValue,
    this.isRequired = false,
    this.minLines = 3,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.focusNode,
    this.readOnly = false,
  }) : assert(controller != null || initialValue != null, 'Provide either a controller or initialValue');

  @override
  State<RetajTextArea> createState() => _RetajTextAreaState();
}

class _RetajTextAreaState extends State<RetajTextArea> {
  late FocusNode _focus;
  bool _isFocused = false;
  TextDirection _dir = TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() => _isFocused = _focus.hasFocus);
    });
    final t = widget.controller?.text ?? widget.initialValue ?? '';
    if (t.isNotEmpty) _dir = _detect(t);
  }

  TextDirection _detect(String s) {
    final c = s.trimLeft().isEmpty ? 0 : s.trimLeft().codeUnitAt(0);
    if (c >= 0x0600 && c <= 0x06FF) return TextDirection.rtl;
    if (c >= 0x0030 && c <= 0x0039) return TextDirection.ltr;
    return TextDirection.rtl;
  }

  @override
  void dispose() {
    _focus.removeListener(() {});
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: _glowDecoration(_isFocused),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.controller == null ? widget.initialValue : null,
        focusNode: _focus,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: widget.minLines,
        maxLines: null,
        readOnly: widget.readOnly,
        textDirection: _dir,
        textAlign: _dir == TextDirection.rtl ? TextAlign.right : TextAlign.left,
        textAlignVertical: TextAlignVertical.top,
        enableInteractiveSelection: true,
        selectionControls: MaterialTextSelectionControls(),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14.sp,
          color: _kTextColor,
          height: 1.5,
        ),
        validator: widget.validator ??
            (widget.isRequired
                ? (v) => (v == null || v.isEmpty) ? 'حقل مطلوب' : null
                : null),
        onChanged: (v) {
          final d = _detect(v);
          if (d != _dir && mounted) setState(() => _dir = d);
          widget.onChanged?.call(v);
        },
        decoration: _buildDecoration(
          label: widget.label,
          isFocused: _isFocused,
          isRequired: widget.isRequired,
          prefixIcon: widget.prefixIcon,
          isMultiline: true,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  2. RetajNumberStepper — حقل الأرقام مع أسهم ±
// ══════════════════════════════════════════════════════════════
class RetajNumberStepper extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final int min;
  final int max;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const RetajNumberStepper({
    super.key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.min = 0,
    this.max = 9999,
    this.validator,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  State<RetajNumberStepper> createState() => _RetajNumberStepperState();
}

class _RetajNumberStepperState extends State<RetajNumberStepper> {
  late FocusNode _focus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() => _isFocused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final current = int.tryParse(widget.controller.text) ?? 0;
    final next = (current + delta).clamp(widget.min, widget.max);
    widget.controller.text = next.toString();
    // نُطلع الـ listener يدوياً لأن setText لا يُطلق onChanged
    widget.onChanged?.call(widget.controller.text);
  }

  Widget _arrowBtn(IconData icon, int delta) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _step(delta),
          borderRadius: BorderRadius.circular(6.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            child: Icon(
              icon,
              size: 14.sp,
              color: _kNeonBlue,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: _glowDecoration(_isFocused),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: _kTextColor,
          ),
          enableInteractiveSelection: true,
          inputFormatters: widget.inputFormatters ??
              [FilteringTextInputFormatter.digitsOnly],
          validator: widget.validator ??
              (widget.isRequired
                  ? (v) => (v == null || v.isEmpty) ? 'مطلوب' : null
                  : null),
          onChanged: widget.onChanged,
          // نستخدم suffixIcon لأن التطبيق RTL والـ suffix يظهر يمين
          decoration: _buildDecoration(
            label: widget.label,
            isFocused: _isFocused,
            isRequired: widget.isRequired,
            suffix: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _arrowBtn(Icons.keyboard_arrow_up_rounded, 1),
                _arrowBtn(Icons.keyboard_arrow_down_rounded, -1),
              ],
            ),
          ).copyWith(
            // الـ label يظهر بالعربي حتى في حالة LTR
            hintTextDirection: TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  3. RetajCopyableDisplay — حقل العرض القابل للنسخ
// ══════════════════════════════════════════════════════════════
class RetajCopyableDisplay extends StatelessWidget {
  final String label;
  final String value;
  final bool isNumeric; // أرقام → LTR
  final IconData? leadingIcon;
  final Color? iconColor;

  const RetajCopyableDisplay({
    super.key,
    required this.label,
    required this.value,
    this.isNumeric = false,
    this.leadingIcon,
    this.iconColor,
  });

  TextDirection _detectDirection(String text) {
    if (isNumeric) return TextDirection.ltr;
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final codeUnit = trimmed.codeUnitAt(0);
    if (codeUnit >= 0x0030 && codeUnit <= 0x0039) return TextDirection.ltr;
    final isArabic = (codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
        (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
        (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
        (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  void _copy(BuildContext ctx) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'تم النسخ: $value',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
          ],
        ),
        backgroundColor: _kNeonBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kRadius),
        border: Border.all(color: _kBorderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: (iconColor ?? _kNeonBlue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(leadingIcon, size: 28.sp,
                  color: iconColor ?? _kNeonBlue),
            ),
            SizedBox(width: 14.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    color: _kLabelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Directionality(
                  textDirection: _detectDirection(value),
                  child: Container(
                    width: double.infinity,
                    alignment: _detectDirection(value) == TextDirection.rtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: SelectableText(
                      value.isEmpty ? '—' : value,
                      textAlign: _detectDirection(value) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22.sp,
                        color: value.isEmpty ? _kLabelColor : _kTextColor,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (value.isNotEmpty)
            IconButton(
              icon: Icon(Icons.copy_rounded,
                  size: 22.sp, color: _kLabelColor),
              tooltip: 'نسخ',
              onPressed: () => _copy(context),
              padding: EdgeInsets.all(8.r),
              constraints: const BoxConstraints(),
              splashRadius: 24,
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  4. RetajFieldRow — يضع حقلين في نفس الصف بمسافة بينهما
// ══════════════════════════════════════════════════════════════
class RetajFieldRow extends StatelessWidget {
  final Widget first;
  final Widget second;
  final double spacing;

  const RetajFieldRow({
    super.key,
    required this.first,
    required this.second,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        SizedBox(width: spacing.w),
        Expanded(child: second),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  5. RetajSectionCard — بطاقة تفصل بين أقسام النموذج
// ══════════════════════════════════════════════════════════════
class RetajSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const RetajSectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? _kNeonBlue;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _kBorderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── رأس القسم ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16.sp, color: color),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // ─── المحتوى ───
          Padding(
            padding: padding ?? EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spaced(children),
            ),
          ),
        ],
      ),
    );
  }

  /// إضافة مسافة عمودية بين الحقول تلقائياً
  List<Widget> _spaced(List<Widget> widgets) {
    if (widgets.isEmpty) return [];
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) result.add(SizedBox(height: 12.h));
    }
    return result;
  }
}

// ══════════════════════════════════════════════════════════════
//  6. RetajTextField — حقل نص ذكي بديل لـ NeonTextField
// ══════════════════════════════════════════════════════════════
class RetajTextField extends StatefulWidget {
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
  final int? maxLines;  
  final int minLines;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? initialValue;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool forceLtr;

  const RetajTextField({
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
    this.maxLines = 1,
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
  State<RetajTextField> createState() => _RetajTextFieldState();
}

class _RetajTextFieldState extends State<RetajTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  TextDirection _textDirection = TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    if (widget.forceLtr) {
      _textDirection = TextDirection.ltr;
    } else {
      final initial = widget.controller?.text ?? widget.initialValue ?? '';
      if (initial.isNotEmpty) {
        _textDirection = _detectDirection(initial);
      }
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

  TextDirection _detectDirection(String text) {
    if (widget.forceLtr) return TextDirection.ltr;
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return TextDirection.rtl;
    final codeUnit = trimmed.codeUnitAt(0);
    if (codeUnit >= 0x0030 && codeUnit <= 0x0039) return TextDirection.ltr;
    final isArabic = (codeUnit >= 0x0600 && codeUnit <= 0x06FF) ||
        (codeUnit >= 0x0750 && codeUnit <= 0x077F) ||
        (codeUnit >= 0xFB50 && codeUnit <= 0xFDFF) ||
        (codeUnit >= 0xFE70 && codeUnit <= 0xFEFF);
    return isArabic ? TextDirection.rtl : TextDirection.ltr;
  }

  TextAlign get _textAlign =>
      _textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left;

  TextInputType get _resolvedKeyboardType {
    if (widget.obscureText) return TextInputType.visiblePassword;
    if (widget.keyboardType != null) return widget.keyboardType!;
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
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        initialValue: widget.controller == null ? widget.initialValue : null,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: _resolvedKeyboardType,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.obscureText ? 1 : widget.minLines,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction ??
            (widget.maxLines == null ? TextInputAction.newline : TextInputAction.done),
        textAlign: _textAlign,
        textAlignVertical: TextAlignVertical.top,
        textDirection: _textDirection,
        inputFormatters: widget.inputFormatters,
        style: AppTextStyles.inputText,
        validator: widget.validator,
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
          hintTextDirection: TextDirection.rtl,
          labelStyle: AppTextStyles.inputLabel.copyWith(
            color: _isFocused ? AppColors.brandPrimary : AppColors.textSecondary,
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
                  color: _isFocused ? AppColors.brandPrimary : AppColors.textSecondary,
                )
              : null,
          suffix: widget.suffix,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: widget.maxLines == null || (widget.maxLines ?? 1) > 1 ? 16.h : 14.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: AppColors.brandPrimary, width: 2.w),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.borderSubtle),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.brandAccent, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  7. RetajDropdown — قائمة منسدلة
// ══════════════════════════════════════════════════════════════
class RetajDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final String? Function(T?)? validator;
  final bool isExpanded;

  const RetajDropdown({
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
  State<RetajDropdown<T>> createState() => _RetajDropdownState<T>();
}

class _RetajDropdownState<T> extends State<RetajDropdown<T>> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // توحيد شكل النص داخل خيارات الـ dropdown (القيم داخل القائمة)
    final themedItems = widget.items
        .map(
          (item) => DropdownMenuItem<T>(
            value: item.value,
            enabled: item.enabled,
            // DefaultTextStyle لضمان font/weight موحّد عبر المشروع
            child: DefaultTextStyle.merge(
              style: AppTextStyles.inputText,
              child: item.child,
            ),
          ),
        )
        .toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.2),
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
          items: themedItems,
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
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.borderSubtle, width: 1.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.brandPrimary, width: 2.w),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.brandAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  8. RetajDatePicker — منتقي التاريخ
// ══════════════════════════════════════════════════════════════
class RetajDatePicker extends StatelessWidget {
  final BuildContext context;
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const RetajDatePicker({
    super.key,
    required this.context,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
        leading: Icon(
          Icons.calendar_today_outlined,
          color: AppColors.brandPrimary,
          size: 20.sp,
        ),
        title: Text(
          selectedDate == null
              ? label
              : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
          style: selectedDate == null
              ? AppTextStyles.tableCellSub
              : AppTextStyles.inputText,
        ),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
          );
          if (d != null) onDateSelected(d);
        },
      ),
    );
  }
}
