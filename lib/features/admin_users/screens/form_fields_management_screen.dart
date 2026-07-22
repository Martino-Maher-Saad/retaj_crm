import 'dart:convert';
import 'package:flutter/cupertino.dart' hide FormFieldState;
import 'package:flutter/material.dart' hide FormFieldState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/core/constants/app_colors.dart';
import 'package:retaj_crm/core/widgets/retaj_page_header.dart';
import '../../../data/models/form_field_model.dart';
import '../cubit/form_field_cubit.dart';
import '../cubit/form_field_state.dart';

class FormFieldsManagementScreen extends StatefulWidget {
  const FormFieldsManagementScreen({super.key});

  @override
  State<FormFieldsManagementScreen> createState() => _FormFieldsManagementScreenState();
}

class _FormFieldsManagementScreenState extends State<FormFieldsManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FormFieldCubit>().fetchFields(entityType: 'lead');
  }

  void _showFieldDialog([FormFieldModel? field]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: context.read<FormFieldCubit>(),
        child: _FieldEditorDialog(field: field),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      body: Column(
        children: [
          RetajPageHeader(
            title: 'ادارة الحقول الديناميكية (Lead Inputs)',
            subtitle: 'التحكم في الحقول التي تظهر في نماذج العملاء وصلاحيات كل دور لرؤيتها وترتيبها',
            addLabel: 'إضافة حقل جديد',
            onAdd: () => _showFieldDialog(),
          ),
          Expanded(
            child: BlocConsumer<FormFieldCubit, FormFieldState>(
              listener: (context, state) {
                if (state is FormFieldActionSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                  );
                } else if (state is FormFieldError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                if (state is FormFieldLoading) return const Center(child: CircularProgressIndicator());
                
                if (state is FormFieldError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
                          SizedBox(height: 16.h),
                          Text('حدث خطأ أثناء جلب الحقول من قاعدة البيانات:', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8.h),
                          Text(state.message, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 14.sp)),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: () => context.read<FormFieldCubit>().fetchFields(entityType: 'lead'),
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          )
                        ],
                      ),
                    ),
                  );
                }

                if (state is FormFieldLoaded) {
                  final fields = state.fields;
                  if (fields.isEmpty) return const Center(child: Text('لا توجد حقول حتى الان.'));
                  return ReorderableListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: fields.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = fields.removeAt(oldIndex);
                      fields.insert(newIndex, item);
                      final updates = fields.asMap().entries
                          .map((e) => {'id': e.value.id, 'field_order': e.key + 1})
                          .toList();
                      context.read<FormFieldCubit>().reorderFields(updates);
                    },
                    itemBuilder: (context, index) {
                      final field = fields[index];
                      return _FieldCard(
                        key: ValueKey(field.id),
                        field: field,
                        index: index + 1,
                        onEdit: () => _showFieldDialog(field),
                        onDelete: field.isSystem ? null : () => context.read<FormFieldCubit>().deleteField(field.id),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final FormFieldModel field;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _FieldCard({super.key, required this.field, required this.index, required this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: field.isSystem ? Colors.grey.shade200 : AppColors.brandPrimary.withValues(alpha: 0.1),
          child: Text('$index', style: TextStyle(color: field.isSystem ? Colors.grey.shade700 : AppColors.brandPrimary, fontWeight: FontWeight.bold)),
        ),
        title: Row(children: [
          Icon(field.isSystem ? Icons.lock_outline : Icons.edit_note, size: 16, color: field.isSystem ? Colors.grey : AppColors.brandAccent),
          SizedBox(width: 6.w),
          Text(field.titleAr, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (field.titleEn.isNotEmpty) ...[SizedBox(width: 8.w), Text('/ ${field.titleEn}', style: TextStyle(color: Colors.grey, fontSize: 12.sp))],
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4.r)),
            child: Text(field.fieldKey, style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade700, fontFamily: 'monospace')),
          ),
        ]),
        subtitle: Wrap(spacing: 6.w, runSpacing: 4.h, children: [
          _badge(field.inputType.labelAr, Colors.blue),
          if (field.refTable != null) _badge('<- ${kAllowedRefTables[field.refTable] ?? field.refTable!}', Colors.teal),
          if (field.options.isNotEmpty) _badge('${field.options.length} خيار', Colors.orange),
          if (field.isRequired) _badge('اجباري', Colors.red),
          if (!field.isActive) _badge('معطل', Colors.grey),
          if (field.isShowSales) _badge('Sales', AppColors.brandPrimary),
          if (field.isShowTeamLeader) _badge('Leader', AppColors.brandPrimary),
          if (field.isShowManager) _badge('Manager', AppColors.brandPrimary),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: onEdit),
          if (onDelete != null) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          const Icon(Icons.drag_handle, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        margin: EdgeInsets.only(top: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4.r), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Text(text, style: TextStyle(fontSize: 10.sp, color: color)),
      );
}

class _FieldEditorDialog extends StatefulWidget {
  final FormFieldModel? field;
  const _FieldEditorDialog({this.field});

  @override
  State<_FieldEditorDialog> createState() => _FieldEditorDialogState();
}

class _FieldEditorDialogState extends State<_FieldEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleArCtrl, _titleEnCtrl, _keyCtrl, _orderCtrl;
  late FormFieldInputType _inputType;
  String? _refTable;
  List<FieldOption> _staticOptions = [];
  bool _isShowSales = true, _isShowLeader = true, _isShowManager = true;
  bool _isRequired = false, _isEditableSales = true, _isEditableLeader = true, _isEditableManager = true, _showInForm = true;
  bool _showInCard = false, _canFilter = false, _isExportable = true;

  bool get _isEdit => widget.field != null;
  bool get _isSystem => widget.field?.isSystem ?? false;
  
  // حقول النظام الأساسية التي لا يمكن الاستغناء عنها وتعتبر NOT NULL في الداتابيز
  bool get _isStrictMandatory => const ['client_name', 'phones', 'phone_primary', 'lead_status', 'assigned_to', 'listing_type_id', 'property_type_id', 'city_id', 'platform_id'].contains(widget.field?.fieldKey);

  @override
  void initState() {
    super.initState();
    final f = widget.field;
    _titleArCtrl = TextEditingController(text: f?.titleAr ?? '');
    _titleEnCtrl = TextEditingController(text: f?.titleEn ?? '');
    _keyCtrl = TextEditingController(text: f?.fieldKey ?? '');
    _inputType = f?.inputType ?? FormFieldInputType.text;
    _refTable = f?.refTable;
    _staticOptions = List.from(f?.options ?? []);
    final originalOptions = List<FieldOption>.from(f?.options ?? []);
    
    final cubit = context.read<FormFieldCubit>();
    int currentOrder = f?.fieldOrder ?? 99;
    if (f == null && cubit.state is FormFieldLoaded) {
      currentOrder = (cubit.state as FormFieldLoaded).fields.length + 1;
    }
    _orderCtrl = TextEditingController(text: currentOrder.toString());

    if (f != null) {
      _isShowSales = f.isShowSales; _isShowLeader = f.isShowTeamLeader; _isShowManager = f.isShowManager;
      _isRequired = f.isRequired; 
      _isEditableSales = f.isEditableSales; _isEditableLeader = f.isEditableTeamLeader; _isEditableManager = f.isEditableManager;
      _showInForm = f.showInForm;
      _showInCard = f.showInCard; _canFilter = f.canFilter; _isExportable = f.isExportable;
    }
    
    if (_isStrictMandatory) {
      _isRequired = true;
      _showInForm = true;
      _isShowSales = true;
      _isShowLeader = true;
      _isShowManager = true;
    }
  }

  @override
  void dispose() { _titleArCtrl.dispose(); _titleEnCtrl.dispose(); _keyCtrl.dispose(); _orderCtrl.dispose(); super.dispose(); }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_isStrictMandatory) {
      _isRequired = true;
      _showInForm = true;
      _isShowSales = true;
      _isShowLeader = true;
      _isShowManager = true;
    }

    final data = <String, dynamic>{
      'title': _titleArCtrl.text.trim(),
      'title_en': _titleEnCtrl.text.trim(),
      'is_show_sales': _isShowSales, 'is_show_team_leader': _isShowLeader, 'is_show_manager': _isShowManager,
      'is_required': _isRequired,
      'is_editable_sales': _isEditableSales,
      'is_editable_team_leader': _isEditableLeader,
      'is_editable_manager': _isEditableManager,
      'show_in_form': _showInForm,
      'show_in_card': _showInCard,
      'can_filter': _canFilter,
      'is_exportable': _isExportable,
    };
    
    if (!_isSystem) {
      data['input_type'] = _inputType.toDbString();
      data['options'] = _inputType == FormFieldInputType.selectStatic && _staticOptions.isNotEmpty ? _staticOptions.map((o) => o.toJson()).toList() : null;
      data['ref_table'] = _inputType == FormFieldInputType.selectRef ? _refTable : null;
    }
    
    if (!_isEdit) { 
      data['field_key'] = _keyCtrl.text.trim(); 
      data['entity_type'] = 'lead'; 
      data['is_system'] = false; 
    }
    
    final cubit = context.read<FormFieldCubit>();
    final state = cubit.state;
    List<FormFieldModel> currentFields = [];
    if (state is FormFieldLoaded) currentFields = List.from(state.fields);

    int newOrder = int.tryParse(_orderCtrl.text.trim()) ?? (_isEdit ? widget.field!.fieldOrder : currentFields.length + 1);
    if (newOrder < 1) newOrder = 1;
    final maxOrder = _isEdit ? currentFields.length : currentFields.length + 1;
    if (newOrder > maxOrder) newOrder = maxOrder;
    
    if (_isEdit) {
      if (widget.field!.fieldOrder != newOrder) {
        final oldIndex = currentFields.indexWhere((f) => f.id == widget.field!.id);
        if (oldIndex != -1) {
          final item = currentFields.removeAt(oldIndex);
          currentFields.insert(newOrder - 1, item);
          final updates = currentFields.asMap().entries.map((e) => {'id': e.value.id, 'field_order': e.key + 1}).toList();
          cubit.updateField(widget.field!.id, data).then((_) {
            cubit.reorderFields(updates);
          });
          Navigator.pop(context);
          return;
        }
      }
      cubit.updateField(widget.field!.id, data);
    } else {
      data['field_order'] = currentFields.length + 1;
      cubit.addField(data).then((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        final newState = cubit.state;
        if (newState is FormFieldLoaded) {
           var latestFields = List<FormFieldModel>.from(newState.fields);
           final newIndex = latestFields.indexWhere((f) => f.fieldKey == data['field_key']);
           if (newIndex != -1 && newOrder <= latestFields.length) {
              final item = latestFields.removeAt(newIndex);
              latestFields.insert(newOrder - 1, item);
              final updates = latestFields.asMap().entries.map((e) => {'id': e.value.id, 'field_order': e.key + 1}).toList();
              cubit.reorderFields(updates);
           }
        }
      });
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Container(
        width: 700.w,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Icon(Icons.people_outline, color: Colors.grey.shade600, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEdit ? 'Edit Lead Input' : 'Add Lead Input', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        SizedBox(height: 4.h),
                        Text(_isEdit ? 'تعديل بيانات الحقل (${widget.field!.titleAr})' : 'إضافة حقل جديد لبيانات العملاء.', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade500),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isSystem) ...[
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.blue.withValues(alpha: 0.2))),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20.sp), SizedBox(width: 12.w),
                              Expanded(child: Text('هذا حقل أساسي (System Field). مفتاحه ونوعه محميان برمجياً لتجنب الأعطال.', style: TextStyle(color: Colors.blue.shade800, fontSize: 13.sp, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                      if (_isStrictMandatory) ...[
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.orange.withValues(alpha: 0.2))),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20.sp), SizedBox(width: 12.w),
                              Expanded(child: Text('هذا الحقل إجباري في قاعدة البيانات. تم فرض ظهوره وإلزاميته لجميع الموظفين.', style: TextStyle(color: Colors.orange.shade800, fontSize: 13.sp, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],

                      // Row 1: Order and Titles
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100.w,
                            child: _buildInputField(
                              label: 'Order *',
                              child: TextFormField(
                                controller: _orderCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: _inputDecoration(),
                                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _buildInputField(
                              label: 'Title (Ar) *',
                              child: TextFormField(
                                controller: _titleArCtrl,
                                decoration: _inputDecoration(hint: 'اسم الحقل بالعربية'),
                                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _buildInputField(
                              label: 'Title (En)',
                              child: TextFormField(
                                controller: _titleEnCtrl,
                                decoration: _inputDecoration(hint: 'اسم الحقل بالإنجليزية'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Row 2: Field Key and Type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildInputField(
                              label: 'Field Key *',
                              child: TextFormField(
                                controller: _keyCtrl,
                                enabled: !_isSystem && !_isEdit,
                                style: TextStyle(fontFamily: 'monospace', color: (_isSystem || _isEdit) ? Colors.grey.shade600 : null),
                                decoration: _inputDecoration(
                                  hint: 'ex: interest_level',
                                  filled: _isSystem || _isEdit,
                                ),
                                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            flex: 3,
                            child: _buildInputField(
                              label: 'Type *',
                              child: DropdownButtonFormField<FormFieldInputType>(
                                value: _inputType,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
                                decoration: _inputDecoration(),
                                items: FormFieldInputType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.labelAr, style: TextStyle(color: Colors.grey.shade800)))).toList(),
                                onChanged: _isSystem ? null : (v) => setState(() { _inputType = v!; _refTable = null; _staticOptions.clear(); }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_inputType == FormFieldInputType.selectRef) ...[
                        SizedBox(height: 20.h),
                        _buildInputField(
                          label: 'Reference Table *',
                          child: DropdownButtonFormField<String>(
                            value: _refTable,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
                            decoration: _inputDecoration(hint: 'اختر الجدول المصدري'),
                            validator: (v) => v == null ? 'يجب اختيار جدول' : null,
                            items: kAllowedRefTables.entries.map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Row(children: [Text(e.value), SizedBox(width: 8.w), Text('(${e.key})', style: TextStyle(fontSize: 11.sp, color: Colors.grey, fontFamily: 'monospace'))]),
                            )).toList(),
                            onChanged: _isSystem ? null : (v) => setState(() => _refTable = v),
                          ),
                        ),
                      ],
                      
                      if (_inputType == FormFieldInputType.selectStatic) ...[
                        SizedBox(height: 20.h),
                        _StaticOptionsEditor(
                          options: _staticOptions,
                          originalOptions: widget.field?.options ?? const [],
                          onChanged: _isSystem ? (updated){} : (updated) => setState(() => _staticOptions = updated),
                        ),
                      ],

                      SizedBox(height: 32.h),
                      
                      // Switches Grid
                      Wrap(
                        spacing: 24.w,
                        runSpacing: 16.h,
                        children: [
                          _buildSwitchItem('Is Required', _isRequired, _isStrictMandatory ? null : (v) => setState(() => _isRequired = v)),
                          _buildSwitchItem('is system', _isSystem, null), // Always disabled in UI as requested
                          _buildSwitchItem('show in Form', _showInForm, _isStrictMandatory ? null : (v) => setState(() => _showInForm = v)),
                          _buildSwitchItem('show in Card', _showInCard, (v) => setState(() => _showInCard = v)),
                          _buildSwitchItem('Can Filter', _canFilter, (v) => setState(() => _canFilter = v)),
                          _buildSwitchItem('is Exportable', _isExportable, (v) => setState(() => _isExportable = v)),
                          _buildSwitchItem('is Show Sales', _isShowSales, _isStrictMandatory ? null : (v) => setState(() => _isShowSales = v)),
                          _buildSwitchItem('is Show Leader', _isShowLeader, _isStrictMandatory ? null : (v) => setState(() => _isShowLeader = v)),
                          _buildSwitchItem('is Show Manager', _isShowManager, _isStrictMandatory ? null : (v) => setState(() => _isShowManager = v)),
                          _buildSwitchItem('is Editable Sales', _isEditableSales, (v) => setState(() => _isEditableSales = v)),
                          _buildSwitchItem('is Editable Leader', _isEditableLeader, (v) => setState(() => _isEditableLeader = v)),
                          _buildSwitchItem('is Editable Manager', _isEditableManager, (v) => setState(() => _isEditableManager = v)),
                        ],
                      ),
                      
                      SizedBox(height: 32.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                              foregroundColor: Colors.grey.shade600,
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 12.w),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            onPressed: _save,
                            child: Text(_isEdit ? 'Save Changes' : 'Add Input', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.replaceAll(' *', ''),
            style: TextStyle(color: const Color(0xFF2C3E50), fontSize: 13.sp, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
            children: [
              if (label.contains('*')) TextSpan(text: ' *', style: TextStyle(color: Colors.red.shade400)),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, bool filled = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
      filled: filled,
      fillColor: filled ? Colors.grey.shade50 : Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: AppColors.brandPrimary, width: 1.5)),
    );
  }

  Widget _buildSwitchItem(String label, bool value, void Function(bool)? onChanged) {
    return SizedBox(
      width: 280.w, // About 45% of dialog width
      child: Row(
        children: [
          Transform.scale(
            scale: 0.85,
            child: CupertinoSwitch(
              value: value,
              activeColor: AppColors.brandPrimary,
              trackColor: Colors.grey.shade300,
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StaticOptionsEditor extends StatefulWidget {
  final List<FieldOption> options;
  final List<FieldOption> originalOptions;
  final void Function(List<FieldOption>) onChanged;
  const _StaticOptionsEditor({
    required this.options,
    required this.originalOptions,
    required this.onChanged,
  });

  @override
  State<_StaticOptionsEditor> createState() => _StaticOptionsEditorState();
}

class _StaticOptionsEditorState extends State<_StaticOptionsEditor> {
  final _labelCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();

  @override
  void dispose() { _labelCtrl.dispose(); _valueCtrl.dispose(); super.dispose(); }

  void _add() {
    final label = _labelCtrl.text.trim();
    final value = _valueCtrl.text.trim();
    if (label.isEmpty || value.isEmpty) return;
    
    // Prevent adding if value (internal code) already exists
    if (widget.options.any((o) => o.value == value)) return;

    widget.onChanged([...widget.options, FieldOption(label: label, value: value)]);
    _labelCtrl.clear(); _valueCtrl.clear();
  }

  void _editLabelDialog(int index) {
    final option = widget.options[index];
    final editCtrl = TextEditingController(text: option.label);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل الاسم الظاهري', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكود الثابت (لا يتغير): ${option.value}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13.sp, fontFamily: 'monospace')),
            SizedBox(height: 16.h),
            TextField(
              controller: editCtrl,
              decoration: InputDecoration(
                labelText: 'الاسم الظاهري (الجديد)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final newLabel = editCtrl.text.trim();
              if (newLabel.isNotEmpty) {
                final updated = List<FieldOption>.from(widget.options);
                updated[index] = FieldOption(label: newLabel, value: option.value);
                widget.onChanged(updated);
              }
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('إدارة خيارات القائمة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: const Color(0xFF2C3E50))),
      SizedBox(height: 8.h),
      ...widget.options.asMap().entries.map((e) {
        final isOriginal = widget.originalOptions.any((o) => o.value == e.value.value);
        return Container(
          margin: EdgeInsets.only(bottom: 6.h),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6.r), border: Border.all(color: Colors.grey.shade200)),
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
            leading: Text('${e.key + 1}.', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
            title: Text(e.value.label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp)),
            subtitle: Text('الكود الثابت: ${e.value.value}', style: TextStyle(fontFamily: 'monospace', fontSize: 11.sp, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade400, size: 18),
                  tooltip: 'تعديل الاسم',
                  onPressed: () => _editLabelDialog(e.key),
                ),
                if (!isOriginal)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                    tooltip: 'حذف',
                    onPressed: () {
                      final updated = List<FieldOption>.from(widget.options)..removeAt(e.key);
                      widget.onChanged(updated);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
      SizedBox(height: 12.h),
      Row(children: [
        Expanded(flex: 3, child: TextField(controller: _labelCtrl, decoration: InputDecoration(labelText: 'الاسم الظاهري (يظهر للموظف)', hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)), isDense: true))),
        SizedBox(width: 8.w),
        Expanded(flex: 2, child: TextField(controller: _valueCtrl, style: const TextStyle(fontFamily: 'monospace'), decoration: InputDecoration(labelText: 'الكود (إنجليزي - لا يتغير)', hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)), isDense: true))),
        SizedBox(width: 8.w),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black87, elevation: 0, padding: EdgeInsets.symmetric(vertical: 12.h)),
          onPressed: _add,
          child: const Text('إضافة'),
        ),
      ]),
    ]);
  }
}
