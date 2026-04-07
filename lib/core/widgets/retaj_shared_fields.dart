import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ══════════════════════════════════════════════════════════════
//  RETAJ SHARED FIELDS — Neon-Minimalist Field Library
//  ⚠️ لا تعدّل أي منطق أعمال (controllers / onChanged / validators)
//     هذه المكتبة للـ UI/UX فقط.
// ══════════════════════════════════════════════════════════════

// ─── ألوان الـ Neon Glow ───────────────────────────────────────
const Color _kNeonBlue = Color(0xFF2E3192);
const Color _kBorderDefault = Color(0xFFE2E8F0);
const Color _kBorderFocused = Color(0xFF2E3192);
const Color _kFillColor = Colors.white;
const Color _kLabelColor = Color(0xFF64748B);
const Color _kTextColor = Color(0xFF1A1A2E);
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
        fontSize: 13.sp,
        color: isFocused ? _kNeonBlue : _kLabelColor,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 11.sp,
        color: _kNeonBlue,
        fontWeight: FontWeight.w600,
      ),
      hintTextDirection: TextDirection.rtl,
      filled: true,
      fillColor: _kFillColor,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              size: 18.sp,
              color: isFocused ? _kNeonBlue : _kLabelColor)
          : null,
      suffix: suffix,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: isMultiline ? 14.h : 13.h,
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
        borderSide: BorderSide(color: _kBorderFocused, width: 1.8.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE31E24)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_kRadius),
        borderSide: const BorderSide(color: Color(0xFFE31E24), width: 1.8),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: (iconColor ?? _kNeonBlue).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(leadingIcon, size: 16.sp,
                  color: iconColor ?? _kNeonBlue),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.sp,
                    color: _kLabelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Directionality(
                  textDirection: isNumeric
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  child: SelectableText(
                    value.isEmpty ? '—' : value,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14.sp,
                      color: value.isEmpty ? _kLabelColor : _kTextColor,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (value.isNotEmpty)
            IconButton(
              icon: Icon(Icons.copy_rounded,
                  size: 16.sp, color: _kLabelColor),
              tooltip: 'نسخ',
              onPressed: () => _copy(context),
              padding: EdgeInsets.all(6.r),
              constraints: const BoxConstraints(),
              splashRadius: 20,
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
