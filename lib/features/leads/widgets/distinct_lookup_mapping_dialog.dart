import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../../data/services/dropdown_service.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';

class DistinctLookupMappingDialog extends StatefulWidget {
  final String title;
  final String category; // 'property_type' or 'listing_type'
  final Map<String, int> unmappedItems;
  final Function(Map<String, String> mapping) onApply;

  const DistinctLookupMappingDialog({
    super.key,
    required this.title,
    required this.category,
    required this.unmappedItems,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String category,
    required Map<String, int> unmappedItems,
    required Function(Map<String, String> mapping) onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DistinctLookupMappingDialog(
        title: title,
        category: category,
        unmappedItems: unmappedItems,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DistinctLookupMappingDialog> createState() => _DistinctLookupMappingDialogState();
}

class _DistinctLookupMappingDialogState extends State<DistinctLookupMappingDialog> {
  final Map<String, String?> _selectedMappings = {};
  late List<LookupOptionModel> _options;

  @override
  void initState() {
    super.initState();
    final dataManager = sl<StaticDataManager>();
    _options = dataManager.getOptionModels(widget.category).where((o) => o.isActive).toList();

    widget.unmappedItems.forEach((rawKey, _) {
      final matched = _guessOption(rawKey);
      _selectedMappings[rawKey] = matched?.id;
    });
  }

  LookupOptionModel? _guessOption(String rawKey) {
    final clean = rawKey.trim().toLowerCase();
    for (var o in _options) {
      final name = o.nameAr.trim().toLowerCase();
      if (clean == name || clean.contains(name) || name.contains(clean)) {
        return o;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final int totalLeads = widget.unmappedItems.values.fold(0, (sum, count) => sum + count);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.category_outlined, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.unmappedItems.length} عنصر فريد ($totalLeads عميل)',
              style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 13),
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
            Text(
              'اختر القيمة المعتمدة من السيستم لكل نص حر قادم من ملف الإكسيل. بمجرد الاختيار سيتم تطبيقه على كافة الصفوف دفعة واحدة:',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: widget.unmappedItems.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final key = widget.unmappedItems.keys.elementAt(i);
                  final count = widget.unmappedItems[key]!;
                  final currentId = _selectedMappings[key];

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
                                '$count عملاء مرتبطين بهذه القيمة',
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
                          child: DropdownSearch<LookupOptionModel>(
                            items: (filter, infiniteScrollProps) {
                              final query = filter.trim().toLowerCase();
                              if (query.isEmpty) return _options;
                              return _options.where((opt) => opt.nameAr.toLowerCase().contains(query)).toList();
                            },
                            selectedItem: _options.where((opt) => opt.id == currentId).firstOrNull,
                            itemAsString: (opt) => opt.nameAr,
                            compareFn: (o1, o2) => o1.id == o2.id,
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
                                  hintText: 'ابحث في الخيارات...',
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
                                hintText: 'اختر من السيستم...',
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
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () {
            final Map<String, String> validMappings = {};
            _selectedMappings.forEach((key, optId) {
              if (optId != null && optId.isNotEmpty) {
                validMappings[key] = optId;
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
