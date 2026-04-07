import 'package:flutter/material.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
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
    return RetajSectionCard(
      title: 'بيانات الموقع',
      icon: Icons.location_on_outlined,
      iconColor: const Color(0xFF0F766E),
      children: [
        // المحافظة + المدينة في صف واحد (dropdowns قصيرة)
        RetajFieldRow(
          first: PropertyFieldBuilders.buildJsonDrop(
            label: 'المحافظة',
            items: dataManager.governorates,
            val: selectedGovId,
            onChg: onGovChanged,
          ),
          second: PropertyFieldBuilders.buildJsonDrop(
            label: 'المدينة',
            items: selectedGovId != null
                ? dataManager.getCitiesByGov(selectedGovId!)
                : [],
            val: selectedCityId,
            onChg: onCityChanged,
          ),
        ),

        // المنطقة — صف كامل
        PropertyFieldBuilders.buildField(
          controllers['regionAr']!,
          'المنطقة / الحي',
          req: true,
        ),

        // العنوان التفصيلي — صف كامل
        PropertyFieldBuilders.buildField(
          controllers['locDetails']!,
          'العنوان التفصيلي',
          req: true,
        ),

        // رابط الخريطة — صف كامل (قد يكون طويلاً)
        PropertyFieldBuilders.buildField(
          controllers['locMap']!,
          'رابط جوجل ماب',
        ),
      ],
    );
  }
}
