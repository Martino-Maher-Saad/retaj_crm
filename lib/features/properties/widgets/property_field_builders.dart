import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/neon_text_field.dart';
import '../../../core/widgets/neon_dropdown.dart';

/// مبنيو حقول نموذج العقار — محوّل لاستخدام NeonTextField + NeonDropdown
class PropertyFieldBuilders {
  /// حقل نص عام (نصي / رقمي / سعر / وصف / stepper)
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
      child: hasStepper
          // ─── Counter Stepper ───
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                border: Border.all(color: AppColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppConstants.r8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _stepperBtn(Icons.remove, () {
                    int val = int.tryParse(ctrl.text) ?? 0;
                    if (val > 0) ctrl.text = (val - 1).toString();
                  }),
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.inputLabel.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: ctrl,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTextStyles.inputText.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                  _stepperBtn(Icons.add, () {
                    int val = int.tryParse(ctrl.text) ?? 0;
                    ctrl.text = (val + 1).toString();
                  }),
                ],
              ),
            )
          // ─── NeonTextField ───
          : NeonTextField(
              controller: ctrl,
              hint: label,
              maxLines: long ? null : 1,
              minLines: long ? 3 : 1,
              // الأرقام والأسعار → LTR دائماً
              forceLtr: num || isPrice,
              keyboardType: num || isPrice
                  ? TextInputType.number
                  : (long ? TextInputType.multiline : TextInputType.text),
              inputFormatters: [
                if (num && !isPrice) FilteringTextInputFormatter.digitsOnly,
                if (isPrice) ThousandsFormatter(),
              ],
              validator: (v) =>
                  (req && (v == null || v.isEmpty)) ? 'حقل مطلوب' : null,
            ),
    );
  }

  static Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Icon(icon, size: 20.sp, color: AppColors.brandPrimary),
      ),
    );
  }

  /// قائمة منسدلة من JSON data (e.g., المدن / الأحياء)
  static Widget buildJsonDrop({
    required String label,
    required List<dynamic> items,
    required String? val,
    required Function(String?) onChg,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: NeonDropdown<String>(
          label: label,
          value: val,
          onChanged: onChg,
          items: items
              .map((i) => DropdownMenuItem<String>(
                    value: i.id.toString(),
                    child: Text(i.nameAr),
                  ))
              .toList(),
        ),
      );

  /// قائمة منسدلة من قائمة نصية ثابتة (e.g., نوع العقار)
  static Widget buildFixedDrop({
    required String label,
    required List<String> items,
    required String? val,
    required Function(String?) onChg,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: NeonDropdown<String>(
          label: label,
          value: items.contains(val) ? val : null,
          onChanged: onChg,
          items: items
              .map((i) => DropdownMenuItem<String>(
                    value: i,
                    child: Text(i),
                  ))
              .toList(),
        ),
      );

  /// منتقي التاريخ (منطق onDateSelected لا يتغير)
  static Widget buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.r8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: ListTile(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
          leading: Icon(
            Icons.calendar_today_outlined,
            color: AppColors.brandPrimary,
            size: 20.sp,
          ),
          title: Text(
            selectedDate == null
                ? label
                : DateFormat('yyyy-MM-dd').format(selectedDate),
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
