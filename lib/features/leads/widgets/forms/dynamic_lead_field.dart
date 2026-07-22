import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/models/form_field_model.dart';
import '../../../../core/di/injection_container.dart' as di;

/// Widget ديناميكي يرسم حقل إدخال مناسب بناءً على FormFieldModel
class DynamicLeadField extends StatelessWidget {
  final FormFieldModel field;
  final dynamic value;
  final void Function(String fieldKey, dynamic newValue) onChanged;
  final bool readOnly;

  const DynamicLeadField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!field.showInForm || !field.isActive) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: _buildInput(context),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (field.inputType) {
      case FormFieldInputType.text:
        return _buildTextField(context, maxLines: 1);
      case FormFieldInputType.textarea:
        return _buildTextField(context, maxLines: 4);
      case FormFieldInputType.number:
        return _buildNumberField(context);
      case FormFieldInputType.date:
        return _buildDateField(context);
      case FormFieldInputType.checkbox:
        return _buildCheckboxField(context);
      case FormFieldInputType.selectStatic:
        return _buildStaticDropdown(context);
      case FormFieldInputType.selectRef:
        return _buildRefDropdown(context);
      case FormFieldInputType.action:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(BuildContext context, {int maxLines = 1}) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: _decoration(),
      validator: field.isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
      onChanged: readOnly ? null : (v) => onChanged(field.fieldKey, v),
    );
  }

  Widget _buildNumberField(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: _decoration(),
      validator: field.isRequired
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
      onChanged: readOnly ? null : (v) {
        final parsed = num.tryParse(v);
        onChanged(field.fieldKey, parsed ?? v);
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    DateTime? currentDate;
    if (value != null && value.toString().isNotEmpty) {
      try { currentDate = DateTime.parse(value.toString()); } catch (_) {}
    }
    return InkWell(
      onTap: readOnly ? null : () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: currentDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(field.fieldKey, picked.toIso8601String());
      },
      child: InputDecorator(
        decoration: _decoration(),
        child: Text(
          currentDate != null
              ? DateFormat('dd/MM/yyyy').format(currentDate)
              : (field.placeholderAr ?? 'اختر تاريخاً'),
          style: TextStyle(color: currentDate != null ? null : Colors.grey, fontSize: 14.sp),
        ),
      ),
    );
  }

  Widget _buildCheckboxField(BuildContext context) {
    final boolValue = value == true || value == 'true' || value == 1;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(field.titleAr + (field.isRequired ? ' *' : ''), style: TextStyle(fontSize: 14.sp)),
          Switch(
            value: boolValue,
            onChanged: readOnly ? null : (v) => onChanged(field.fieldKey, v),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticDropdown(BuildContext context) {
    final currentValue = value?.toString();
    final isValidValue = currentValue != null && field.options.any((o) => o.value == currentValue);
    return DropdownButtonFormField<String>(
      value: isValidValue ? currentValue : null,
      isExpanded: true,
      decoration: _decoration(),
      hint: Text(field.placeholderAr ?? 'اختر...'),
      validator: field.isRequired ? (v) => v == null ? 'هذا الحقل مطلوب' : null : null,
      items: field.options.map((opt) => DropdownMenuItem<String>(value: opt.value, child: Text(opt.label))).toList(),
      onChanged: readOnly ? null : (v) => onChanged(field.fieldKey, v),
    );
  }

  Widget _buildRefDropdown(BuildContext context) {
    if (field.refTable == null) return _buildTextField(context);
    final manager = di.sl<StaticDataManager>();
    final options = manager.getRefTableOptions(field.refTable!);
    final currentValue = value?.toString();
    final isValidValue = currentValue != null && options.any((o) => o.id == currentValue);
    return DropdownButtonFormField<String>(
      value: isValidValue ? currentValue : null,
      isExpanded: true,
      decoration: _decoration(),
      hint: Text(field.placeholderAr ?? 'اختر...'),
      validator: field.isRequired ? (v) => v == null ? 'هذا الحقل مطلوب' : null : null,
      items: options.where((o) => o.isActive || o.id == currentValue)
          .map((opt) => DropdownMenuItem<String>(value: opt.id, child: Text(opt.nameAr))).toList(),
      onChanged: readOnly ? null : (v) => onChanged(field.fieldKey, v),
    );
  }

  InputDecoration _decoration() {
    return InputDecoration(
      labelText: field.titleAr + (field.isRequired ? ' *' : ''),
      hintText: field.placeholderAr,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    );
  }
}

/// Widget للعرض فقط (Read-only) — يُستخدم في صفحة التفاصيل
class DynamicLeadFieldReadOnly extends StatelessWidget {
  final FormFieldModel field;
  final dynamic value;
  final String userRole;

  const DynamicLeadFieldReadOnly({
    super.key,
    required this.field,
    required this.value,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (!field.isActive || !field.isVisibleForRole(userRole)) return const SizedBox.shrink();
    final displayValue = _resolveDisplayValue();
    if (displayValue == null || displayValue.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(field.titleAr,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(displayValue,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  String? _resolveDisplayValue() {
    if (value == null) return null;
    switch (field.inputType) {
      case FormFieldInputType.checkbox:
        return (value == true || value == 'true' || value == 1) ? 'نعم ✓' : 'لا ✗';
      case FormFieldInputType.date:
        try {
          return DateFormat('dd/MM/yyyy').format(DateTime.parse(value.toString()));
        } catch (_) { return value.toString(); }
      case FormFieldInputType.selectStatic:
        try {
          return field.options.firstWhere((o) => o.value == value.toString()).label;
        } catch (_) { return value.toString(); }
      case FormFieldInputType.selectRef:
        if (field.refTable == null) return value.toString();
        try {
          final manager = di.sl<StaticDataManager>();
          return manager.getRefTableOptions(field.refTable!).firstWhere((o) => o.id == value.toString()).nameAr;
        } catch (_) { return value.toString(); }
      default:
        final str = value.toString();
        return str.isEmpty ? null : str;
    }
  }
}
