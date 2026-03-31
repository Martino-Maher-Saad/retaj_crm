import 'package:flutter/material.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../property_field_builders.dart';

class BasicSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final StaticDataManager dataManager;
  final String? selectedListingTypeId;
  final String? selectedPropertyTypeId;
  final Function(String?) onListingTypeChanged;
  final Function(String?) onPropertyTypeChanged;

  const BasicSection({
    super.key,
    required this.controllers,
    required this.dataManager,
    required this.selectedListingTypeId,
    required this.selectedPropertyTypeId,
    required this.onListingTypeChanged,
    required this.onPropertyTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PropertyFieldBuilders.buildField(controllers['propertyCode']!, "كود العقار"),
        PropertyFieldBuilders.buildJsonDrop(
          label: "الفئة",
          items: dataManager.listingTypes,
          val: selectedListingTypeId,
          onChg: onListingTypeChanged,
        ),
        PropertyFieldBuilders.buildJsonDrop(
          label: "نوع العقار",
          items: dataManager.propertyTypes,
          val: selectedPropertyTypeId,
          onChg: onPropertyTypeChanged,
        ),
        PropertyFieldBuilders.buildField(
          controllers['titleAr']!,
          "العنوان بالعربي",
          req: true,
        ),
        PropertyFieldBuilders.buildField(
          controllers['descAr']!,
          "الوصف بالعربي",
          long: true,
          req: true,
        ),
      ],
    );
  }
}
