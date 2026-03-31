import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/lead_model.dart';

/// Dialog تأكيد حذف عميل — يظهر عند الضغط على زر الحذف في الكارت
/// يتحقق من رغبة المستخدم قبل تنفيذ الحذف الفعلي
class LeadDeleteDialog extends StatelessWidget {
  final LeadModel lead;

  /// يُستدعى فقط عند تأكيد الحذف — الـ dialog يُغلق نفسه بعده
  final VoidCallback onConfirm;

  const LeadDeleteDialog({
    super.key,
    required this.lead,
    required this.onConfirm,
  });

  /// Helper static — يسهل استدعاء الـ dialog من أي مكان بسطر واحد
  static void show(BuildContext context, LeadModel lead, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => LeadDeleteDialog(lead: lead, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("تأكيد الحذف", style: AppTextStyles.h3),
      content: Text("هل تريد حذف ${lead.clientName}؟"),
      actions: [
        // ─── إلغاء — فقط يغلق الـ dialog ───
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),
        // ─── تأكيد الحذف ───
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text("حذف", style: TextStyle(color: AppColors.brandAccent)),
        ),
      ],
    );
  }
}
