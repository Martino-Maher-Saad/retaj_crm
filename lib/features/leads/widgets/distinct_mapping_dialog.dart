import 'package:flutter/material.dart';
import '../../../data/models/location_model.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';

class DistinctMappingDialog extends StatefulWidget {
  final Map<String, int> unmappedLocations;
  final Function(Map<String, int> mapping) onApply;

  const DistinctMappingDialog({
    super.key,
    required this.unmappedLocations,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, int> unmappedLocations,
    required Function(Map<String, int> mapping) onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DistinctMappingDialog(
        unmappedLocations: unmappedLocations,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DistinctMappingDialog> createState() => _DistinctMappingDialogState();
}

class _DistinctMappingDialogState extends State<DistinctMappingDialog> {
  final Map<String, int?> _selectedMappings = {};
  late List<City> _cities;

  @override
  void initState() {
    super.initState();
    final dataManager = sl<StaticDataManager>();
    _cities = dataManager.allCities.where((c) => c.isActive).toList();

    // محاولة مطابقة أولية ذكية إن وُجدت
    widget.unmappedLocations.forEach((loc, _) {
      final matchedCity = _guessCity(loc);
      _selectedMappings[loc] = matchedCity?.id;
    });
  }

  City? _guessCity(String location) {
    final clean = location.toLowerCase();
    for (var c in _cities) {
      final name = c.name.toLowerCase();
      if (clean.contains(name) || name.contains(clean)) return c;
    }
    if (clean.contains('تجمع') || clean.contains('settlement') || clean.contains('new cairo') || clean.contains('فانتدج') || clean.contains('سنشري')) {
      return _cities.where((c) => c.name.contains('التجمع')).firstOrNull;
    }
    if (clean.contains('زايد') || clean.contains('zayed')) {
      return _cities.where((c) => c.name.contains('الشيخ زايد')).firstOrNull;
    }
    if (clean.contains('نصر') || clean.contains('nasr')) {
      return _cities.where((c) => c.name.contains('مدينة نصر')).firstOrNull;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final int totalLeads = widget.unmappedLocations.values.fold(0, (sum, count) => sum + count);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.hub_outlined, color: Colors.indigo),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'مطابقة المناطق والكمبوندات غير المعرفة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${widget.unmappedLocations.length} منطقة فريدة ($totalLeads عميل)',
              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
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
              'اختر المدينة التابعة لكل منطقة فريدة من القائمة. بمجرد الاختيار، ستُطبق المدينة آلياً على كافة صفوف الملف:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: ListView.separated(
                itemCount: widget.unmappedLocations.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final key = widget.unmappedLocations.keys.elementAt(i);
                  final count = widget.unmappedLocations[key]!;
                  final currentCityId = _selectedMappings[key];

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
                                '$count عملاء مرتبطين بهذا الاسم',
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
                          child: DropdownButtonFormField<int>(
                            initialValue: currentCityId,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              hintText: 'اختر المدينة...',
                            ),
                            items: _cities.map((city) {
                              return DropdownMenuItem<int>(
                                value: city.id,
                                child: Text(city.name, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedMappings[key] = val;
                              });
                            },
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
            final Map<String, int> validMappings = {};
            _selectedMappings.forEach((key, cityId) {
              if (cityId != null) {
                validMappings[key] = cityId;
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
