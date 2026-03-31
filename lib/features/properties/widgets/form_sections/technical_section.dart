import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../property_field_builders.dart';

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
    bool isLand = selectedPropertyTypeId == 'land';
    // استخدام IDs الجديدة للتحقق من السكني
    bool isResidential = selectedPropertyTypeId == 'apartment' ||
        selectedPropertyTypeId == 'villa' ||
        selectedPropertyTypeId == 'chalet';

    return Column(
      children: [
        if (isLand)
          PropertyFieldBuilders.buildField(
            controllers['landArea']!,
            "مساحة الأرض الكلية",
            num: true,
            req: true,
          ),
        if (!isLand) ...[
          PropertyFieldBuilders.buildField(
            controllers['area']!,
            "المساحة المبنية (BUA)",
            num: true,
            req: true,
          ),
          Row(
            children: [
              Expanded(
                child: PropertyFieldBuilders.buildField(
                  controllers['bedrooms']!,
                  "الغرف",
                  num: true,
                  hasStepper: true,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: PropertyFieldBuilders.buildField(
                  controllers['bathrooms']!,
                  "الحمامات",
                  num: true,
                  hasStepper: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: PropertyFieldBuilders.buildField(
                  controllers['kitchens']!,
                  "المطابخ",
                  num: true,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: PropertyFieldBuilders.buildField(
                  controllers['balconies']!,
                  "البلكونات",
                  num: true,
                ),
              ),
            ],
          ),
          if (showFloor)
            PropertyFieldBuilders.buildField(
              controllers['floor']!,
              "رقم الدور",
              num: true,
              hasStepper: true,
            ),
          if (isResidential)
            PropertyFieldBuilders.buildFixedDrop(
              label: "مفروش؟",
              items: ["yes", "no"],
              val: selectedFurnished,
              onChg: onFurnishedChanged,
            ),
          if (selectedPropertyTypeId == 'villa' ||
              selectedPropertyTypeId == 'building') ...[
            PropertyFieldBuilders.buildField(
              controllers['totalFloors']!,
              "عدد الأدوار",
              num: true,
            ),
            if (selectedPropertyTypeId == 'building')
              PropertyFieldBuilders.buildField(
                controllers['totalApartments']!,
                "عدد الشقق",
                num: true,
              ),
            PropertyFieldBuilders.buildField(
              controllers['gardenArea']!,
              "مساحة الحديقة",
              num: true,
            ),
            PropertyFieldBuilders.buildField(
              controllers['landArea']!,
              "مساحة الأرض الكلية",
              num: true,
            ),
          ],
        ],
      ],
    );
  }
}
