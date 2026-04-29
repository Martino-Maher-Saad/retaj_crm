import 'package:flutter/material.dart';
import '../../../../core/widgets/form_toggle_tile.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
/// قسم حالة العقار في الفورم
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
    return RetajSectionCard(
      title: 'حالة العقار',
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF0F766E),
      children: [
        // ─── toggle: هل العقار داخل كمبوند؟ ───
        FormToggleTile(
          icon: Icons.villa_outlined,
          title: 'داخل كمبوند',
          subtitle: 'سيظهر ضمن عقارات الكمبوندات',
          value: isCompound,
          onChanged: onCompoundChanged,
        ),

        if (isCompound) ...[
          // حالة التشطيب — صف كامل لوضوح الخيارات
          RetajDropdown<String>(
            label: 'حالة التشطيب',
            value: selectedCompletionStatus,
            items: ['ready', 'off-plan']
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onCompletionStatusChanged,
          ),
          if (selectedCompletionStatus == 'off-plan')
            RetajDatePicker(
              context: context,
              label: 'تاريخ الاستلام المتوقع',
              selectedDate: selectedDeliveryDate,
              onDateSelected: onDeliveryDateSelected,
            ),
        ],

        // عمر المبنى لو خارج كمبوند وليس أرض
        if (selectedPropertyTypeId != 'land' && !isCompound)
          RetajNumberStepper(
            controller: controllers['buildingAge']!,
            label: 'عمر المبنى (سنة)',
          ),
      ],
    );
  }
}
