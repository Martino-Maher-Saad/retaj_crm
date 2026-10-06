import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';

class DistinctEmployeeMappingDialog extends StatefulWidget {
  final Map<String, int> unmappedEmployees;
  final Function(Map<String, String> mapping) onApply;

  const DistinctEmployeeMappingDialog({
    super.key,
    required this.unmappedEmployees,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, int> unmappedEmployees,
    required Function(Map<String, String> mapping) onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DistinctEmployeeMappingDialog(
        unmappedEmployees: unmappedEmployees,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DistinctEmployeeMappingDialog> createState() => _DistinctEmployeeMappingDialogState();
}

class _DistinctEmployeeMappingDialogState extends State<DistinctEmployeeMappingDialog> {
  final Map<String, String?> _selectedMappings = {};
  late List<ProfileModel> _employees;

  @override
  void initState() {
    super.initState();
    final dataManager = sl<StaticDataManager>();
    _employees = dataManager.employees.where((e) => e.isActive).toList();

    // محاولة مطابقة أولية بالاسم أو بالبادئة إن أمكن
    widget.unmappedEmployees.forEach((rawKey, _) {
      final matchedEmp = _guessEmployee(rawKey);
      _selectedMappings[rawKey] = matchedEmp?.id;
    });
  }

  ProfileModel? _guessEmployee(String rawKey) {
    final clean = rawKey.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    
    // فحص لو كان مفتاح كود مثل "كود: HG"
    String prefix = clean;
    if (clean.startsWith('كود:')) {
      prefix = clean.replaceFirst('كود:', '').trim();
    } else if (clean.startsWith('prefix:')) {
      prefix = clean.replaceFirst('prefix:', '').trim();
    }

    for (var e in _employees) {
      if (e.propertyPrefix != null && e.propertyPrefix!.trim().toLowerCase() == prefix.toLowerCase()) {
        return e;
      }
      final fullName = '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (fullName == clean) {
        return e;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final int totalLeads = widget.unmappedEmployees.values.fold(0, (sum, count) => sum + count);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.badge_outlined, color: Colors.indigo),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'مطابقة الموظفين وأكواد العقارات غير المسجلة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.unmappedEmployees.length} اسم/كود ($totalLeads عميل)',
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الموظف المسند لكل اسم موظف أو كود عقار غير معروف. بمجرد الاختيار، سيتم تطبيق الموظف على كافة عملاء هذا الكود/الاسم دفعة واحدة:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: widget.unmappedEmployees.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final key = widget.unmappedEmployees.keys.elementAt(i);
                  final count = widget.unmappedEmployees[key]!;
                  final currentUserId = _selectedMappings[key];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                key,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '$count عملاء مرتبطين بهذا الكود/الاسم',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_back, size: 16, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: DropdownSearch<ProfileModel>(
                            items: (filter, infiniteScrollProps) {
                              final query = filter.trim().toLowerCase();
                              if (query.isEmpty) return _employees;
                              return _employees.where((emp) {
                                final name = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.toLowerCase();
                                final prefix = emp.propertyPrefix?.toLowerCase() ?? '';
                                return name.contains(query) || prefix.contains(query);
                              }).toList();
                            },
                            selectedItem: _employees.where((emp) => emp.id == currentUserId).firstOrNull,
                            itemAsString: (emp) {
                              final name = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
                              final prefixDisplay = (emp.propertyPrefix != null && emp.propertyPrefix!.isNotEmpty)
                                  ? ' (${emp.propertyPrefix})'
                                  : '';
                              return '$name$prefixDisplay';
                            },
                            compareFn: (i1, i2) => i1.id == i2.id,
                            onSelected: (val) {
                              setState(() {
                                _selectedMappings[key] = val?.id;
                              });
                            },
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              fit: FlexFit.loose,
                              searchFieldProps: TextFieldProps(
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'ابحث عن اسم الموظف أو الكود...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                hintText: 'اختر الموظف...',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('تخطي وتعديلها يدوياً لاحقاً'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('تطبيق على جميع الصفوف'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            final Map<String, String> validMappings = {};
            _selectedMappings.forEach((key, userId) {
              if (userId != null && userId.isNotEmpty) {
                validMappings[key] = userId;
              }
            });
            widget.onApply(validMappings);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
