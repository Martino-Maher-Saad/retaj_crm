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
    return BlocProvider(
      create: (context) => BulkAddLeadsCubit(),
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
            Navigator.pop(context); 
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

  Widget _buildGrid(BuildContext context, List<EditableLeadRow> rows, List<String> columnOrder) {
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      thickness: 10,
      radius: const Radius.circular(8),
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          thickness: 10,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Container(
              color: Colors.white,
              child: DataTable(
                dataRowMinHeight: 50,
                dataRowMaxHeight: 50,
                headingRowHeight: 55,
                columnSpacing: 0,
                horizontalMargin: 0,
                dividerThickness: 0,
                border: TableBorder.all(color: Colors.grey.shade400, width: 1),
                headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
                columns: columnOrder.map((key) => _excelColumn(_columnLabels[key] ?? '')).toList(),
                rows: rows.map((row) => _buildDataRow(context, row, columnOrder)).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _excelColumn(String label) {
    return DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
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

  DataRow _buildDataRow(BuildContext context, EditableLeadRow row, List<String> columnOrder) {
    final dataManager = sl<StaticDataManager>();
    final cubit = context.read<BulkAddLeadsCubit>();
    final bool hasError = !row.isValid && !row.isEmpty;

    Widget buildTextField(String? initial, Function(String) onChanged, {double width = 140, TextInputType type = TextInputType.text}) {
      return _ExcelTextField(
        initialValue: initial ?? '',
        type: type,
        onChanged: onChanged,
        width: width,
      );
    }

    Widget buildDateField(DateTime? initial, Function(DateTime?) onChanged) {
      return _ExcelTextField(
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

    Widget buildOptionDropdown(String? value, String tableName, String? unmappedValue, Function(String?) onChanged) {
      final options = dataManager.getOptionModels(tableName);
      final isError = value == null && unmappedValue != null;
      return Container(
        width: 180,
        color: isError ? Colors.red.withValues(alpha: 0.1) : null,
        child: DropdownMenu<String>(
          initialSelection: value,
          enableFilter: true,
          requestFocusOnTap: true,
          width: 180,
          hintText: isError ? 'غير معروف' : '',
          textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
          inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          ),
          dropdownMenuEntries: options.map((opt) => DropdownMenuEntry<String>(value: opt.id, label: opt.nameAr)).toList(),
          onSelected: onChanged,
        ),
      );
    }

    Widget buildCityDropdown(int? value, String? unmappedValue, Function(int?) onChanged) {
      final options = dataManager.allCities;
      final isError = value == null && unmappedValue != null;
      return Container(
        width: 180,
        color: isError ? Colors.red.withValues(alpha: 0.1) : null,
        child: DropdownMenu<int>(
          initialSelection: value,
          enableFilter: true,
          requestFocusOnTap: true,
          width: 180,
          hintText: isError ? 'غير معروف' : '',
          textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
          inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          ),
          dropdownMenuEntries: options.map((opt) => DropdownMenuEntry<int>(value: opt.id, label: opt.name)).toList(),
          onSelected: onChanged,
        ),
      );
    }

    Widget buildProfileDropdown(String? value, String? unmappedValue, Function(String?) onChanged) {
      final options = dataManager.employees;
      final isError = value == null && unmappedValue != null;
      return Container(
        width: 180,
        color: isError ? Colors.red.withValues(alpha: 0.1) : null,
        child: DropdownMenu<String>(
          initialSelection: value,
          enableFilter: true,
          requestFocusOnTap: true,
          width: 180,
          hintText: isError ? 'غير معروف' : '',
          textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
          inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 15),
          ),
          dropdownMenuEntries: options.map((opt) => DropdownMenuEntry<String>(value: opt.id, label: '${opt.firstName} ${opt.lastName}'.trim())).toList(),
          onSelected: onChanged,
        ),
      );
    }

    final cellsMap = {
      'name': DataCell(buildTextField(row.name, (v) => cubit.updateRow(row.copyWith(name: v)))),
      'phone': DataCell(buildTextField(row.phone, (v) => cubit.updateRow(row.copyWith(phone: v)), type: TextInputType.phone)),
      'cityId': DataCell(buildCityDropdown(row.cityId, row.unmappedCity, (v) => cubit.updateRow(row.copyWith(cityId: v, unmappedCity: null)))),
      'propertyTypeId': DataCell(buildOptionDropdown(row.propertyTypeId, 'property_type', row.unmappedPropertyType, (v) => cubit.updateRow(row.copyWith(propertyTypeId: v, unmappedPropertyType: null)))),
      'listingTypeId': DataCell(buildOptionDropdown(row.listingTypeId, 'listing_type', row.unmappedListingType, (v) => cubit.updateRow(row.copyWith(listingTypeId: v, unmappedListingType: null)))),
      'platformId': DataCell(buildOptionDropdown(row.platformId, 'platform', row.unmappedPlatform, (v) => cubit.updateRow(row.copyWith(platformId: v, unmappedPlatform: null)))),
      'channelId': DataCell(buildOptionDropdown(row.channelId, 'communication_channel', row.unmappedChannel, (v) => cubit.updateRow(row.copyWith(channelId: v, unmappedChannel: null)))),
      'statusId': DataCell(buildOptionDropdown(row.statusId, 'lead_status', row.unmappedStatus, (v) => cubit.updateRow(row.copyWith(statusId: v, unmappedStatus: null)))),
      'assignedTo': DataCell(buildProfileDropdown(row.assignedTo, row.unmappedAssignedTo, (v) => cubit.updateRow(row.copyWith(assignedTo: v, unmappedAssignedTo: null)))),
      'propertyCode': DataCell(buildTextField(row.propertyCode, (v) => cubit.updateRow(row.copyWith(propertyCode: v)))),
      'createdAt': DataCell(buildDateField(row.createdAt, (v) => cubit.updateRow(row.copyWith(createdAt: v)))),
      'descLeadNeed': DataCell(buildTextField(row.descLeadNeed, (v) => cubit.updateRow(row.copyWith(descLeadNeed: v)), width: 220, type: TextInputType.multiline)),
      'budgetFrom': DataCell(buildTextField(row.budgetFrom, (v) => cubit.updateRow(row.copyWith(budgetFrom: v)), type: TextInputType.number)),
      'budgetTo': DataCell(buildTextField(row.budgetTo, (v) => cubit.updateRow(row.copyWith(budgetTo: v)), type: TextInputType.number)),
      'notes': DataCell(buildTextField(row.notes, (v) => cubit.updateRow(row.copyWith(notes: v)), width: 220, type: TextInputType.multiline)),
    };

    return DataRow(
      color: WidgetStateProperty.all(hasError ? Colors.red.withValues(alpha: 0.05) : null),
      cells: columnOrder.map((key) => cellsMap[key]!).toList(),
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
        focusNode: _focusNode,
        scrollController: _scrollController,
        style: const TextStyle(fontSize: 14),
        maxLines: widget.type == TextInputType.multiline ? null : 1,
        textAlignVertical: TextAlignVertical.center,
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
