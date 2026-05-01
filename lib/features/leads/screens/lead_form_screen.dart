import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
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
  late TextEditingController _newCommentController;
  List<TextEditingController> _phoneControllers = [];

  String? _selectedPlatform;
  String? _selectedListingType;
  String? _selectedPropertyType;
  int? _selectedGovId;
  String? _selectedCityName;
  String? _selectedCommunicationChannel;

  String? _selectedStatus;
  String? _selectedEmployeeId;
  bool _isSubmitting = false;

  final List<String> _statuses = ['جديد', 'تم التواصل', 'تفاوض', 'تم التعاقد', 'مستبعد'];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.lead?.clientName);
    _propertyCodeController = TextEditingController(text: widget.lead?.propertyCode);
    _descController = TextEditingController(text: widget.lead?.descLeadNeed);
    _newCommentController = TextEditingController();

    _selectedStatus = widget.lead?.leadStatus ?? 'جديد';
    _selectedEmployeeId = widget.lead?.assignedTo ?? widget.user.id;
    
    _selectedPlatform = widget.lead?.platform;
    _selectedListingType = widget.lead?.listingType;
    _selectedPropertyType = widget.lead?.propertyType;
    _selectedCommunicationChannel = widget.lead?.communicationChannel;
    
    if (widget.lead?.governorate != null) {
      try {
        final gov = dataManager.governorates.firstWhere((g) => g.name == widget.lead!.governorate);
        _selectedGovId = gov.id;
        _selectedCityName = widget.lead!.city;
      } catch (_) {}
    }

    if (widget.lead != null && widget.lead!.clientPhone.isNotEmpty) {
      _phoneControllers = widget.lead!.clientPhone.map((p) => TextEditingController(text: p)).toList();
    } else {
      _phoneControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _propertyCodeController.dispose();
    _descController.dispose();
    _newCommentController.dispose();
    for (var c in _phoneControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.lead != null;

    return BlocConsumer<LeadCubit, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          if (!_isSubmitting) return; // Prevent closing if we didn't initiate
          setState(() => _isSubmitting = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ البيانات بنجاح"), backgroundColor: Colors.green),
          );
        } else if (state is LeadError) {
          if (!_isSubmitting) return;
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.brandAccent),
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
                            color: const Color(0xFFAAAABB),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        // زر الرجوع
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                            label: const Text('رجوع'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFAAAABB)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ─── 1. القسم الأساسي ───
                  _buildSectionCard(
                    title: "بيانات العميل",
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        RetajTextField(
                          controller: _nameController,
                          label: "الاسم بالكامل",
                        ),
                        SizedBox(height: 16.h),
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
                                  ),
                                ),
                                if (idx > 0) ...[
                                  SizedBox(width: 8.w),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => setState(() => _phoneControllers.removeAt(idx)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _phoneControllers.add(TextEditingController())),
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
                            Expanded(child: _buildDropdown("نوع الإعلان", dataManager.getOptions('listing_type'), _selectedListingType, (v) => setState(() => _selectedListingType = v))),
                            SizedBox(width: 16.w),
                            Expanded(child: _buildDropdown("نوع العقار", dataManager.getOptions('property_type'), _selectedPropertyType, (v) => setState(() => _selectedPropertyType = v))),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: RetajDropdown<int>(
                                label: "المحافظة",
                                value: _selectedGovId,
                                items: dataManager.governorates
                                    .map(
                                      (g) => DropdownMenuItem<int>(
                                        value: g.id,
                                        child: Text(g.name),
                                      ),
                                    )
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
                                value: _selectedCityName,
                                items: _selectedGovId == null
                                    ? []
                                    : dataManager
                                        .getCitiesByGovId(_selectedGovId!)
                                        .map(
                                          (c) => DropdownMenuItem<String>(
                                            value: c.name,
                                            child: Text(c.name),
                                          ),
                                        )
                                        .toList(),
                                onChanged: _selectedGovId == null
                                    ? null
                                    : (v) => setState(() => _selectedCityName = v),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        RetajTextField(controller: _propertyCodeController, label: "كود عقار محدد (اختياري)"),
                        SizedBox(height: 16.h),
                        RetajTextField(controller: _descController, label: "وصف الاحتياج (اختياري)", maxLines: 3),
                      ],
                    ),
                  ),

                  // ─── 3. المصدر والإدارة ───
                  _buildSectionCard(
                    title: "المنصة والحالة",
                    icon: Icons.admin_panel_settings_outlined,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildDropdown("المنصة القادم منها", dataManager.getOptions('platform'), _selectedPlatform, (v) => setState(() => _selectedPlatform = v))),
                            SizedBox(width: 16.w),
                            Expanded(child: _buildDropdown("طريقة التواصل", ['مكالمة هاتفية', 'واتساب', 'ماسنجر', 'زيارة'], _selectedCommunicationChannel, (v) => setState(() => _selectedCommunicationChannel = v))),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _buildDropdown("حالة العميل", _statuses, _selectedStatus, (v) => setState(() => _selectedStatus = v)),
                        
                        if (widget.user.role == 'manager' || widget.user.role == 'admin') ...[
                          SizedBox(height: 16.h),
                          (state is LeadLoaded && state.employees.isNotEmpty)
                            ? RetajDropdown<String>(
                                label: "الموظف المسؤول (خاص بالمدير)",
                                value: state.employees.any((e) => e.id == _selectedEmployeeId)
                                    ? _selectedEmployeeId
                                    : null,
                                items: state.employees
                                    .map(
                                      (e) => DropdownMenuItem<String>(
                                        value: e.id,
                                        child: Text(
                                          e.firstName != null
                                              ? "${e.firstName} ${e.lastName}"
                                              : e.email,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedEmployeeId = val),
                              )
                            : const CircularProgressIndicator(),
                        ],
                      ],
                    ),
                  ),

                  // ─── 4. إضافة تعليق ───
                  _buildSectionCard(
                    title: "إضافة تعليق (اختياري)",
                    icon: Icons.comment_outlined,
                    child: RetajTextField(
                      controller: _newCommentController,
                      label: "اكتب تعليقاً يضاف للسجل مباشرة...",
                      maxLines: 3,
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

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
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
          // عنوان القسم في المنتصف
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
          Divider(color: const Color(0xFFF0F0F6), thickness: 1, height: 24.h),
          Padding(padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h), child: child),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return RetajDropdown<String>(
      label: hint,
      value: value,
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
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
                colors: [AppColors.brandPrimary, AppColors.brandPrimary.withValues(alpha: 0.8)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
        color: isLoading ? AppColors.brandPrimary.withValues(alpha: 0.5) : null,
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
                      height: 26, width: 26,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white, size: 22.sp),
                        SizedBox(width: 10.w),
                        Text(
                          isEdit ? 'تحديث بيانات العميل' : 'حفظ البيانات',
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      List<String> phones = _phoneControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();
      String? govName;
      if (_selectedGovId != null) {
        govName = dataManager.governorates.firstWhere((g) => g.id == _selectedGovId).name;
      }

      final leadData = LeadModel(
        id: widget.lead?.id,
        clientName: _nameController.text,
        clientPhone: phones,
        propertyCode: _propertyCodeController.text,
        descLeadNeed: _descController.text,
        budgetFrom: null,
        budgetTo: null,
        platform: _selectedPlatform,
        listingType: _selectedListingType,
        propertyType: _selectedPropertyType,
        communicationChannel: _selectedCommunicationChannel,
        governorate: govName,
        city: _selectedCityName,
        leadStatus: _selectedStatus,
        createdBy: widget.lead?.createdBy ?? widget.user.id,
        assignedTo: _selectedEmployeeId ?? widget.user.id,
        createdAt: widget.lead?.createdAt ?? DateTime.now(),
      );

      if (widget.lead == null) {
        context.read<LeadCubit>().addLead(leadData, newComment: _newCommentController.text);
      } else {
        context.read<LeadCubit>().updateFullLead(leadData, newComment: _newCommentController.text);
      }
    }
  }
}