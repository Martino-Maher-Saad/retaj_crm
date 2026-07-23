import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_states.dart';
import '../cubit/bulk_add_leads_cubit.dart';
import '../cubit/bulk_add_leads_state.dart';

class BulkAddLeadsScreen extends StatelessWidget {
  const BulkAddLeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<BulkAddLeadsCubit>(),
      child: const _BulkAddLeadsView(),
    );
  }
}

class _BulkAddLeadsView extends StatefulWidget {
  const _BulkAddLeadsView({super.key});

  @override
  State<_BulkAddLeadsView> createState() => _BulkAddLeadsViewState();
}

class _BulkAddLeadsViewState extends State<_BulkAddLeadsView> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  late List<DropdownMenuEntry<int>> _cityEntries;
  late List<DropdownMenuEntry<String>> _employeeEntries;
  late Map<String, List<DropdownMenuEntry<String>>> _optionEntries;

  @override
  void initState() {
    super.initState();
    final dataManager = sl<StaticDataManager>();
    _cityEntries = dataManager.allCities.map((c) => DropdownMenuEntry<int>(value: c.id, label: c.name)).toList();
    _employeeEntries = dataManager.employees.map((e) => DropdownMenuEntry<String>(value: e.id, label: '${e.firstName} ${e.lastName}'.trim())).toList();
    _optionEntries = {
      'property_type': dataManager.getOptionModels('property_type').map((o) => DropdownMenuEntry<String>(value: o.id, label: o.nameAr)).toList(),
      'listing_type': dataManager.getOptionModels('listing_type').map((o) => DropdownMenuEntry<String>(value: o.id, label: o.nameAr)).toList(),
      'platform': dataManager.getOptionModels('platform').map((o) => DropdownMenuEntry<String>(value: o.id, label: o.nameAr)).toList(),
      'communication_channel': dataManager.getOptionModels('communication_channel').map((o) => DropdownMenuEntry<String>(value: o.id, label: o.nameAr)).toList(),
      'lead_status': dataManager.getOptionModels('lead_status').map((o) => DropdownMenuEntry<String>(value: o.id, label: o.nameAr)).toList(),
    };
  }

  static const Map<String, String> _columnLabels = {
    'name': 'اسم العميل',
    'phone': 'رقم الهاتف (إجباري)',
    'cityId': 'المدينة (إجباري)',
    'propertyTypeId': 'نوع العقار (إجباري)',
    'listingTypeId': 'نوع الإعلان (إجباري)',
    'platformId': 'المنصة (إجباري)',
    'channelId': 'طريقة التواصل',
    'statusId': 'حالة العميل',
    'assignedTo': 'الموظف المسند إليه (إجباري)',
    'propertyCode': 'كود العقار',
    'createdAt': 'تاريخ الإضافة',
    'descLeadNeed': 'متطلبات العميل',
    'budgetFrom': 'ميزانية من',
    'budgetTo': 'ميزانية إلى',
    'notes': 'ملاحظات'
  };

  void _showReorderColumnsDialog(BuildContext context) {
    final cubit = context.read<BulkAddLeadsCubit>();
    if (cubit.state is! BulkAddLeadsLoaded) return;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return BlocProvider.value(
          value: cubit,
          child: AlertDialog(
            title: const Text('ترتيب الخانات'),
            content: SizedBox(
              width: 350,
              height: 500,
              child: BlocBuilder<BulkAddLeadsCubit, BulkAddLeadsState>(
                builder: (context, state) {
                  if (state is! BulkAddLeadsLoaded) return const SizedBox();
                  return ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      context.read<BulkAddLeadsCubit>().reorderColumns(oldIndex, newIndex);
                    },
                    children: state.columnOrder.map((key) {
                      return ListTile(
                        key: ValueKey(key),
                        title: Text(_columnLabels[key] ?? ''),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة عملاء متعددين / رفع إكسيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_column),
            tooltip: 'ترتيب الأعمدة',
            onPressed: () => _showReorderColumnsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'تحميل القالب',
            onPressed: () {
              context.read<BulkAddLeadsCubit>().downloadTemplate();
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'رفع ملف إكسيل',
            onPressed: () {
              context.read<BulkAddLeadsCubit>().uploadExcelFile();
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('حفظ الكل'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                FocusScope.of(context).unfocus();
                final authState = context.read<AuthCubit>().state;
                if (authState is AuthSuccess) {
                  context.read<BulkAddLeadsCubit>().saveAll(authState.user.id);
                }
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<BulkAddLeadsCubit, BulkAddLeadsState>(
        listener: (context, state) {
          if (state is BulkAddLeadsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
          } else if (state is BulkAddLeadsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح!'), backgroundColor: Colors.green));
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
                Text('جاري الحفظ: ${state.processed} / ${state.total}', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ));
          } else if (state is BulkAddLeadsLoaded) {
            return _buildGrid(context, state.rows, state.columnOrder);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<BulkAddLeadsCubit>().addEmptyRows(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة 10 صفوف'),
        tooltip: 'إضافة 10 صفوف فارغة للجدول',
      ),
    );
  }

  double _getColumnWidth(String key) {
    if (key == 'descLeadNeed' || key == 'notes') return 220;
    if (key == 'propertyTypeId' || key == 'listingTypeId' || key == 'platformId' || key == 'channelId' || key == 'statusId' || key == 'assignedTo' || key == 'cityId') return 180;
    return 140; 
  }

  Widget _buildHeaderCell(BuildContext context, String key) {
    final bool isDropdown = ['cityId', 'propertyTypeId', 'listingTypeId', 'platformId', 'channelId', 'statusId', 'assignedTo'].contains(key);
    final pinnedValues = (context.read<BulkAddLeadsCubit>().state as BulkAddLeadsLoaded).pinnedValues;
    final isPinned = pinnedValues.containsKey(key);

    return Container(
      width: _getColumnWidth(key),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade400)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Text(_columnLabels[key] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14), textAlign: TextAlign.center)),
          if (isDropdown)
            InkWell(
              onTap: () => _showPinDialog(context, key),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.push_pin, size: 16, color: isPinned ? Colors.blue : Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, String key) {
    final cubit = context.read<BulkAddLeadsCubit>();
    
    String title = _columnLabels[key] ?? '';
    dynamic selectedValue = (cubit.state as BulkAddLeadsLoaded).pinnedValues[key];
    
    List<DropdownMenuEntry<dynamic>> entries = [];
    if (key == 'cityId') {
      entries = _cityEntries;
    } else if (key == 'assignedTo') {
      entries = _employeeEntries;
    } else {
      String tableName = '';
      if (key == 'propertyTypeId') tableName = 'property_type';
      else if (key == 'listingTypeId') tableName = 'listing_type';
      else if (key == 'platformId') tableName = 'platform';
      else if (key == 'channelId') tableName = 'communication_channel';
      else if (key == 'statusId') tableName = 'lead_status';
      entries = _optionEntries[tableName] ?? [];
    }

    showDialog(
      context: context,
      builder: (ctx) {
        dynamic tempValue = selectedValue;
        return AlertDialog(
          title: Text('تثبيت قيمة لـ ($title)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('القيمة المحددة سيتم تطبيقها على جميع الصفوف فوراً وللصفوف الجديدة.'),
              const SizedBox(height: 16),
              DropdownMenu<dynamic>(
                initialSelection: tempValue,
                enableFilter: true,
                requestFocusOnTap: true,
                width: 250,
                menuHeight: 200,
                dropdownMenuEntries: entries,
                onSelected: (v) => tempValue = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cubit.pinColumnValue(key, null);
                Navigator.pop(ctx);
              },
              child: const Text('إلغاء التثبيت', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                cubit.pinColumnValue(key, tempValue);
                Navigator.pop(ctx);
              },
              child: const Text('تطبيق وتثبيت'),
            ),
          ],
        );
      }
    );
  }



  Widget _buildGrid(BuildContext context, List<EditableLeadRow> rows, List<String> columnOrder) {
    final double totalWidth = columnOrder.fold(0.0, (sum, key) => sum + _getColumnWidth(key)) + 50.0; // +50 for index column

    return Scrollbar(
      controller: _verticalScrollController, // Put vertical scrollbar OUTSIDE!
      thumbVisibility: true,
      thickness: 10,
      radius: const Radius.circular(8),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        thickness: 10,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth + 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.grey[300],
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade400))),
                          child: const Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        ...columnOrder.map((key) => _buildHeaderCell(context, key)).toList(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _verticalScrollController,
                      itemCount: rows.length,
                      itemExtent: 64.0,
                      itemBuilder: (ctx, i) => _buildCustomDataRow(ctx, rows[i], i, columnOrder),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseCustomDate(String text) {
    text = text.trim();
    if (text.isEmpty) return null;
    var d = DateTime.tryParse(text);
    if (d != null) return d;
    final parts = text.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      int? p1 = int.tryParse(parts[0]);
      int? p2 = int.tryParse(parts[1]);
      int? p3 = int.tryParse(parts[2]);
      if (p1 != null && p2 != null && p3 != null) {
        if (p3 > 1000) {
          if (p2 > 12 && p1 <= 12) return DateTime(p3, p1, p2);
          return DateTime(p3, p2, p1);
        } else if (p1 > 1000) {
          return DateTime(p1, p2, p3);
        }
      }
    }
    return null;
  }

  Widget _buildCustomDataRow(BuildContext context, EditableLeadRow row, int index, List<String> columnOrder) {
    final cubit = context.read<BulkAddLeadsCubit>();
    final bool hasError = !row.isValid && !row.isEmpty;

    Widget buildTextField(String? initial, Function(String) onChanged, {required String cellKey, double width = 140, TextInputType type = TextInputType.text}) {
      return _ExcelTextField(
        key: ValueKey('${row.id}_$cellKey'),
        initialValue: initial ?? '',
        type: type,
        onChanged: onChanged,
        width: width,
      );
    }

    Widget buildDateField(DateTime? initial, Function(DateTime?) onChanged, {required String cellKey}) {
      return _ExcelTextField(
        key: ValueKey('${row.id}_$cellKey'),
        initialValue: initial != null ? initial.toIso8601String().split('T')[0] : '',
        type: TextInputType.datetime,
        width: 140,
        hintText: 'مثال: 22/7/2026',
        onChanged: (v) {
          if (v.isEmpty) onChanged(null);
          else {
            final d = _parseCustomDate(v);
            if (d != null) onChanged(d);
          }
        },
      );
    }

    final cellsMap = {
      'name': buildTextField(row.name, (v) => cubit.updateRow(row.copyWith(name: v)), cellKey: 'name'),
      'phone': buildTextField(row.phone, (v) => cubit.updateRow(row.copyWith(phone: v)), type: TextInputType.phone, cellKey: 'phone'),
      'cityId': _DropdownCell<int>(label: _columnLabels['cityId']!, value: row.cityId, unmappedValue: row.unmappedCity, entries: _cityEntries, onChanged: (v) => cubit.updateRow(row.copyWith(cityId: v, unmappedCity: null))),
      'propertyTypeId': _DropdownCell<String>(label: _columnLabels['propertyTypeId']!, value: row.propertyTypeId, unmappedValue: row.unmappedPropertyType, entries: _optionEntries['property_type'] ?? [], onChanged: (v) => cubit.updateRow(row.copyWith(propertyTypeId: v, unmappedPropertyType: null))),
      'listingTypeId': _DropdownCell<String>(label: _columnLabels['listingTypeId']!, value: row.listingTypeId, unmappedValue: row.unmappedListingType, entries: _optionEntries['listing_type'] ?? [], onChanged: (v) => cubit.updateRow(row.copyWith(listingTypeId: v, unmappedListingType: null))),
      'platformId': _DropdownCell<String>(label: _columnLabels['platformId']!, value: row.platformId, unmappedValue: row.unmappedPlatform, entries: _optionEntries['platform'] ?? [], onChanged: (v) => cubit.updateRow(row.copyWith(platformId: v, unmappedPlatform: null))),
      'channelId': _DropdownCell<String>(label: _columnLabels['channelId']!, value: row.channelId, unmappedValue: row.unmappedChannel, entries: _optionEntries['communication_channel'] ?? [], onChanged: (v) => cubit.updateRow(row.copyWith(channelId: v, unmappedChannel: null))),
      'statusId': _DropdownCell<String>(label: _columnLabels['statusId']!, value: row.statusId, unmappedValue: row.unmappedStatus, entries: _optionEntries['lead_status'] ?? [], onChanged: (v) => cubit.updateRow(row.copyWith(statusId: v, unmappedStatus: null))),
      'assignedTo': _DropdownCell<String>(label: _columnLabels['assignedTo']!, value: row.assignedTo, unmappedValue: row.unmappedAssignedTo, entries: _employeeEntries, onChanged: (v) => cubit.updateRow(row.copyWith(assignedTo: v, unmappedAssignedTo: null))),
      'propertyCode': buildTextField(row.propertyCode, (v) => cubit.updateRow(row.copyWith(propertyCode: v)), cellKey: 'propertyCode'),
      'createdAt': buildDateField(row.createdAt, (v) => cubit.updateRow(row.copyWith(createdAt: v)), cellKey: 'createdAt'),
      'descLeadNeed': buildTextField(row.descLeadNeed, (v) => cubit.updateRow(row.copyWith(descLeadNeed: v)), width: 220, type: TextInputType.multiline, cellKey: 'descLeadNeed'),
      'budgetFrom': buildTextField(row.budgetFrom, (v) => cubit.updateRow(row.copyWith(budgetFrom: v)), type: TextInputType.number, cellKey: 'budgetFrom'),
      'budgetTo': buildTextField(row.budgetTo, (v) => cubit.updateRow(row.copyWith(budgetTo: v)), type: TextInputType.number, cellKey: 'budgetTo'),
      'notes': buildTextField(row.notes, (v) => cubit.updateRow(row.copyWith(notes: v)), width: 220, type: TextInputType.multiline, cellKey: 'notes'),
    };

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: hasError ? Colors.red.withValues(alpha: 0.05) : null,
        border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(left: BorderSide(color: Colors.grey.shade400)),
            ),
            child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ...columnOrder.map((key) {
            return Container(
              width: _getColumnWidth(key),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade400)),
              ),
              child: cellsMap[key]!,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _ExcelTextField extends StatefulWidget {
  final String initialValue;
  final TextInputType type;
  final Function(String) onChanged;
  final double width;
  final String? hintText;

  const _ExcelTextField({
    super.key,
    required this.initialValue,
    required this.type,
    required this.onChanged,
    required this.width,
    this.hintText,
  });

  @override
  State<_ExcelTextField> createState() => _ExcelTextFieldState();
}

class _ExcelTextFieldState extends State<_ExcelTextField> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialValue);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        if (_textController.text != widget.initialValue) {
          widget.onChanged(_textController.text);
        }
      }
    });
  }

  @override
  void didUpdateWidget(_ExcelTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && widget.initialValue != _textController.text) {
      _textController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextFormField(
        controller: _textController,
        keyboardType: widget.type,
        scrollController: _scrollController,
        onChanged: (v) => widget.onChanged(v),
        style: const TextStyle(fontSize: 14),
        maxLines: widget.type == TextInputType.multiline ? null : 1,
        expands: widget.type == TextInputType.multiline,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          hintText: widget.hintText,
          hintStyle: widget.hintText != null ? const TextStyle(fontSize: 12) : null,
        ),
      ),
    );
  }
}

class _DropdownCell<T> extends StatefulWidget {
  final String label;
  final T? value;
  final String? unmappedValue;
  final List<DropdownMenuEntry<T>> entries;
  final Function(T?) onChanged;

  const _DropdownCell({
    required this.label,
    required this.value,
    this.unmappedValue,
    required this.entries,
    required this.onChanged,
  });

  @override
  State<_DropdownCell<T>> createState() => _DropdownCellState<T>();
}

class _DropdownCellState<T> extends State<_DropdownCell<T>> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final bool isError = widget.value == null && widget.unmappedValue != null;
    
    if (!_isEditing) {
      String displayLabel = '';
      if (widget.value != null) {
        final entry = widget.entries.where((e) => e.value == widget.value).firstOrNull;
        displayLabel = entry?.label ?? '';
      } else if (isError) {
        displayLabel = 'غير معروف (${widget.unmappedValue})';
      }

      return InkWell(
        onTap: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: Container(
          width: 180,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: isError ? Colors.red.withValues(alpha: 0.1) : null,
          alignment: Alignment.centerRight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: (widget.value == null && !isError) ? Colors.grey : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 180,
      height: 64,
      color: isError ? Colors.red.withValues(alpha: 0.1) : Colors.white,
      child: DropdownMenu<T>(
        initialSelection: widget.value,
        enableFilter: true,
        requestFocusOnTap: true,
        width: 180,
        menuHeight: 200,
        textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 15),
        ),
        dropdownMenuEntries: widget.entries,
        onSelected: (val) {
          widget.onChanged(val);
          setState(() {
            _isEditing = false;
          });
        },
      ),
    );
  }
}
