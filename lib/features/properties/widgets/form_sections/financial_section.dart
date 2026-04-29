import 'package:flutter/material.dart';
import '../../../../core/widgets/form_toggle_tile.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';

/// قسم التفاصيل المالية للعقار
class FinancialSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final String? selectedListingTypeId;
  final String? selectedRentalFrequency;
  final bool hasInstallment;
  final bool negotiable;
  final Function(String?) onRentalFrequencyChanged;
  final Function(bool) onInstallmentChanged;
  final Function(bool) onNegotiableChanged;

  const FinancialSection({
    super.key,
    required this.controllers,
    required this.selectedListingTypeId,
    required this.selectedRentalFrequency,
    required this.hasInstallment,
    required this.negotiable,
    required this.onRentalFrequencyChanged,
    required this.onInstallmentChanged,
    required this.onNegotiableChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSale = selectedListingTypeId == 'sale';
    final bool isRent = selectedListingTypeId == 'rent';

    return RetajSectionCard(
      title: 'بيانات السعر',
      icon: Icons.payments_outlined,
      iconColor: const Color(0xFF059669),
      children: [
        // ─── السعر الأساسي (صف كامل — رقم مهم) ───
        RetajTextField(
          controller: controllers['price'],
          label: 'السعر (جنيه)',
          keyboardType: TextInputType.number,
          forceLtr: true,
          validator: (v) => (v == null || v.isEmpty) ? 'حقل مطلوب' : null,
          inputFormatters: [ThousandsFormatter()],
        ),

        // ─── حقول الإيجار ───
        if (isRent) ...[
          RetajFieldRow(
            first: RetajDropdown<String>(
              label: 'دورية الدفع',
              value: selectedRentalFrequency,
              items: ['daily', 'weekly', 'monthly', 'yearly']
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onRentalFrequencyChanged,
            ),
            second: RetajTextField(
              controller: controllers['insurance'],
              label: 'قيمة التأمين',
              keyboardType: TextInputType.number,
              forceLtr: true,
              inputFormatters: [ThousandsFormatter()],
            ),
          ),
        ],

        // ─── حقول البيع — التقسيط ───
        if (isSale) ...[
          FormToggleTile(
            icon: Icons.credit_card_outlined,
            title: 'يوجد نظام تقسيط',
            subtitle: 'دفع مقدم + أقساط شهرية',
            value: hasInstallment,
            onChanged: onInstallmentChanged,
          ),

          if (hasInstallment) ...[
            // الدفعة المقدمة + القسط الشهري في صف واحد
            RetajFieldRow(
              first: RetajTextField(
                controller: controllers['downPayment'],
                label: 'الدفعة المقدمة',
                keyboardType: TextInputType.number,
                forceLtr: true,
                inputFormatters: [ThousandsFormatter()],
              ),
              second: RetajTextField(
                controller: controllers['monthlyInstall'],
                label: 'القسط الشهري',
                keyboardType: TextInputType.number,
                forceLtr: true,
                inputFormatters: [ThousandsFormatter()],
              ),
            ),
            // مدة التقسيط — عدد شهور (stepper)
            RetajNumberStepper(
              controller: controllers['monthsInstall']!,
              label: 'مدة التقسيط (شهور)',
              min: 1,
              max: 360,
            ),
          ],
        ],

        // ─── السعر قابل للتفاوض ───
        FormToggleTile(
          icon: Icons.handshake_outlined,
          title: 'السعر قابل للتفاوض',
          value: negotiable,
          onChanged: onNegotiableChanged,
        ),
      ],
    );
  }
}
