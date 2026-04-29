import 'package:flutter/material.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';

class TechnicalSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final String? selectedPropertyTypeId;
  final String? selectedFurnished;
  final bool showFloor;
  final Function(String?) onFurnishedChanged;

  const TechnicalSection({
    super.key,
    required this.controllers,
    required this.selectedPropertyTypeId,
    required this.selectedFurnished,
    required this.showFloor,
    required this.onFurnishedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLand = selectedPropertyTypeId == 'land';
    final bool isResidential = selectedPropertyTypeId == 'apartment' ||
        selectedPropertyTypeId == 'villa' ||
        selectedPropertyTypeId == 'chalet';
    final bool isBuilding = selectedPropertyTypeId == 'building';
    final bool isVillaOrBuilding =
        selectedPropertyTypeId == 'villa' || isBuilding;

    return RetajSectionCard(
      title: 'المواصفات الفنية',
      icon: Icons.straighten_rounded,
      iconColor: const Color(0xFF7C3AED),
      children: [
        if (isLand) ...[
          // أرض — مساحة فقط
          RetajNumberStepper(
            controller: controllers['landArea']!,
            label: 'مساحة الأرض (م²)',
            isRequired: true,
          ),
        ] else ...[
          // ─── المساحة المبنية ───
          RetajNumberStepper(
            controller: controllers['area']!,
            label: 'المساحة المبنية (م²)',
            isRequired: true,
          ),

          // ─── الغرف + الحمامات في صف ───
          RetajFieldRow(
            first: RetajNumberStepper(
              controller: controllers['bedrooms']!,
              label: 'غرف النوم',
            ),
            second: RetajNumberStepper(
              controller: controllers['bathrooms']!,
              label: 'الحمامات',
            ),
          ),

          // ─── المطابخ + البلكونات في صف ───
          RetajFieldRow(
            first: RetajNumberStepper(
              controller: controllers['kitchens']!,
              label: 'المطابخ',
            ),
            second: RetajNumberStepper(
              controller: controllers['balconies']!,
              label: 'البلكونات',
            ),
          ),

          // ─── رقم الدور (يظهر حسب النوع) ───
          if (showFloor) ...[
            RetajFieldRow(
              first: RetajNumberStepper(
                controller: controllers['floor']!,
                label: 'رقم الدور',
              ),
              second: RetajNumberStepper(
                controller: controllers['buildingAge']!,
                label: 'عمر المبنى (سنة)',
              ),
            ),
          ],

          // ─── التشطيب / التأثيث ───
          if (isResidential)
            RetajDropdown<String>(
              label: 'حالة التأثيث',
              value: selectedFurnished,
              items: ['yes', 'no', 'semi']
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onFurnishedChanged,
            ),

          // ─── فيلا / عمارة — عدد الأدوار + الشقق + الحديقة ───
          if (isVillaOrBuilding) ...[
            RetajFieldRow(
              first: RetajNumberStepper(
                controller: controllers['totalFloors']!,
                label: 'عدد الأدوار',
              ),
              second: isBuilding
                  ? RetajNumberStepper(
                      controller: controllers['totalApartments']!,
                      label: 'عدد الشقق',
                    )
                  : RetajNumberStepper(
                      controller: controllers['gardenArea']!,
                      label: 'مساحة الحديقة (م²)',
                    ),
            ),
            RetajFieldRow(
              first: RetajNumberStepper(
                controller: controllers['gardenArea']!,
                label: 'مساحة الحديقة (م²)',
              ),
              second: RetajNumberStepper(
                controller: controllers['landArea']!,
                label: 'مساحة الأرض الكلية (م²)',
              ),
            ),
          ],
        ],
      ],
    );
  }
}
