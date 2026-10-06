import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';
import '../../../data/models/lead_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_states.dart';
import '../cubit/bulk_add_leads_cubit.dart';
import '../cubit/bulk_add_leads_state.dart';
import '../widgets/distinct_mapping_dialog.dart';
import '../widgets/distinct_employee_mapping_dialog.dart';
import '../widgets/distinct_lookup_mapping_dialog.dart';

class BulkAddLeadsScreen extends StatelessWidget {
  const BulkAddLeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String role = '';
    String userId = '';
    if (authState is AuthSuccess) {
      role = authState.user.role;
      userId = authState.user.id;
    }
    
    final cubit = sl<BulkAddLeadsCubit>()..init(role, userId);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: BlocProvider.value(
        value: cubit,
        child: const _BulkAddLeadsView(),
      ),
    );
  }
}

class _BulkAddLeadsView extends StatefulWidget {
  const _BulkAddLeadsView();

  @override
  State<_BulkAddLeadsView> createState() => _BulkAddLeadsViewState();
}

class _BulkAddLeadsViewState extends State<_BulkAddLeadsView> {
  TrinaGridStateManager? _stateManager;

  // Lookup maps
  final Map<int, String> _cityNameById = {};
  final Map<String, int> _cityIdByName = {};

  final Map<String, String> _employeeNameById = {};
  final Map<String, String> _employeeIdByName = {};

  final Map<String, Map<String, String>> _optionNameById = {};
  final Map<String, Map<String, String>> _optionIdByName = {};

  List<String> _cityNames = [];
  List<String> _employeeNames = [];
  List<String> _propertyTypeNames = [];
  List<String> _listingTypeNames = [];
  List<String> _platformNames = [];

  late List<TrinaColumn> _columns;
  bool _isGridInitialized = false;
  int _lastSkippedNoEmployeeCount = 0;

  @override
  void initState() {
    super.initState();
    _initLookupData();
    _initColumns();
  }

  void _initLookupData() {
    final dataManager = sl<StaticDataManager>();

    // المدن
    for (var c in dataManager.allCities) {
      _cityNameById[c.id] = c.name;
      _cityIdByName[c.name] = c.id;
    }
    _cityNames = dataManager.allCities.where((c) => c.isActive).map((c) => c.name).toList();

    // الموظفون
    for (var e in dataManager.employees) {
      final fullName = '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim();
      _employeeNameById[e.id] = fullName;
      _employeeIdByName[fullName] = e.id;
    }
    _employeeNames = dataManager.employees.where((e) => e.isActive).map((e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim()).toList();

    // القوائم الأخرى
    final categories = ['property_type', 'listing_type', 'platform', 'communication_channel', 'lead_status'];
    for (var cat in categories) {
      _optionNameById[cat] = {};
      _optionIdByName[cat] = {};
      for (var o in dataManager.getOptionModels(cat)) {
        _optionNameById[cat]![o.id] = o.nameAr;
        _optionIdByName[cat]![o.nameAr] = o.id;
      }
    }

    _propertyTypeNames = dataManager.getOptionModels('property_type').where((o) => o.isActive).map((o) => o.nameAr).toList();
    _listingTypeNames = dataManager.getOptionModels('listing_type').where((o) => o.isActive).map((o) => o.nameAr).toList();
    _platformNames = dataManager.getOptionModels('platform').where((o) => o.isActive).map((o) => o.nameAr).toList();
  }

  void _initColumns() {
    // الأعمدة الـ 10 المحددة والمطلوبة فقط من اليسار لليمين:
    // 1. التاريخ | 2. اسم المنصة | 3. اسم العميل | 4. رقم العميل | 5. اسم الموظف
    // 6. كود العقار | 7. نوع العقار | 8. نوع الاعلان | 9. المنطقة الأصلية | 10. المدينة
    _columns = [
      TrinaColumn(
        title: '#',
        field: 'no',
        type: TrinaColumnType.text(),
        width: 60,
        enableRowChecked: true, // Checkbox لاختيار الصف بالكامل
        enableEditingMode: false,
        enableSorting: false,
        frozen: TrinaColumnFrozen.start,
      ),
      TrinaColumn(
        title: 'التاريخ',
        field: 'createdAt',
        type: TrinaColumnType.text(),
        width: 150,
      ),
      TrinaColumn(
        title: 'اسم المنصة',
        field: 'platform',
        type: TrinaColumnType.select(_platformNames),
        width: 150,
      ),
      TrinaColumn(
        title: 'اسم العميل',
        field: 'name',
        type: TrinaColumnType.text(),
        width: 160,
      ),
      TrinaColumn(
        title: 'رقم العميل',
        field: 'phone',
        type: TrinaColumnType.text(),
        width: 140,
      ),
      TrinaColumn(
        title: 'اسم الموظف',
        field: 'assignedTo',
        type: TrinaColumnType.select(_employeeNames),
        width: 170,
      ),
      TrinaColumn(
        title: 'كود العقار',
        field: 'propertyCode',
        type: TrinaColumnType.text(),
        width: 120,
      ),
      TrinaColumn(
        title: 'نوع العقار',
        field: 'propertyType',
        type: TrinaColumnType.select(_propertyTypeNames),
        width: 150,
      ),
      TrinaColumn(
        title: 'نوع الاعلان',
        field: 'listingType',
        type: TrinaColumnType.select(_listingTypeNames),
        width: 140,
      ),
      TrinaColumn(
        title: 'المنطقة الأصلية',
        field: 'areaName',
        type: TrinaColumnType.text(),
        width: 210,
      ),
      TrinaColumn(
        title: 'المدينة',
        field: 'city',
        type: TrinaColumnType.select(_cityNames),
        width: 160,
      ),
    ];
  }

  TrinaRow _createTrinaRowFromLeadRow(EditableLeadRow r, int idx) {
    String dateStr = '';
    if (r.createdAt != null) {
      dateStr = r.createdAt!.toIso8601String().replaceAll('T', ' ').split('.').first;
    }

    return TrinaRow(
      cells: {
        'no': TrinaCell(value: '${idx + 1}'),
        'createdAt': TrinaCell(value: dateStr),
        'platform': TrinaCell(value: _optionNameById['platform']?[r.platformId] ?? r.unmappedPlatform ?? ''),
        'name': TrinaCell(value: r.name ?? ''),
        'phone': TrinaCell(value: r.phone ?? ''),
        'assignedTo': TrinaCell(value: _employeeNameById[r.assignedTo] ?? r.unmappedAssignedTo ?? ''),
        'propertyCode': TrinaCell(value: r.propertyCode ?? ''),
        'propertyType': TrinaCell(value: _optionNameById['property_type']?[r.propertyTypeId] ?? r.unmappedPropertyType ?? ''),
        'listingType': TrinaCell(value: _optionNameById['listing_type']?[r.listingTypeId] ?? r.unmappedListingType ?? ''),
        'areaName': TrinaCell(value: r.areaName ?? ''),
        'city': TrinaCell(value: _cityNameById[r.cityId] ?? r.unmappedCity ?? ''),
      },
    );
  }

  TrinaRow _createEmptyTrinaRow(int idx) {
    return TrinaRow(
      cells: {
        'no': TrinaCell(value: '${idx + 1}'),
        'createdAt': TrinaCell(value: DateTime.now().toLocal().toIso8601String().split('T').first),
        'platform': TrinaCell(value: ''),
        'name': TrinaCell(value: ''),
        'phone': TrinaCell(value: ''),
        'assignedTo': TrinaCell(value: ''),
        'propertyCode': TrinaCell(value: ''),
        'propertyType': TrinaCell(value: ''),
        'listingType': TrinaCell(value: ''),
        'areaName': TrinaCell(value: ''),
        'city': TrinaCell(value: ''),
      },
    );
  }

  void _syncGridWithRows(List<EditableLeadRow> rows) {
    if (_stateManager == null) return;
    final List<TrinaRow> trinaRows = [];
    for (int i = 0; i < rows.length; i++) {
      trinaRows.add(_createTrinaRowFromLeadRow(rows[i], i));
    }
    _stateManager!.removeAllRows(notify: false);
    _stateManager!.appendRows(trinaRows);
  }

  // --- التعبئة الجماعية للخلايا المحددة (Bulk Fill Selected Cells) ---

  List<String>? _getItemsForField(String field) {
    switch (field) {
      case 'platform': return _platformNames;
      case 'assignedTo': return _employeeNames;
      case 'propertyType': return _propertyTypeNames;
      case 'listingType': return _listingTypeNames;
      case 'city': return _cityNames;
      default: return null;
    }
  }

  // --- التعبئة الجماعية للخلايا المحددة (Bulk Fill Selected Cells) ---

  void _bulkFillSelectedCells(BuildContext context) {
    if (_stateManager == null) return;

    final selectedPositions = _stateManager!.currentSelectingPositionList;
    if (selectedPositions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد خلية أو مجموعة خلايا في الجدول أولاً (بالسحب بالماوس أو Shift + الأسهم)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // تحديد الأعمدة الموجودة في التحديد
    final Set<String> selectedFields = selectedPositions.map((p) => p.field).whereType<String>().toSet();
    if (selectedFields.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لتعبئة الخلايا دفعة واحدة، يرجى تحديد خلايا في عمود واحد فقط (مثلاً عمود المدينة أو الموظف)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String field = selectedFields.first;
    final column = _stateManager!.columns.firstWhere((c) => c.field == field);
    final title = column.title;

    if (field == 'no') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تعديل عمود الترقيم'), backgroundColor: Colors.orange),
      );
      return;
    }

    final selectItems = _getItemsForField(field);

    // إذا كان العمود قائمة منسدلة (Select Column)
    if (selectItems != null) {
      dynamic chosenVal;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تعبئة ${selectedPositions.length} خلايا محددة لـ ($title)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر القيمة التي ترغب في تطبيقها على جميع الخلايا المحددة:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: selectItems.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
                onChanged: (v) => chosenVal = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                if (chosenVal != null) {
                  for (final pos in selectedPositions) {
                    final row = _stateManager!.getRowByIdx(pos.rowIdx);
                    if (row != null && row.cells.containsKey(field)) {
                      _stateManager!.changeCellValue(row.cells[field]!, chosenVal, notify: false);
                    }
                  }
                  _stateManager!.notifyListeners();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت تعبئة ${selectedPositions.length} خلية بالقيمة ($chosenVal)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('تطبيق وتعبئة'),
            ),
          ],
        ),
      );
    } else {
      // عمود نصي عادي
      final textController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تعبئة ${selectedPositions.length} خلايا محددة لـ ($title)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اكتب القيمة المراد تعميمها على الخلايا المحددة:'),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  hintText: 'اكتب القيمة هنا...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () {
                final text = textController.text.trim();
                for (final pos in selectedPositions) {
                  final row = _stateManager!.getRowByIdx(pos.rowIdx);
                  if (row != null && row.cells.containsKey(field)) {
                    _stateManager!.changeCellValue(row.cells[field]!, text, notify: false);
                  }
                }
                _stateManager!.notifyListeners();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تمت تعبئة ${selectedPositions.length} خلية بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('تطبيق وتعبئة'),
            ),
          ],
        ),
      );
    }
  }

  // --- حذف الصفوف المحددة ---

  void _deleteCheckedOrSelectedRows(BuildContext context) {
    if (_stateManager == null) return;

    final checkedRows = _stateManager!.checkedRows;
    if (checkedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد الصفوف المراد حذفها باستخدام مربع الاختيار (#) أولاً'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف ${checkedRows.length} صفاً من الجدول؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              _stateManager!.removeRows(checkedRows);
              // إعادة ترقيم الصفوف
              for (int i = 0; i < _stateManager!.rows.length; i++) {
                _stateManager!.rows[i].cells['no']?.value = '${i + 1}';
              }
              _stateManager!.notifyListeners();
              Navigator.pop(ctx);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // --- حفظ الكل في Supabase ---

  void _saveAllFromGrid(BuildContext context) {
    if (_stateManager == null) return;

    final gridRows = _stateManager!.rows;
    final authState = context.read<AuthCubit>().state;
    String creatorId = '';
    if (authState is AuthSuccess) {
      creatorId = authState.user.id;
    }

    List<LeadModel> leadsToInsert = [];
    List<EditableLeadRow> remainingLeadRows = [];
    List<String> errorMessages = [];
    int skippedNoEmployeeCount = 0;

    for (int i = 0; i < gridRows.length; i++) {
      final cells = gridRows[i].cells;

      final dateStr = cells['createdAt']?.value?.toString().trim();
      final platformName = cells['platform']?.value?.toString().trim();
      final name = cells['name']?.value?.toString().trim();
      final phone = cells['phone']?.value?.toString().trim();
      final assignedToName = cells['assignedTo']?.value?.toString().trim();
      final pCode = cells['propertyCode']?.value?.toString().trim();
      final propTypeName = cells['propertyType']?.value?.toString().trim();
      final listTypeName = cells['listingType']?.value?.toString().trim();
      final areaName = cells['areaName']?.value?.toString().trim();
      final cityName = cells['city']?.value?.toString().trim();

      // تخطي الصفوف الفارغة بالكامل
      final bool isEmptyRow = (name == null || name.isEmpty) &&
          (phone == null || phone.isEmpty) &&
          (pCode == null || pCode.isEmpty) &&
          (areaName == null || areaName.isEmpty);
      if (isEmptyRow) continue;

      // إذا كان الصف بدون موظف، نتخطى إضافته ونتركه في الجدول ليحدده المستخدم بنفسه
      final bool isUnassigned = (assignedToName == null || assignedToName.isEmpty || assignedToName == 'بدون موظف (غير محدد)');
      if (isUnassigned) {
        skippedNoEmployeeCount++;
        final cityId = (cityName != null && cityName.isNotEmpty) ? _cityIdByName[cityName] : null;
        final propTypeId = (propTypeName != null && propTypeName.isNotEmpty) ? (_optionIdByName['property_type'] ?? {})[propTypeName] : null;
        final listTypeId = (listTypeName != null && listTypeName.isNotEmpty) ? (_optionIdByName['listing_type'] ?? {})[listTypeName] : null;
        final platId = (platformName != null && platformName.isNotEmpty) ? (_optionIdByName['platform'] ?? {})[platformName] : null;

        remainingLeadRows.add(EditableLeadRow(
          id: 'rem_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: name,
          phone: phone,
          createdAt: (dateStr != null && dateStr.isNotEmpty) ? DateTime.tryParse(dateStr.replaceAll('/', '-')) : null,
          propertyCode: pCode,
          areaName: areaName,
          cityId: cityId,
          unmappedCity: (cityId == null && cityName != null && cityName.isNotEmpty) ? cityName : null,
          propertyTypeId: propTypeId,
          unmappedPropertyType: (propTypeId == null && propTypeName != null && propTypeName.isNotEmpty) ? propTypeName : null,
          listingTypeId: listTypeId,
          unmappedListingType: (listTypeId == null && listTypeName != null && listTypeName.isNotEmpty) ? listTypeName : null,
          platformId: platId,
          assignedTo: null,
          unmappedAssignedTo: 'بدون موظف (غير محدد)',
        ));
        continue;
      }

      // التحقق من المتطلبات
      List<String> missing = [];
      if (phone == null || phone.isEmpty) {
        missing.add('رقم الهاتف');
      } else if (phone.contains(',') || phone.contains(' ')) {
        missing.add('رقم الهاتف (بدون مسافات)');
      }

      if (platformName == null || platformName.isEmpty) missing.add('اسم المنصة');

      if (missing.isNotEmpty) {
        errorMessages.add('الصف ${i + 1}: ينقصه (${missing.join('، ')})');
        continue;
      }

      // تحويل القيم إلى IDs
      final cityId = (cityName != null && cityName.isNotEmpty) ? _cityIdByName[cityName] : null;
      final propTypeId = (propTypeName != null && propTypeName.isNotEmpty) ? (_optionIdByName['property_type'] ?? {})[propTypeName] : null;
      final listTypeId = (listTypeName != null && listTypeName.isNotEmpty) ? (_optionIdByName['listing_type'] ?? {})[listTypeName] : null;
      final platId = (platformName != null && platformName.isNotEmpty) ? (_optionIdByName['platform'] ?? {})[platformName] : null;
      final chanId = (_optionIdByName['communication_channel'] ?? {})['مكالمة هاتفية'] ?? 
                     (_optionIdByName['communication_channel'] ?? {})['واتساب'];
      final statusMap = _optionIdByName['lead_status'] ?? {};
      final statId = statusMap['لم يتم التواصل معه'] ?? 
                     statusMap['لم يتم التواصل'] ?? 
                     statusMap['جديد'] ?? 
                     statusMap['تم التواصل اول مرة'] ?? 
                     '460be748-7685-49ef-abcf-c4dd49511ab7';
      // تحويل اسم الموظف إلى ID مع دعم case-insensitive
      String? assignedToId;
      if (assignedToName.isNotEmpty) {
        assignedToId = _employeeIdByName[assignedToName];
        if (assignedToId == null) {
          final cleanAssigned = assignedToName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          for (var entry in _employeeIdByName.entries) {
            if (entry.key.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') == cleanAssigned) {
              assignedToId = entry.value;
              break;
            }
          }
        }
      }

      if (assignedToId == null) {
        errorMessages.add('الصف ${i + 1}: لم يتم التعرف على الموظف ($assignedToName)');
        continue;
      }

      DateTime? parsedDate;
      if (dateStr != null && dateStr.isNotEmpty) {
        parsedDate = DateTime.tryParse(dateStr.replaceAll('/', '-'));
      }

      final lead = LeadModel(
        clientName: (name != null && name.isNotEmpty) ? name : 'بدون اسم',
        phones: [LeadPhoneModel(phoneNumber: phone!, isPrimary: true)],
        createdBy: creatorId,
        assignedTo: assignedToId,
        createdAt: parsedDate ?? DateTime.now().toLocal(),
        cityId: cityId,
        propertyTypeId: propTypeId,
        listingTypeId: listTypeId,
        platformId: platId,
        channelId: chanId,
        statusId: statId,
        propertyCode: pCode?.toUpperCase(),
        areaName: areaName,
        descLeadNeed: null,
        budgetFrom: null,
        budgetTo: null,
        notes: [],
      );

      leadsToInsert.add(lead);
    }

    if (errorMessages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه: أخطاء في البيانات'),
          content: SizedBox(
            width: 450,
            height: 300,
            child: ListView(
              children: errorMessages.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('• $e', style: const TextStyle(color: Colors.red, fontSize: 13)),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق وتصحيح')),
          ],
        ),
      );
      return;
    }

    if (leadsToInsert.isEmpty) {
      if (skippedNoEmployeeCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لم يتم حفظ أي عميل لأن هناك $skippedNoEmployeeCount عميل بدون موظف. يرجى تحديد الموظفين أولاً لحفظهم.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جميع الصفوف فارغة، لا يوجد شيء للحفظ'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    _lastSkippedNoEmployeeCount = skippedNoEmployeeCount;
    // استدعاء خدمة الحفظ الجماعي السريع وتمرير الصفوف المتبقية للإبقاء عليها
    context.read<BulkAddLeadsCubit>().saveLeadsList(leadsToInsert, remainingLeadRows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.table_chart_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('منظومة استيراد وتوحيد العملاء (Excel DataGrid)'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'تحميل القالب الموحد',
            onPressed: () {
              context.read<BulkAddLeadsCubit>().downloadTemplate();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'رفع ملف (Excel أو CSV)',
            onPressed: () {
              context.read<BulkAddLeadsCubit>().uploadFile();
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('حفظ الكل دفعة واحدة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => _saveAllFromGrid(context),
            ),
          ),
        ],
      ),
      body: BlocConsumer<BulkAddLeadsCubit, BulkAddLeadsState>(
        listener: (context, state) {
          if (state is BulkAddLeadsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
          } else if (state is BulkAddLeadsSuccess) {
            final skipped = _lastSkippedNoEmployeeCount;
            _lastSkippedNoEmployeeCount = 0;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(skipped > 0
                    ? 'تم حفظ العملاء بنجاح، وتم الإبقاء على $skipped عميل في الجدول لعدم تحديد موظف لهم.'
                    : 'تم حفظ جميع العملاء بنجاح في قاعدة البيانات!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is BulkAddLeadsLoaded) {
            if (_isGridInitialized) {
              _syncGridWithRows(state.rows);
            }
          }
        },
        builder: (context, state) {
          if (state is BulkAddLeadsLoading) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text(state.message, style: TextStyle(fontSize: 18.sp)),
              ],
            ));
          } else if (state is BulkAddLeadsProgress) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('جاري الحفظ الجماعي: ${state.processed} / ${state.total}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ));
          } else if (state is BulkAddLeadsLoaded) {
            return Column(
              children: [
                if (state.unmappedEmployees.isNotEmpty)
                  _buildDistinctEmployeeMappingBanner(context, state.unmappedEmployees),
                if (state.unmappedLocations.isNotEmpty)
                  _buildDistinctMappingBanner(context, state.unmappedLocations),
                if (state.unmappedPropertyTypes.isNotEmpty)
                  _buildDistinctPropertyTypeMappingBanner(context, state.unmappedPropertyTypes),
                if (state.unmappedListingTypes.isNotEmpty)
                  _buildDistinctListingTypeMappingBanner(context, state.unmappedListingTypes),
                _buildExcelToolbar(context),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: TrinaGrid(
                      columns: _columns,
                      rows: state.rows.map((r) => _createTrinaRowFromLeadRow(r, state.rows.indexOf(r))).toList(),
                      onLoaded: (TrinaGridOnLoadedEvent event) {
                        _stateManager = event.stateManager;
                        _isGridInitialized = true;
                      },
                      configuration: TrinaGridConfiguration(
                        style: TrinaGridStyleConfig(
                          gridBorderColor: Colors.grey.shade400,
                          rowHeight: 44,
                          columnHeight: 44,
                          activatedColor: Colors.green.shade50,
                          activatedBorderColor: Colors.green.shade700,
                          cellTextStyle: const TextStyle(fontSize: 13, color: Colors.black87),
                          columnTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        selectingMode: TrinaGridSelectingMode.cell, // إمكانية تحديد خلايا مفردة أو نطاق بالماوس
                        enableMoveHorizontalInEditing: true,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // --- شريط أدوات الإكسيل (Excel Action Bar) ---

  Widget _buildExcelToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.format_color_fill, size: 18),
            label: const Text('تعبئة الخلايا المحددة (Fill Selected)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => _bulkFillSelectedCells(context),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('إضافة 10 صفوف'),
            onPressed: () {
              if (_stateManager != null) {
                final currentCount = _stateManager!.rows.length;
                final newRows = List.generate(10, (i) => _createEmptyTrinaRow(currentCount + i));
                _stateManager!.appendRows(newRows);
              }
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            label: const Text('حذف الصفوف المحددة', style: TextStyle(color: Colors.red)),
            onPressed: () => _deleteCheckedOrSelectedRows(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  'يدعم السحب لتحديد نطاق خلايا • النسخ (Ctrl+C) واللصق (Ctrl+V) لعدة خلايا دفعة واحدة',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- شريط التنبيه للمطابقة السريعة للمناطق الفريدة ---

  Widget _buildDistinctMappingBanner(BuildContext context, Map<String, int> unmapped) {
    final int totalLeads = unmapped.values.fold(0, (sum, count) => sum + count);

    return Container(
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: يوجد ${unmapped.length} منطقة أو كمبوند فريد غير معروف في النظام ($totalLeads عميل). يمكنك ربطها بالمدن دفعة واحدة بضغطة زر:',
              style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.hub_outlined, size: 16),
            label: const Text('مطابقة سريعة للمدن (Distinct Mapping)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              DistinctMappingDialog.show(
                context,
                unmappedLocations: unmapped,
                onApply: (mapping) {
                  // تحديث الكيوبت
                  context.read<BulkAddLeadsCubit>().applyDistinctMapping(mapping);

                  // تحديث الخلايا المعروضة في TrinaGrid فوراً
                  if (_stateManager != null) {
                    for (final r in _stateManager!.rows) {
                      final areaVal = r.cells['areaName']?.value?.toString().trim();
                      final cityVal = r.cells['city']?.value?.toString().trim();
                      final raw = (areaVal != null && areaVal.isNotEmpty) ? areaVal : cityVal;

                      if (raw != null && mapping.containsKey(raw)) {
                        final cityId = mapping[raw];
                        final cityName = _cityNameById[cityId];
                        if (cityName != null) {
                          _stateManager!.changeCellValue(r.cells['city']!, cityName, notify: false);
                        }
                      }
                    }
                    _stateManager!.notifyListeners();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- شريط التنبيه للمطابقة السريعة للموظفين والأكواد غير المسجلة ---

  Widget _buildDistinctEmployeeMappingBanner(BuildContext context, Map<String, int> unmapped) {
    final int totalLeads = unmapped.values.fold(0, (sum, count) => sum + count);

    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: يوجد ${unmapped.length} كود عقار أو اسم موظف غير مطابق في النظام ($totalLeads عميل). يمكنك إسنادهم لموظفي السيستم بضغطة زر:',
              style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_search_outlined, size: 16),
            label: const Text('مطابقة الموظفين (Employee Mapping)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              DistinctEmployeeMappingDialog.show(
                context,
                unmappedEmployees: unmapped,
                onApply: (mapping) {
                  context.read<BulkAddLeadsCubit>().applyDistinctEmployeeMapping(mapping);

                  if (_stateManager != null) {
                    for (final r in _stateManager!.rows) {
                      final assignedVal = r.cells['assignedTo']?.value?.toString().trim();
                      if (assignedVal != null && mapping.containsKey(assignedVal)) {
                        final userId = mapping[assignedVal];
                        final userName = _employeeNameById[userId];
                        if (userName != null) {
                          _stateManager!.changeCellValue(r.cells['assignedTo']!, userName, notify: false);
                        }
                      }
                    }
                    _stateManager!.notifyListeners();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- شريط التنبيه للمطابقة السريعة لأنواع العقارات غير المعرفة ---

  Widget _buildDistinctPropertyTypeMappingBanner(BuildContext context, Map<String, int> unmapped) {
    final int totalLeads = unmapped.values.fold(0, (sum, count) => sum + count);

    return Container(
      color: Colors.purple.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.home_work_outlined, color: Colors.purple.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: يوجد ${unmapped.length} نوع عقار غير مطابق في النظام ($totalLeads عميل). يمكنك ربطها بأنواع عقارات السيستم بضغطة زر:',
              style: TextStyle(color: Colors.purple.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.category_outlined, size: 16),
            label: const Text('مطابقة نوع العقار (Property Type)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              DistinctLookupMappingDialog.show(
                context,
                title: 'مطابقة أنواع العقارات غير المعرفة',
                category: 'property_type',
                unmappedItems: unmapped,
                onApply: (mapping) {
                  context.read<BulkAddLeadsCubit>().applyDistinctPropertyTypeMapping(mapping);

                  if (_stateManager != null) {
                    for (final r in _stateManager!.rows) {
                      final val = r.cells['propertyType']?.value?.toString().trim();
                      if (val != null && mapping.containsKey(val)) {
                        final optId = mapping[val];
                        final optName = _optionNameById['property_type']?[optId];
                        if (optName != null) {
                          _stateManager!.changeCellValue(r.cells['propertyType']!, optName, notify: false);
                        }
                      }
                    }
                    _stateManager!.notifyListeners();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- شريط التنبيه للمطابقة السريعة لأنواع الإعلانات غير المعرفة ---

  Widget _buildDistinctListingTypeMappingBanner(BuildContext context, Map<String, int> unmapped) {
    final int totalLeads = unmapped.values.fold(0, (sum, count) => sum + count);

    return Container(
      color: Colors.teal.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.sell_outlined, color: Colors.teal.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: يوجد ${unmapped.length} نوع إعلان غير مطابق في النظام ($totalLeads عميل). يمكنك ربطها بأنواع إعلانات السيستم بضغطة زر:',
              style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.style_outlined, size: 16),
            label: const Text('مطابقة نوع الإعلان (Listing Type)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              DistinctLookupMappingDialog.show(
                context,
                title: 'مطابقة أنواع الإعلانات غير المعرفة',
                category: 'listing_type',
                unmappedItems: unmapped,
                onApply: (mapping) {
                  context.read<BulkAddLeadsCubit>().applyDistinctListingTypeMapping(mapping);

                  if (_stateManager != null) {
                    for (final r in _stateManager!.rows) {
                      final val = r.cells['listingType']?.value?.toString().trim();
                      if (val != null && mapping.containsKey(val)) {
                        final optId = mapping[val];
                        final optName = _optionNameById['listing_type']?[optId];
                        if (optName != null) {
                          _stateManager!.changeCellValue(r.cells['listingType']!, optName, notify: false);
                        }
                      }
                    }
                    _stateManager!.notifyListeners();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
