import 'package:flutter/material.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
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
    return RetajSectionCard(
      title: 'البيانات الأساسية',
      icon: Icons.assignment_outlined,
      children: [
        // كود العقار + الفئة في صف واحد (محتوى قليل)
        RetajFieldRow(
          first: PropertyFieldBuilders.buildField(
            controllers['propertyCode']!,
            'كود العقار',
          ),
          second: PropertyFieldBuilders.buildJsonDrop(
            label: 'الفئة',
            items: dataManager.listingTypes,
            val: selectedListingTypeId,
            onChg: onListingTypeChanged,
          ),
        ),

        // نوع العقار — يستحق صفاً كاملاً
        PropertyFieldBuilders.buildJsonDrop(
          label: 'نوع العقار',
          items: dataManager.propertyTypes,
          val: selectedPropertyTypeId,
          onChg: onPropertyTypeChanged,
        ),

        // العنوان — صف كامل (نص متوسط)
        PropertyFieldBuilders.buildField(
          controllers['titleAr']!,
          'العنوان بالعربي',
          req: true,
        ),

        // الوصف — حقل نصي مطاطي
        RetajTextArea(
          controller: controllers['descAr']!,
          label: 'الوصف بالعربي',
          isRequired: true,
          minLines: 4,
          prefixIcon: Icons.description_outlined,
        ),
      ],
    );
  }
}
