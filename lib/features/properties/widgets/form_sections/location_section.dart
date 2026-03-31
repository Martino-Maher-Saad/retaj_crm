import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../property_field_builders.dart';

class LocationSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final StaticDataManager dataManager;
  final String? selectedGovId;
  final String? selectedCityId;
  final Function(String?) onGovChanged;
  final Function(String?) onCityChanged;

  const LocationSection({
    super.key,
    required this.controllers,
    required this.dataManager,
    required this.selectedGovId,
    required this.selectedCityId,
    required this.onGovChanged,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PropertyFieldBuilders.buildJsonDrop(
                label: "المحافظة",
                items: dataManager.governorates,
                val: selectedGovId,
                onChg: onGovChanged,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: PropertyFieldBuilders.buildJsonDrop(
                label: "المدينة",
                items: selectedGovId != null
                    ? dataManager.getCitiesByGov(selectedGovId!)
                    : [],
                val: selectedCityId,
                onChg: onCityChanged,
              ),
            ),
          ],
        ),
        PropertyFieldBuilders.buildField(
          controllers['regionAr']!,
          "المنطقة بالعربي",
          req: true,
        ),
        PropertyFieldBuilders.buildField(
          controllers['locDetails']!,
          "العنوان التفصيلي",
          req: true,
        ),
        PropertyFieldBuilders.buildField(
          controllers['locMap']!,
          "رابط جوجل ماب",
        ),
      ],
    );
  }
}
