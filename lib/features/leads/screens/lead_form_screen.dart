import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../../../core/widgets/retaj_shared_fields.dart';

class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;
  final ProfileModel user;

  const LeadFormScreen({super.key, this.lead, required this.user});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dataManager = di.sl<StaticDataManager>();

  late TextEditingController _nameController;
  late TextEditingController _propertyCodeController;
  late TextEditingController _descController;
  late TextEditingController _newNoteController;
  late TextEditingController _budgetFromController;
  late TextEditingController _budgetToController;

  // كل controller بيقابل LeadPhoneModel (phoneNumber + isPrimary)
  List<TextEditingController> _phoneControllers = [];
  // نتتبع is_primary لكل رقم
  List<bool> _phonePrimary = [];

  String? _selectedPlatform;
  String? _selectedListingType;
  String? _selectedPropertyType;
  int? _selectedGovId;
  String? _selectedCityName;
  String? _selectedCommunicationChannel;
  String? _selectedStatus;
  String? _selectedEmployeeId;
  String? _selectedExclusionReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.lead?.clientName);
    _propertyCodeController = TextEditingController(text: widget.lead?.propertyCode);
    _descController = TextEditingController(text: widget.lead?.descLeadNeed);
    _newNoteController = TextEditingController();
    final budgetFromStr = widget.lead?.budgetFrom != null ? widget.lead!.budgetFrom!.toCurrency() : '';
    final budgetToStr = widget.lead?.budgetTo != null ? widget.lead!.budgetTo!.toCurrency() : '';
    _budgetFromController = TextEditingController(text: budgetFromStr);
    _budgetToController = TextEditingController(text: budgetToStr);

    _selectedStatus = widget.lead?.leadStatus ?? 'تم التواصل اول مرة';
    _selectedEmployeeId = widget.lead?.assignedTo ?? widget.user.id;
    _selectedExclusionReason = widget.lead?.exclusionReasonName;

    _selectedPlatform = widget.lead?.platform;
    _selectedListingType = widget.lead?.listingType;
    _selectedPropertyType = widget.lead?.propertyType;
    _selectedCommunicationChannel = widget.lead?.communicationChannel;

    if (widget.lead != null) {
      if (widget.lead!.governorateId != null) {
        _selectedGovId = widget.lead!.governorateId;
        _selectedCityName = widget.lead!.city;
      } else if (widget.lead!.governorate != null) {
        try {
          final gov = dataManager.governorates
              .firstWhere((g) => g.name == widget.lead!.governorate);
          _selectedGovId = gov.id;
          _selectedCityName = widget.lead!.city;
        } catch (_) {}
      }
    }

    // تحميل الأرقام من lead_phones
    if (widget.lead != null && widget.lead!.phones.isNotEmpty) {
      // نرتب الـ primary أولاً
      final sorted = [...widget.lead!.phones]
        ..sort((a, b) => b.isPrimary ? 1 : -1);
      _phoneControllers = sorted
          .map((p) => TextEditingController(text: p.phoneNumber))
          .toList();
      _phonePrimary = sorted.map((p) => p.isPrimary).toList();
    } else {
      _phoneControllers.add(TextEditingController());
      _phonePrimary.add(true); // أول رقم primary افتراضياً
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _propertyCodeController.dispose();
    _descController.dispose();
    _newNoteController.dispose();
    _budgetFromController.dispose();
    _budgetToController.dispose();
    for (var c in _phoneControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.lead != null;

    return BlocConsumer<LeadCubit, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          if (!_isSubmitting) return;
          setState(() => _isSubmitting = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("تم حفظ البيانات بنجاح"),
                backgroundColor: Colors.green),
          );
        } else if (state is LeadError) {
          if (!_isSubmitting) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.brandAccent),
          );
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
                  // ─── Page Header ───
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          isEdit ? 'تعديل بيانات العميل' : 'إدخال بيانات العميل',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'يرجى تعبئة النموذج أدناه لتسجيل بيانات العميل في النظام العقاري.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFFAAAABB)),
                        ),
                        SizedBox(height: 6.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 14),
                            label: const Text('رجوع'),
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFAAAABB)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── 1. بيانات العميل ───
                  _buildSectionCard(
                    title: "بيانات العميل",
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        RetajTextField(
                          controller: _nameController,
                          label: "الاسم بالكامل",
                        ),
                        SizedBox(height: 24.h),
                        ..._phoneControllers.asMap().entries.map((entry) {
                          int idx = entry.key;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RetajTextField(
                                    controller: entry.value,
                                    label: "رقم الهاتف ${idx + 1}",
                                    keyboardType: TextInputType.phone,
                                    forceLtr: true,
                                    validator: idx == 0
                                        ? (v) => (v == null || v.trim().isEmpty)
                                            ? 'رقم الهاتف الأساسي مطلوب'
                                            : null
                                        : null,
                                  ),
                                ),
                                if (idx > 0) ...[
                                  SizedBox(width: 8.w),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () => setState(() {
                                      _phoneControllers.removeAt(idx);
                                      _phonePrimary.removeAt(idx);
                                    }),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _phoneControllers.add(TextEditingController());
                              _phonePrimary.add(false);
                            }),
                            icon: const Icon(Icons.add),
                            label: const Text("إضافة رقم آخر"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── 2. تفاصيل الطلب والموقع ───
                  _buildSectionCard(
                    title: "تفاصيل الطلب",
                    icon: Icons.home_work_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildDropdown(
                                    "نوع الإعلان *",
                                    dataManager.getActiveOptions('listing_type', includeValue: _selectedListingType),
                                    _selectedListingType,
                                    (v) => setState(() => _selectedListingType = v),
                                    required: true)),
                            SizedBox(width: 16.w),
                            Expanded(
                                child: _buildDropdown(
                                    "نوع العقار",
                                    dataManager.getActiveOptions('property_type', includeValue: _selectedPropertyType),
                                    _selectedPropertyType,
                                    (v) => setState(() => _selectedPropertyType = v))),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: RetajDropdown<int>(
                                label: "المحافظة",
                                value: _selectedGovId,
                                items: dataManager.getActiveGovernorates(includeId: _selectedGovId)
                                    .map((g) => DropdownMenuItem<int>(
                                          value: g.id,
                                          child: Text(g.name),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() {
                                  _selectedGovId = v;
                                  _selectedCityName = null;
                                }),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: RetajDropdown<String>(
                                label: "المدينة",
                                value: _selectedCityName != null &&
                                            dataManager.getActiveCitiesByGovId(_selectedGovId ?? -1, includeName: _selectedCityName)
                                                .any((c) => c.name == _selectedCityName)
                                        ? _selectedCityName
                                        : null,
                                items: _selectedGovId == null
                                    ? []
                                    : dataManager
                                        .getActiveCitiesByGovId(_selectedGovId!, includeName: _selectedCityName)
                                        .map((c) => DropdownMenuItem<String>(
                                              value: c.name,
                                              child: Text(c.name),
                                            ))
                                        .toList(),
                                onChanged: _selectedGovId == null
                                    ? null
                                    : (v) => setState(
                                        () => _selectedCityName = v),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                            controller: _propertyCodeController,
                            label: "كود عقار محدد (اختياري)"),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: RetajTextField(
                                controller: _budgetFromController,
                                label: "الميزانية من (اختياري)",
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  NumberFormatter(),
                                ],
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: RetajTextField(
                                controller: _budgetToController,
                                label: "الميزانية إلى (اختياري)",
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  NumberFormatter(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                            controller: _descController,
                            label: "وصف الاحتياج (اختياري)",
                            maxLines: null,
                            minLines: 3),
                      ],
                    ),
                  ),

                  // ─── 3. المنصة والحالة ───
                  _buildSectionCard(
                    title: "المنصة والحالة",
                    icon: Icons.admin_panel_settings_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildDropdown(
                                    "المنصة القادم منها *",
                                    dataManager.getActiveOptions('platform', includeValue: _selectedPlatform),
                                    _selectedPlatform,
                                    (v) => setState(() => _selectedPlatform = v),
                                    required: true)),
                            SizedBox(width: 16.w),
                            Expanded(
                                child: _buildDropdown(
                                    "طريقة التواصل",
                                    dataManager.getActiveOptions('communication_channel', includeValue: _selectedCommunicationChannel),
                                    _selectedCommunicationChannel,
                                    (v) => setState(() => _selectedCommunicationChannel = v))),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        _buildDropdown(
                            "حالة العميل",
                            dataManager.getActiveOptions('lead_status', includeValue: _selectedStatus),
                            _selectedStatus,
                            (v) {
                              setState(() {
                                _selectedStatus = v;
                                if (v != 'مستبعد') {
                                  _selectedExclusionReason = null;
                                }
                              });
                            }),
                        if (_selectedStatus == 'مستبعد') ...[
                          SizedBox(height: 24.h),
                          _buildDropdown(
                              "سبب الاستبعاد *",
                              dataManager.getActiveOptions('lead_exclusion_reasons', includeValue: _selectedExclusionReason),
                              _selectedExclusionReason,
                              (v) => setState(() => _selectedExclusionReason = v),
                              required: true),
                        ],
                        if (widget.user.role == 'manager' ||
                            widget.user.role == 'admin') ...[
                          SizedBox(height: 24.h),
                          (state is LeadLoaded && state.employees.isNotEmpty)
                              ? RetajDropdown<String>(
                                  label: "الموظف المسؤول (خاص بالمدير)",
                                  value: state.employees.any(
                                          (e) => e.id == _selectedEmployeeId)
                                      ? _selectedEmployeeId
                                      : null,
                                  items: state.employees
                                      .map((e) => DropdownMenuItem<String>(
                                            value: e.id,
                                            child: Text(
                                              e.firstName != null
                                                  ? "${e.firstName} ${e.lastName}"
                                                  : e.email,
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) => setState(
                                      () => _selectedEmployeeId = val),
                                )
                              : const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),

                  // ─── 4. إضافة ملاحظة ───
                  _buildSectionCard(
                    title: "إضافة ملاحظة (اختياري)",
                    icon: Icons.comment_outlined,
                    child: RetajTextField(
                      controller: _newNoteController,
                      label: "اكتب ملاحظة تضاف للسجل مباشرة...",
                      maxLines: null,
                      minLines: 3,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // ─── 5. زر الحفظ ───
                  _buildSubmitButton(isEdit, _isSubmitting),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 24.h, bottom: 4.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(icon, color: AppColors.brandPrimary, size: 22.sp),
              ],
            ),
          ),
          Divider(
              color: const Color(0xFFF0F0F6), thickness: 1, height: 24.h),
          Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
              child: child),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final List<String> validItems = items.toSet().toList();
    if (value != null && !validItems.contains(value)) {
      validItems.insert(0, value);
    }

    return RetajDropdown<String>(
      label: hint,
      value: value,
      items: validItems
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildSubmitButton(bool isEdit, bool isLoading) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: isLoading
            ? null
            : LinearGradient(
                colors: [
                  AppColors.brandPrimary,
                  AppColors.brandPrimary.withValues(alpha: 0.8)
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
        color: isLoading
            ? AppColors.brandPrimary.withValues(alpha: 0.5)
            : null,
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
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
                  ? const SizedBox(
                      height: 26,
                      width: 26,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded,
                            color: Colors.white, size: 22.sp),
                        SizedBox(width: 10.w),
                        Text(
                          isEdit
                              ? 'تحديث بيانات العميل'
                              : 'حفظ البيانات',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // بناء قائمة الأرقام كـ LeadPhoneModel
      final phones = _phoneControllers.asMap().entries
          .where((e) => e.value.text.trim().isNotEmpty)
          .map((e) => LeadPhoneModel(
                phoneNumber: e.value.text.trim(),
                isPrimary: _phonePrimary.length > e.key
                    ? _phonePrimary[e.key]
                    : e.key == 0,
              ))
          .toList();

      // تحويل الاختيارات النصية إلى IDs
      final statusId = _selectedStatus != null
          ? dataManager.getIdByName('lead_status', _selectedStatus!)
          : null;
      final platformId = _selectedPlatform != null
          ? dataManager.getIdByName('platform', _selectedPlatform!)
          : null;
      final propertyTypeId = _selectedPropertyType != null
          ? dataManager.getIdByName('property_type', _selectedPropertyType!)
          : null;
      final listingTypeId = _selectedListingType != null
          ? dataManager.getIdByName('listing_type', _selectedListingType!)
          : null;
      final channelId = _selectedCommunicationChannel != null
          ? dataManager.getIdByName(
              'communication_channel', _selectedCommunicationChannel!)
          : null;

      int? cityId;
      if (_selectedGovId != null && _selectedCityName != null) {
        try {
          final cityObj = dataManager
              .getCitiesByGovId(_selectedGovId!)
              .firstWhere((c) => c.name == _selectedCityName);
          cityId = cityObj.id;
        } catch (_) {}
      }

      final exclusionReasonId = _selectedExclusionReason != null
          ? dataManager.getIdByName('lead_exclusion_reasons', _selectedExclusionReason!)
          : null;

      final bool isExcluded = _selectedStatus == 'مستبعد';
      final bool isArchived = isExcluded || (widget.lead?.isArchived ?? false);

      final newAssignee = _selectedEmployeeId ?? widget.user.id;
      String? transferredFrom;
      String? finalStatus = _selectedStatus;
      String? finalStatusId = statusId;

      if (widget.lead != null) {
        if (newAssignee != widget.lead!.assignedTo) {
          // المدير قام بتغيير الموظف: نحتفظ بالموظف القديم ونجبر الحالة لتم التواصل أول مرة
          transferredFrom = widget.lead!.assignedTo;
          finalStatus = 'تم التواصل اول مرة';
          finalStatusId = '460be748-7685-49ef-abcf-c4dd49511ab7';
        } else if (_selectedStatus != widget.lead!.leadStatus) {
          // الموظف قام بتغيير الحالة: نزيل المحول منه لأنه أتم المهمة
          transferredFrom = null;
        } else {
          // لم يحدث نقل ولم تتغير الحالة: نحتفظ بالقيمة القديمة
          transferredFrom = widget.lead!.transferredFrom;
        }
      }

      final leadData = LeadModel(
        id: widget.lead?.id,
        clientName: _nameController.text,
        phones: phones,
        propertyCode: _propertyCodeController.text,
        descLeadNeed: _descController.text,
        platform: _selectedPlatform,
        listingType: _selectedListingType,
        propertyType: _selectedPropertyType,
        communicationChannel: _selectedCommunicationChannel,
        city: _selectedCityName,
        leadStatus: finalStatus,
        statusId: finalStatusId,
        platformId: platformId,
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        channelId: channelId,
        governorateId: _selectedGovId,
        cityId: cityId,
        exclusionReasonId: exclusionReasonId,
        budgetFrom: num.tryParse(_budgetFromController.text.replaceAll(',', '').trim()),
        budgetTo: num.tryParse(_budgetToController.text.replaceAll(',', '').trim()),
        isActive: widget.lead?.isActive ?? true,
        isArchived: isArchived,
        isPinned: widget.lead?.isPinned ?? false,
        createdBy: widget.lead?.createdBy ?? widget.user.id,
        assignedTo: newAssignee,
        transferredFrom: transferredFrom,
        createdAt: widget.lead?.createdAt ?? DateTime.now(),
      );

      // Smart Sync: منع التعديل الوهمي للموظفين
      if (widget.lead != null) {
        bool hasChanges = false;
        
        // هل تم تغيير حالة العميل؟
        if (widget.lead!.statusId != leadData.statusId) {
          hasChanges = true;
        }

        // هل تم تغيير باقي البيانات؟
        if (!hasChanges) {
          if (widget.lead!.clientName != leadData.clientName ||
              widget.lead!.descLeadNeed != leadData.descLeadNeed ||
              widget.lead!.platformId != leadData.platformId ||
              widget.lead!.listingTypeId != leadData.listingTypeId ||
              widget.lead!.propertyTypeId != leadData.propertyTypeId ||
              widget.lead!.channelId != leadData.channelId ||
              widget.lead!.cityId != leadData.cityId ||
              widget.lead!.governorateId != leadData.governorateId ||
              widget.lead!.exclusionReasonId != leadData.exclusionReasonId ||
              widget.lead!.budgetFrom != leadData.budgetFrom ||
              widget.lead!.budgetTo != leadData.budgetTo ||
              widget.lead!.assignedTo != leadData.assignedTo ||
              widget.lead!.propertyCode != leadData.propertyCode) {
            hasChanges = true;
          }
        }

        // هل تم تغيير الأرقام؟
        if (!hasChanges) {
          if (widget.lead!.phones.length != phones.length) {
            hasChanges = true;
          } else {
            for (int i = 0; i < phones.length; i++) {
              if (widget.lead!.phones[i].phoneNumber != phones[i].phoneNumber ||
                  widget.lead!.phones[i].isPrimary != phones[i].isPrimary) {
                hasChanges = true;
                break;
              }
            }
          }
        }

        if (!hasChanges) {
          // لم يحدث أي تغيير حقيقي، نقفل الشاشة بدون إرسال للباك إيند
          setState(() => _isSubmitting = false);
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      if (widget.lead == null) {
        final phonesList = phones.map((e) => e.phoneNumber).toList();
        final duplicates = await context.read<LeadCubit>().checkDuplicates(phonesList);
        final myDuplicates = duplicates.where((d) => d.createdBy == widget.user.id).toList();

        if (myDuplicates.isNotEmpty) {
          setState(() => _isSubmitting = false);
          final dup = myDuplicates.first;
          final dupPhones = dup.phones.map((p) => p.phoneNumber).join(' - ');
          
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
                  SizedBox(width: 10.w),
                  const Text('تحذير: رقم مكرر!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("يوجد عميل آخر مضاف بواسطتك يمتلك نفس الأرقام (أو يتطابق في آخر 6 أرقام).", style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 15.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("اسم العميل: ${dup.clientName}", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
                        SizedBox(height: 5.h),
                        Text("الأرقام: $dupPhones", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text("هل أنت متأكد أنك تريد إضافة هذا العميل كعميل جديد على أي حال؟", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('إضافة على أي حال', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                ),
              ],
            ),
          );

          if (confirm != true) return;
          setState(() => _isSubmitting = true);
        }

        if (mounted) {
          context.read<LeadCubit>().addLead(
                leadData,
                phones,
                newNote: _newNoteController.text,
              );
        }
      } else {
        context.read<LeadCubit>().updateFullLead(
              leadData,
              phones,
              newNote: _newNoteController.text,
            );
      }
    }
  }
}