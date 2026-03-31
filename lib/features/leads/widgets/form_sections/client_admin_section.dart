import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../properties/widgets/property_form_card.dart';
import '../../widgets/lead_field_builders.dart';

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
    return PropertyFormCard(
      title: "الإدارة والمتابعة",
      icon: Icons.admin_panel_settings_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LeadFieldBuilders.buildDropdown(
                  value: selectedCity,
                  label: "المدينة",
                  items: cities,
                  onChanged: onCityChanged,
                  icon: Icons.location_on_outlined,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: LeadFieldBuilders.buildDropdown(
                  value: selectedStatus,
                  label: "الحالة",
                  items: statuses,
                  onChanged: onStatusChanged,
                  icon: Icons.star_outline,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          LeadFieldBuilders.buildTextField(
            controller: commentController,
            label: "ملاحظات إضافية للموظف",
            icon: Icons.note_alt_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
