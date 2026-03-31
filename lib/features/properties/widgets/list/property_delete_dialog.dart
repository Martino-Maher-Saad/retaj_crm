import 'package:flutter/material.dart';
import '../../../../data/models/property_model.dart';

/// Dialog تأكيد حذف عقار — يتحقق من رغبة المستخدم قبل تنفيذ الحذف
/// يدمر العقار وصوره، لذا نطلب تأكيداً صريحاً قبل المتابعة
class PropertyDeleteDialog extends StatelessWidget {
  final PropertyModel property;

  /// يُستدعى فقط عند الضغط على "حذف" — الـ dialog يُغلق تلقائياً بعده
  final VoidCallback onConfirm;

  const PropertyDeleteDialog({
    super.key,
    required this.property,
    required this.onConfirm,
  });

  /// Helper static — يسهل فتح الـ dialog من أي مكان بسطر واحد
  /// مثال: PropertyDeleteDialog.show(context, property, () => cubit.delete(id))
  static void show(BuildContext context, PropertyModel property, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => PropertyDeleteDialog(property: property, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("حذف العقار"),
      content: Text("هل أنت متأكد من حذف ${property.titleAr}؟"),
      actions: [
        // ─── إلغاء — فقط يغلق الـ dialog دون أي تأثير ───
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء"),
        ),
        // ─── تأكيد الحذف — يُنفذ العملية ثم يغلق الـ dialog ───
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text("حذف", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
