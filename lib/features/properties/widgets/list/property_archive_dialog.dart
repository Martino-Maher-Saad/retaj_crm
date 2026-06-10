import 'package:flutter/material.dart';
import '../../../../data/models/property_model.dart';

class PropertyArchiveDialog extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onConfirm;

  const PropertyArchiveDialog({
    super.key,
    required this.property,
    required this.onConfirm,
  });

  static void show(BuildContext context, PropertyModel property, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => PropertyArchiveDialog(property: property, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("أرشفة العقار"),
      content: Text("هل أنت متأكد من أرشفة ${property.titleAr}؟\nسيتم نقله إلى الأرشيف ولن يظهر في القوائم العامة."),
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
