import 'package:flutter/material.dart';
import '../../../../core/widgets/form_toggle_tile.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../property_field_builders.dart';

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
        PropertyFieldBuilders.buildField(
          controllers['price']!,
          'السعر (جنيه)',
          num: true,
          isPrice: true,
          req: true,
        ),

        // ─── حقول الإيجار ───
        if (isRent) ...[
          RetajFieldRow(
            first: PropertyFieldBuilders.buildFixedDrop(
              label: 'دورية الدفع',
              items: ['daily', 'weekly', 'monthly', 'yearly'],
              val: selectedRentalFrequency,
              onChg: onRentalFrequencyChanged,
            ),
            second: PropertyFieldBuilders.buildField(
              controllers['insurance']!,
              'قيمة التأمين',
              num: true,
              isPrice: true,
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
              first: PropertyFieldBuilders.buildField(
                controllers['downPayment']!,
                'الدفعة المقدمة',
                num: true,
                isPrice: true,
              ),
              second: PropertyFieldBuilders.buildField(
                controllers['monthlyInstall']!,
                'القسط الشهري',
                num: true,
                isPrice: true,
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
