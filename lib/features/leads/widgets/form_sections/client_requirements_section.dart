import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../properties/widgets/property_form_card.dart';
import '../../widgets/lead_field_builders.dart';


class ClientRequirementsSection extends StatelessWidget {
  final TextEditingController propertyCodeController;
  final TextEditingController sourceController;
  final TextEditingController descController;
  final String selectedChannel;
  final List<String> channels;
  final ValueChanged<String?> onChannelChanged;

  const ClientRequirementsSection({
    super.key,
    required this.propertyCodeController,
    required this.sourceController,
    required this.descController,
    required this.selectedChannel,
    required this.channels,
    required this.onChannelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyFormCard(
      title: "تفاصيل الطلب والاحتياج",
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          LeadFieldBuilders.buildTextField(
            controller: propertyCodeController,
            label: "كود العقار المهتم به",
            icon: Icons.home_work_outlined,
          ),
          SizedBox(height: 16.h),
          LeadFieldBuilders.buildTextField(
            controller: sourceController,
            label: "المصدر (المواقع/القناة)",
            icon: Icons.campaign_outlined,
          ),
          SizedBox(height: 16.h),
          LeadFieldBuilders.buildDropdown(
            value: selectedChannel,
            label: "طريقة التواصل المفضلة",
            items: channels,
            onChanged: onChannelChanged,
            icon: Icons.contact_mail_outlined,
          ),
          SizedBox(height: 16.h),
          LeadFieldBuilders.buildTextField(
            controller: descController,
            label: "وصف دقيق لما يبحث عنه العميل",
            icon: Icons.description_outlined,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
