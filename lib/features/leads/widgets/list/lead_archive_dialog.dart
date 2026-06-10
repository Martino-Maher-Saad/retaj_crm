import 'package:flutter/material.dart';
import '../../../../data/models/lead_model.dart';

class LeadArchiveDialog extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onConfirm;

  const LeadArchiveDialog({
    super.key,
    required this.lead,
    required this.onConfirm,
  });

  static void show(BuildContext context, LeadModel lead, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => LeadArchiveDialog(lead: lead, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("أرشفة العميل"),
      content: Text("هل أنت متأكد من أرشفة العميل ${lead.clientName}؟\nسيتم نقله إلى الأرشيف ولن يظهر في القوائم العامة."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text("أرشفة", style: TextStyle(color: Colors.orange)),
        ),
      ],
    );
  }
}
