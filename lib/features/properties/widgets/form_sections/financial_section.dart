import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/form_toggle_tile.dart';
import '../property_field_builders.dart';

/// قسم التفاصيل المالية للعقار
/// يتحكم في: السعر، دورية الإيجار، التأمين، نظام التقسيط، التفاوض
/// يتكيف تلقائياً بناءً على selectedListingTypeId (بيع / إيجار)
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

    return Column(
      children: [
        // ─── السعر الأساسي (مطلوب دائماً) ───
        PropertyFieldBuilders.buildField(
          controllers['price']!,
          "السعر",
          num: true,
          isPrice: true,
          req: true,
        ),

        // ─── حقول خاصة بالإيجار ───
        if (isRent) ...[
          PropertyFieldBuilders.buildFixedDrop(
            label: "دورية الدفع",
            items: ["daily", "weekly", "monthly", "yearly"],
            val: selectedRentalFrequency,
            onChg: onRentalFrequencyChanged,
          ),
          PropertyFieldBuilders.buildField(
            controllers['insurance']!,
            "قيمة التأمين",
            num: true,
          ),
        ],

        // ─── حقول خاصة بالبيع ───
        if (isSale) ...[
          // toggle التقسيط مع subtitle توضيحي
          FormToggleTile(
            icon: Icons.credit_card_outlined,
            title: "يوجد نظام تقسيط",
            subtitle: "ادفع جزءاً مقدماً والباقي أقساط شهرية",
            value: hasInstallment,
            onChanged: onInstallmentChanged,
          ),

          // حقول التقسيط التفصيلية (تظهر فقط لو التقسيط مفعل)
          if (hasInstallment) ...[
            Row(
              children: [
                Expanded(
                  child: PropertyFieldBuilders.buildField(
                    controllers['downPayment']!,
                    "الدفعة المقدمة",
                    num: true,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: PropertyFieldBuilders.buildField(
                    controllers['monthlyInstall']!,
                    "القسط الشهري",
                    num: true,
                  ),
                ),
              ],
            ),
            PropertyFieldBuilders.buildField(
              controllers['monthsInstall']!,
              "مدة التقسيط (شهور)",
              num: true,
            ),
          ],
        ],

        // ─── toggle التفاوض (لكل أنواع العقارات) ───
        FormToggleTile(
          icon: Icons.handshake_outlined,
          title: "السعر قابل للتفاوض",
          value: negotiable,
          onChanged: onNegotiableChanged,
        ),
      ],
    );
  }
}
