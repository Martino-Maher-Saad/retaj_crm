import 'package:flutter/material.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';

class ClientAdminSection extends StatelessWidget {
  final String? selectedCity;
  final String? selectedStatus;
  final List<String> cities;
  final List<String> statuses;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onStatusChanged;
  final TextEditingController commentController;

  const ClientAdminSection({
    super.key,
    required this.selectedCity,
    required this.selectedStatus,
    required this.cities,
    required this.statuses,
    required this.onCityChanged,
    required this.onStatusChanged,
    required this.commentController,
  });

  @override
  Widget build(BuildContext context) {
    return RetajSectionCard(
      title: 'الإدارة والمتابعة',
      icon: Icons.admin_panel_settings_outlined,
      iconColor: const Color(0xFFB45309),
      children: [
        // المدينة + الحالة في صف واحد (dropdowns قصيرة)
        RetajFieldRow(
          first: RetajDropdown<String>(
            value: cities.contains(selectedCity) ? selectedCity : null,
            label: 'المدينة',
            prefixIcon: Icons.location_on_outlined,
            items: cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: onCityChanged,
          ),
          second: RetajDropdown<String>(
            value: statuses.contains(selectedStatus) ? selectedStatus : null,
            label: 'حالة العميل',
            prefixIcon: Icons.star_outline,
            items: statuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: onStatusChanged,
          ),
        ),

        // الملاحظات — حقل مطاطي
        RetajTextArea(
          controller: commentController,
          label: 'ملاحظات إضافية للموظف',
          minLines: 2,
          prefixIcon: Icons.note_alt_outlined,
        ),
      ],
    );
  }
}
