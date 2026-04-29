import 'package:flutter/material.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';

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
    return RetajSectionCard(
      title: 'تفاصيل الطلب',
      icon: Icons.assignment_outlined,
      iconColor: const Color(0xFF0F766E),
      children: [
        // كود العقار + المصدر في صف واحد (قيم قصيرة)
        RetajFieldRow(
          first: RetajTextField(
            controller: propertyCodeController,
            label: 'كود العقار المهتم به',
            prefixIcon: Icons.home_work_outlined,
          ),
          second: RetajTextField(
            controller: sourceController,
            label: 'المصدر / القناة',
            prefixIcon: Icons.campaign_outlined,
          ),
        ),

        // طريقة التواصل — dropdown صف كامل
        RetajDropdown<String>(
          label: 'طريقة التواصل المفضلة',
          prefixIcon: Icons.contact_mail_outlined,
          value: selectedChannel,
          items: channels
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChannelChanged,
        ),

        // وصف الاحتياج — حقل مطاطي
        RetajTextArea(
          controller: descController,
          label: 'وصف دقيق لما يبحث عنه العميل',
          minLines: 3,
          prefixIcon: Icons.description_outlined,
        ),
      ],
    );
  }
}
