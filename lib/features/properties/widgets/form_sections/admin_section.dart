import 'package:flutter/material.dart';
import '../property_field_builders.dart';

class AdminSection extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final bool status;
  final Function(bool) onStatusChanged;

  const AdminSection({
    super.key,
    required this.controllers,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PropertyFieldBuilders.buildField(controllers['ownerName']!, "اسم المالك"),
        PropertyFieldBuilders.buildField(controllers['ownerPhone']!, "رقم المالك"),
        PropertyFieldBuilders.buildField(
          controllers['internalNotes']!,
          "ملاحظات إدارية",
          long: true,
        ),
        SwitchListTile(
          title: const Text("نشط (يظهر للعملاء)"),
          value: status,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}
