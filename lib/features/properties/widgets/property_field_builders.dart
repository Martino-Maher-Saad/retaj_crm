import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/number_formatter.dart';

class PropertyFieldBuilders {
  static Widget buildField(
    TextEditingController ctrl,
    String label, {
    bool num = false,
    bool long = false,
    bool req = false,
    bool isPrice = false,
    bool hasStepper = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.inputLabel),
          SizedBox(height: AppConstants.p8),
          Row(
            children: [
              if (hasStepper)
                _stepperBtn(Icons.remove, () {
                  int val = int.tryParse(ctrl.text) ?? 0;
                  if (val > 0) ctrl.text = (val - 1).toString();
                }),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  maxLines: long ? 3 : 1,
                  keyboardType: num ? TextInputType.number : TextInputType.text,
                  inputFormatters: [
                    if (num) FilteringTextInputFormatter.digitsOnly,
                    if (isPrice) NumberFormatter(),
                  ],
                  style: AppTextStyles.inputText,
                  decoration: InputDecoration(
                    hintText: label,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: AppConstants.p16, vertical: AppConstants.p16),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.r8),
                      borderSide: const BorderSide(color: AppColors.borderStrong),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.r8),
                      borderSide:
                          const BorderSide(color: AppColors.brandPrimary, width: 2),
                    ),
                  ),
                  validator: (v) =>
                      (req && (v == null || v.isEmpty)) ? "حقل مطلوب" : null,
                ),
              ),
              if (hasStepper)
                _stepperBtn(Icons.add, () {
                  int val = int.tryParse(ctrl.text) ?? 0;
                  ctrl.text = (val + 1).toString();
                }),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppConstants.p4),
        padding: EdgeInsets.all(AppConstants.p8),
        decoration: BoxDecoration(
          color: AppColors.brandPrimarySurface,
          borderRadius: BorderRadius.circular(AppConstants.r8),
        ),
        child:
            Icon(icon, size: AppConstants.iconSm, color: AppColors.brandPrimary),
      ),
    );
  }

  static Widget buildJsonDrop({
    required String label,
    required List<dynamic> items,
    required String? val,
    required Function(String?) onChg,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: DropdownButtonFormField<String>(
          value: val,
          onChanged: onChg,
          decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
          items: items
              .map((i) => DropdownMenuItem(
                  value: i.id.toString(), child: Text(i.nameAr)))
              .toList(),
        ),
      );

  static Widget buildFixedDrop({
    required String label,
    required List<String> items,
    required String? val,
    required Function(String?) onChg,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: DropdownButtonFormField<String>(
          value: items.contains(val) ? val : null,
          onChanged: onChg,
          decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
          items: items
              .map((i) =>
                  DropdownMenuItem(value: i, child: Text(i.toUpperCase())))
              .toList(),
        ),
      );

  static Widget buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) =>
      ListTile(
        title: Text(selectedDate == null
            ? label
            : DateFormat('yyyy-MM-dd').format(selectedDate)),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2040));
          if (d != null) onDateSelected(d);
        },
      );
}
