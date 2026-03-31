import 'package:flutter/material.dart';
import '../../../../core/widgets/form_toggle_tile.dart';
import '../property_field_builders.dart';

/// قسم حالة العقار في الفورم — يتحكم في:
/// - هل العقار داخل كمبوند؟
/// - حالة التشطيب (ready / off-plan)
/// - تاريخ استلام متوقع (لو off-plan)
/// - عمر المبنى (للعقارات العادية غير السكنية في الكمبوند)
class StatusSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final bool isCompound;
  final String? selectedPropertyTypeId;
  final String? selectedCompletionStatus;
  final DateTime? selectedDeliveryDate;
  final Function(bool) onCompoundChanged;
  final Function(String?) onCompletionStatusChanged;
  final Function(DateTime) onDeliveryDateSelected;

  const StatusSection({
    super.key,
    required this.controllers,
    required this.isCompound,
    required this.selectedPropertyTypeId,
    required this.selectedCompletionStatus,
    required this.selectedDeliveryDate,
    required this.onCompoundChanged,
    required this.onCompletionStatusChanged,
    required this.onDeliveryDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ─── toggle: هل العقار داخل كمبوند؟ ───
        FormToggleTile(
          icon: Icons.villa_outlined,
          title: "داخل كمبوند",
          subtitle: "سيظهر ضمن عقارات الكمبوندات",
          value: isCompound,
          onChanged: onCompoundChanged,
        ),

        // ─── حقول الكمبوند (تظهر فقط لو isCompound = true) ───
        if (isCompound) ...[
          PropertyFieldBuilders.buildFixedDrop(
            label: "حالة التشطيب",
            items: ["ready", "off-plan"],
            val: selectedCompletionStatus,
            onChg: onCompletionStatusChanged,
          ),
          // تاريخ الاستلام يظهر فقط لو off-plan
          if (selectedCompletionStatus == "off-plan")
            PropertyFieldBuilders.buildDatePicker(
              context: context,
              label: "تاريخ الاستلام المتوقع",
              selectedDate: selectedDeliveryDate,
              onDateSelected: onDeliveryDateSelected,
            ),
        ],

        // ─── عمر المبنى (للعقارات خارج الكمبوند وليست أرض) ───
        if (selectedPropertyTypeId != 'land' && !isCompound)
          PropertyFieldBuilders.buildField(
            controllers['buildingAge']!,
            "عمر المبنى بالسنوات",
            num: true,
          ),
      ],
    );
  }
}
