import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart' as intl_phone_field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/form_field_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../widgets/forms/dynamic_lead_field.dart';

class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;
  final ProfileModel user;
  final bool isEmbedded;
  final VoidCallback? onSaved;

  const LeadFormScreen({
    super.key,
    this.lead,
    required this.user,
    this.isEmbedded = false,
    this.onSaved,
  });

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dataManager = di.sl<StaticDataManager>();

  late TextEditingController _nameController;
  late TextEditingController _newNoteController;

  List<TextEditingController> _phoneControllers = [];
  List<bool> _phonePrimary = [];

  String? _selectedStatus;
  String? _selectedEmployeeId;
  String? _selectedExclusionReason;
  bool _isSubmitting = false;

  Map<String, dynamic> _dynamicValues = {};

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.lead?.clientName);
    _newNoteController = TextEditingController();

    _selectedStatus = widget.lead?.leadStatus ?? 'تم التواصل اول مرة';
    _selectedEmployeeId = widget.lead?.assignedTo ?? widget.user.id;
    _selectedExclusionReason = widget.lead?.exclusionReasonName;

    if (widget.lead != null && widget.lead!.phones.isNotEmpty) {
      final sorted = [...widget.lead!.phones]..sort((a, b) => b.isPrimary ? 1 : -1);
      _phoneControllers = sorted.map((p) => TextEditingController(text: p.phoneNumber)).toList();
      _phonePrimary = sorted.map((p) => p.isPrimary).toList();
    } else {
      _phoneControllers.add(TextEditingController());
      _phonePrimary.add(true);
    }

    _dynamicValues['property_code'] = widget.lead?.propertyCode;
    _dynamicValues['desc_lead_need'] = widget.lead?.descLeadNeed;
    _dynamicValues['budget_from'] = widget.lead?.budgetFrom;
    _dynamicValues['budget_to'] = widget.lead?.budgetTo;
    _dynamicValues['listing_type_id'] = widget.lead?.listingTypeId;
    _dynamicValues['property_type_id'] = widget.lead?.propertyTypeId;
    _dynamicValues['city_id'] = widget.lead?.cityId;
    _dynamicValues['platform_id'] = widget.lead?.platformId;
    _dynamicValues['channel_id'] = widget.lead?.channelId;
    _dynamicValues['rate_id'] = widget.lead?.rateId;
    _dynamicValues['last_activity_type_id'] = widget.lead?.lastActivityTypeId;
    _dynamicValues['assigned_to_at'] = widget.lead?.assignedToAt?.toIso8601String();
    _dynamicValues['scheduled_deadline_at'] = widget.lead?.scheduledDeadlineAt?.toIso8601String();
    _dynamicValues['last_comment'] = widget.lead?.lastComment;
    _dynamicValues['transferred_by'] = widget.lead?.transferredBy;
    _dynamicValues['transferred_from'] = widget.lead?.transferredFrom;

    if (widget.lead?.customFields != null) {
      _dynamicValues.addAll(widget.lead!.customFields!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newNoteController.dispose();
    for (var ctrl in _phoneControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  FormFieldModel? _getFieldMeta(String key) {
    try {
      return dataManager.formFields.firstWhere((f) => f.fieldKey == key);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.lead != null;
    return ListenableBuilder(
      listenable: dataManager,
      builder: (context, _) {
        final visibleFields = dataManager.getFormFieldsForRole(widget.user.role, onlyForm: true);
        final manualKeys = ['client_name', 'phones', 'phone_primary', 'lead_status', 'assigned_to', 'exclusion_reason_id'];
        
        final dynamicFields = visibleFields.where((f) => !manualKeys.contains(f.fieldKey)).toList();
        dynamicFields.sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

        final nameField = _getFieldMeta('client_name');
        final phonesField = _getFieldMeta('phone_primary') ?? _getFieldMeta('phones');
        final statusField = _getFieldMeta('lead_status');
        final exclusionField = _getFieldMeta('exclusion_reason_id');
        final assignedField = _getFieldMeta('assigned_to');

        final showName = nameField?.isVisibleForRole(widget.user.role) ?? true;
        final showPhones = phonesField?.isVisibleForRole(widget.user.role) ?? true;
        final showStatus = statusField?.isVisibleForRole(widget.user.role) ?? true;
        final showExclusion = exclusionField?.isVisibleForRole(widget.user.role) ?? true;
        final showAssigned = assignedField?.isVisibleForRole(widget.user.role) ?? true;

        return BlocConsumer<LeadCubit, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          if (!_isSubmitting) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ البيانات بنجاح"), backgroundColor: Colors.green));
          if (widget.isEmbedded) { widget.onSaved?.call(); } else { Navigator.pop(context); }
        } else if (state is LeadError) {
          if (!_isSubmitting) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.brandAccent));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5FB),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Column(
                      children: [
                        Text(isEdit ? 'تعديل بيانات العميل' : 'إدخال بيانات العميل', style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1A1A2E))),
                        SizedBox(height: 8.h),
                        Text('يرجى تعبئة النموذج أدناه لتسجيل بيانات العميل في النظام العقاري.', style: TextStyle(fontSize: 14.sp, color: const Color(0xFFAAAABB))),
                        if (!widget.isEmbedded)
                          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14), label: const Text('رجوع'), style: TextButton.styleFrom(foregroundColor: const Color(0xFFAAAABB)))),
                      ],
                    ),
                  ),

                  if (showName || showPhones)
                    RetajSectionCard(
                      title: "البيانات الأساسية",
                      icon: Icons.person_outline,
                      children: [
                        if (showName)
                          RetajTextField(
                            controller: _nameController, 
                            label: nameField?.titleAr ?? "الاسم بالكامل",
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                          ),
                        if (showName && showPhones) SizedBox(height: 24.h),
                        if (showPhones)
                          ..._phoneControllers.asMap().entries.map((entry) {
                            int idx = entry.key;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: intl_phone_field.IntlPhoneField(
                                      decoration: InputDecoration(
                                        labelText: idx == 0 ? "الرقم الأساسي (إجباري)" : "رقم هاتف إضافي (اختياري)",
                                        filled: true, fillColor: Colors.grey.withValues(alpha: 0.05),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                                      ),
                                      initialCountryCode: 'EG',
                                      initialValue: entry.value.text,
                                      onChanged: (phone) => entry.value.text = phone.completeNumber,
                                      validator: idx == 0 ? (v) => (v == null || v.completeNumber.isEmpty) ? 'مطلوب' : null : null,
                                    ),
                                  ),
                                  if (idx > 0) ...[
                                    SizedBox(width: 8.w),
                                    IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() { _phoneControllers.removeAt(idx); _phonePrimary.removeAt(idx); })),
                                  ],
                                ],
                              ),
                            );
                          }),
                        if (showPhones)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() { _phoneControllers.add(TextEditingController()); _phonePrimary.add(false); }),
                              icon: const Icon(Icons.add), label: const Text("إضافة رقم آخر"),
                            ),
                          ),
                      ],
                    ),

                  if (dynamicFields.isNotEmpty)
                    RetajSectionCard(
                      title: "تفاصيل الطلب (ديناميكي)",
                      icon: Icons.dynamic_form_outlined,
                      children: dynamicFields.map((f) => DynamicLeadField(
                        field: f,
                        value: _dynamicValues[f.fieldKey],
                        readOnly: isEdit && !f.isEditableForRole(widget.user.role),
                        onChanged: (key, val) => setState(() => _dynamicValues[key] = val),
                      )).toList(),
                    ),

                  if (showStatus || showAssigned)
                    RetajSectionCard(
                      title: "المنصة والحالة",
                      icon: Icons.admin_panel_settings_outlined,
                      children: [
                        if (showStatus)
                          _buildDropdown(statusField?.titleAr ?? "حالة العميل", dataManager.getActiveOptions('lead_status', includeValue: _selectedStatus), _selectedStatus, (v) {
                            setState(() { _selectedStatus = v; if (v != 'مستبعد') _selectedExclusionReason = null; });
                          }, required: statusField?.isRequired ?? true),
                        if (showExclusion && _selectedStatus == 'مستبعد') ...[
                          SizedBox(height: 24.h),
                          _buildDropdown(exclusionField?.titleAr ?? "سبب الاستبعاد *", dataManager.getActiveOptions('lead_exclusion_reasons', includeValue: _selectedExclusionReason), _selectedExclusionReason, (v) => setState(() => _selectedExclusionReason = v), required: exclusionField?.isRequired ?? true),
                        ],
                        if (showAssigned && (widget.user.role == 'manager' || widget.user.role == 'admin')) ...[
                          SizedBox(height: 24.h),
                          (state is LeadLoaded && state.employees.isNotEmpty)
                              ? RetajDropdown<String>(
                                  label: assignedField?.titleAr ?? "الموظف المسؤول",
                                  value: state.employees.any((e) => e.id == _selectedEmployeeId) ? _selectedEmployeeId : null,
                                  items: state.employees.map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.firstName != null ? "${e.firstName} ${e.lastName}" : e.email))).toList(),
                                  onChanged: (val) => setState(() => _selectedEmployeeId = val),
                                )
                              : const CircularProgressIndicator(),
                        ],
                      ],
                    ),

                  RetajSectionCard(
                    title: "إضافة ملاحظة (اختياري)",
                    icon: Icons.comment_outlined,
                    children: [
                      RetajTextField(controller: _newNoteController, label: "اكتب ملاحظة تضاف للسجل مباشرة...", maxLines: null, minLines: 3),
                    ],
                  ),

                  SizedBox(height: 32.h),
                  _buildSubmitButton(isEdit, _isSubmitting),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChanged, {bool required = false}) {
    final List<String> validItems = items.toSet().toList();
    if (value != null && !validItems.contains(value)) validItems.insert(0, value);
    return RetajDropdown<String>(
      label: hint, value: value,
      items: validItems.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'مطلوب' : null : null,
    );
  }

  Widget _buildSubmitButton(bool isEdit, bool isLoading) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: isLoading ? null : LinearGradient(colors: [AppColors.brandPrimary, AppColors.brandPrimary.withValues(alpha: 0.8)], begin: Alignment.centerRight, end: Alignment.centerLeft),
        color: isLoading ? AppColors.brandPrimary.withValues(alpha: 0.5) : null,
        boxShadow: isLoading ? [] : [BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _submitForm,
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: 64.h,
            child: Center(
              child: isLoading
                  ? const SizedBox(height: 26, width: 26, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white, size: 22.sp), SizedBox(width: 10.w),
                        Text(isEdit ? 'تحديث بيانات العميل' : 'حفظ البيانات', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final phones = _phoneControllers.asMap().entries.where((e) => e.value.text.trim().isNotEmpty).map((e) {
        String rawPhone = e.value.text.trim();
        const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
        const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
        for (int i = 0; i < 10; i++) rawPhone = rawPhone.replaceAll(arabicDigits[i], englishDigits[i]);
        rawPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
        return LeadPhoneModel(phoneNumber: rawPhone, isPrimary: _phonePrimary.length > e.key ? _phonePrimary[e.key] : e.key == 0);
      }).toList();

      final statusId = _selectedStatus != null ? dataManager.getIdByName('lead_status', _selectedStatus!) : null;
      final exclusionReasonId = _selectedExclusionReason != null ? dataManager.getIdByName('lead_exclusion_reasons', _selectedExclusionReason!) : null;

      final bool isExcluded = _selectedStatus == 'مستبعد';
      final bool isArchived = isExcluded || (widget.lead?.isArchived ?? false);

      final newAssignee = _selectedEmployeeId ?? widget.user.id;
      String? transferredFrom;
      String? finalStatus = _selectedStatus;
      String? finalStatusId = statusId;

      if (widget.lead != null) {
        if (newAssignee != widget.lead!.assignedTo) {
          transferredFrom = widget.lead!.assignedTo;
          finalStatus = 'تم التواصل اول مرة';
          finalStatusId = '460be748-7685-49ef-abcf-c4dd49511ab7';
        } else if (_selectedStatus != widget.lead!.leadStatus) {
          transferredFrom = null;
        } else {
          transferredFrom = widget.lead!.transferredFrom;
        }
      }

      final Map<String, dynamic> customFields = {};
      final visibleFields = dataManager.getFormFieldsForRole(widget.user.role, onlyForm: true);
      for (var f in visibleFields) {
        if (!f.isSystem && _dynamicValues[f.fieldKey] != null && _dynamicValues[f.fieldKey].toString().isNotEmpty) {
          customFields[f.fieldKey] = _dynamicValues[f.fieldKey];
        }
      }

      final num? budgetFromVal = _dynamicValues['budget_from'] != null ? num.tryParse(_dynamicValues['budget_from'].toString()) : null;
      final num? budgetToVal = _dynamicValues['budget_to'] != null ? num.tryParse(_dynamicValues['budget_to'].toString()) : null;

      final leadData = LeadModel(
        id: widget.lead?.id,
        clientName: _nameController.text,
        phones: phones,
        propertyCode: _dynamicValues['property_code']?.toString(),
        descLeadNeed: _dynamicValues['desc_lead_need']?.toString(),
        leadStatus: finalStatus,
        statusId: finalStatusId,
        platformId: _dynamicValues['platform_id']?.toString(),
        propertyTypeId: _dynamicValues['property_type_id']?.toString(),
        listingTypeId: _dynamicValues['listing_type_id']?.toString(),
        channelId: _dynamicValues['channel_id']?.toString(),
        cityId: _dynamicValues['city_id']?.toString(),
        exclusionReasonId: exclusionReasonId,
        budgetFrom: budgetFromVal,
        budgetTo: budgetToVal,
        isActive: widget.lead?.isActive ?? true,
        isArchived: isArchived,
        isPinned: widget.lead?.isPinned ?? false,
        createdBy: widget.lead?.createdBy ?? widget.user.id,
        assignedTo: newAssignee,
        transferredFrom: _dynamicValues['transferred_from']?.toString() ?? transferredFrom,
        transferredBy: _dynamicValues['transferred_by']?.toString(),
        createdAt: widget.lead?.createdAt ?? DateTime.now(),
        rateId: _dynamicValues['rate_id']?.toString(),
        lastActivityTypeId: _dynamicValues['last_activity_type_id']?.toString(),
        lastComment: _dynamicValues['last_comment']?.toString(),
        assignedToAt: _dynamicValues['assigned_to_at'] != null ? DateTime.tryParse(_dynamicValues['assigned_to_at']) : widget.lead?.assignedToAt,
        scheduledDeadlineAt: _dynamicValues['scheduled_deadline_at'] != null ? DateTime.tryParse(_dynamicValues['scheduled_deadline_at']) : widget.lead?.scheduledDeadlineAt,
        customFields: customFields,
      );

      if (widget.lead == null) {
        final phonesList = phones.map((e) => e.phoneNumber).toList();
        final duplicates = await context.read<LeadCubit>().checkDuplicates(phonesList);
        final myDuplicates = duplicates.where((d) => d.assignedTo == widget.user.id || d.createdBy == widget.user.id).toList();

        if (myDuplicates.isNotEmpty) {
          setState(() => _isSubmitting = false);
          final dup = myDuplicates.first;
          final dupPhones = dup.phones.map((p) => p.phoneNumber).join(' - ');
          
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30), SizedBox(width: 10.w), const Text('تحذير: رقم مكرر!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
              content: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("يوجد عميل آخر مضاف بواسطتك يمتلك نفس الأرقام (أو يتطابق في آخر 6 أرقام).", style: TextStyle(fontSize: 16.sp)), SizedBox(height: 15.h),
                  Container(padding: EdgeInsets.all(12.w), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("اسم العميل: ${dup.clientName}", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)), SizedBox(height: 5.h), Text("الأرقام: $dupPhones", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary))])), SizedBox(height: 15.h),
                  Text("هل أنت متأكد أنك تريد إضافة هذا العميل كعميل جديد على أي حال؟", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 16.sp))),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary), onPressed: () => Navigator.pop(ctx, true), child: Text('إضافة على أي حال', style: TextStyle(color: Colors.white, fontSize: 16.sp))),
              ],
            ),
          );
          if (confirm != true) return;
          setState(() => _isSubmitting = true);
        }

        if (mounted) context.read<LeadCubit>().addLead(leadData, phones, newNote: _newNoteController.text);
      } else {
        context.read<LeadCubit>().updateFullLead(leadData, phones, newNote: _newNoteController.text);
      }
    }
  }
}
