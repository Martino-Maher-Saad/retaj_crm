
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/location_model.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/form_sections/client_basic_section.dart';
import '../widgets/form_sections/client_requirements_section.dart';
import '../widgets/form_sections/client_admin_section.dart';
import '../../../core/widgets/neon_dropdown.dart';


import '../../../data/models/profile_model.dart';

class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;
  final ProfileModel user;

  const LeadFormScreen({super.key, this.lead, required this.user});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _propertyCodeController;
  late TextEditingController _descController;
  late TextEditingController _commentController;
  late TextEditingController _sourceController;
  List<TextEditingController> _phoneControllers = [];

  String? _selectedCity;
  String? _selectedStatus;
  String? _selectedEmployeeId;
  List<City> _allCities = [];
  bool _isLoadingCities = true;
  bool _isSubmitting = false;
  String _selectedChannel = 'مكالمة هاتفية';
  final List<String> _channels = ['مكالمة هاتفية', 'واتساب', 'مسنجر', 'زيارة مقر'];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadCitiesFromJson();
  }

  Future<void> _loadCitiesFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/data/cities.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        _allCities = data.map((json) => City.fromJson(json)).toList();
        if (widget.lead?.city != null) {
          _selectedCity = widget.lead!.city;
        } else if (_allCities.isNotEmpty) {
          _selectedCity = _allCities.first.nameAr;
        }
        _isLoadingCities = false;
      });
    } catch (e) {
      debugPrint("خطأ في تحميل ملف المدن: $e");
      try {
        final String response = await rootBundle.loadString('data/cities.json');
        final List<dynamic> data = json.decode(response);
        setState(() {
          _allCities = data.map((json) => City.fromJson(json)).toList();
          _isLoadingCities = false;
        });
      } catch (innerError) {
        setState(() => _isLoadingCities = false);
      }
    }
  }

  void _initializeFields() {
    _nameController = TextEditingController(text: widget.lead?.clientName);
    _propertyCodeController = TextEditingController(text: widget.lead?.propertyCode);
    _descController = TextEditingController(text: widget.lead?.descLeadNeed);
    _commentController = TextEditingController(text: widget.lead?.comment);
    _sourceController = TextEditingController(text: widget.lead?.source);
    _selectedStatus = widget.lead?.leadStatus ?? 'جديد';
    _selectedEmployeeId = widget.lead?.assignedTo ?? widget.user.id;

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
    _commentController.dispose();
    _sourceController.dispose();
    for (var c in _phoneControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.lead != null;

    return BlocConsumer<LeadCubit, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          setState(() => _isSubmitting = false);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ البيانات بنجاح"), backgroundColor: Colors.green),
          );
        } else if (state is LeadError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.brandAccent),
          );
        }
      },
      builder: (context, state) {

        return Scaffold(
          backgroundColor: AppColors.bgMain,
          appBar: AppBar(
            title: Text(isEdit ? 'تعديل بيانات عميل' : 'إضافة عميل جديد', style: AppTextStyles.h2),
            backgroundColor: AppColors.bgSurface,
            elevation: 0,
            centerTitle: true,
          ),
          body: _isLoadingCities
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. القسم الأساسي (الاسم والأرقام)
                  ClientBasicSection(
                    nameController: _nameController,
                    phoneControllers: _phoneControllers,
                    onAddPhone: () => setState(() => _phoneControllers.add(TextEditingController())),
                    onRemovePhone: (idx) => setState(() => _phoneControllers.removeAt(idx)),
                  ),
                  SizedBox(height: 16.h),

                  // 2. تفاصيل الطلب
                  ClientRequirementsSection(
                    propertyCodeController: _propertyCodeController,
                    sourceController: _sourceController,
                    descController: _descController,
                    selectedChannel: _selectedChannel,
                    channels: _channels,
                    onChannelChanged: (val) => setState(() => _selectedChannel = val!),
                  ),
                  SizedBox(height: 16.h),

                  // 3. قسم الإدارة
                  ClientAdminSection(
                    selectedCity: _selectedCity,
                    selectedStatus: _selectedStatus,
                    cities: _allCities.map((c) => c.nameAr).toList(),
                    statuses: const ['جديد', 'تم التواصل', 'تفاوض', 'تم التعاقد', 'مستبعد'],
                    onCityChanged: (val) => setState(() => _selectedCity = val),
                    onStatusChanged: (val) => setState(() => _selectedStatus = val),
                    commentController: _commentController,
                  ),
                  if (widget.user.role == 'manager' || widget.user.role == 'admin') ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: (state is LeadLoaded && state.employees.isNotEmpty)
                        ? NeonDropdown<String>(
                            label: 'تعيين الموظف المسؤول (خاص بالإدارة)',
                            prefixIcon: Icons.person_outline,
                            value: state.employees.any((e) => e.id == _selectedEmployeeId) ? _selectedEmployeeId : null,
                            items: state.employees.map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.firstName != null ? "${e.firstName} ${e.lastName}" : e.email),
                            )).toList(),
                            onChanged: (val) => setState(() => _selectedEmployeeId = val),
                          )
                        : const Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  SizedBox(height: 32.h),

                  // 4. زر الحفظ
                  _buildSubmitButton(isEdit, _isSubmitting),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(bool isEdit, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.r8)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(
          isEdit ? 'تحديث بيانات العميل' : 'حفظ العميل الجديد',
          style: AppTextStyles.buttonLarge,
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      List<String> phones = _phoneControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

      final leadData = LeadModel(
        id: widget.lead?.id,
        clientName: _nameController.text,
        clientPhone: phones,
        propertyCode: _propertyCodeController.text,
        city: _selectedCity,
        leadStatus: _selectedStatus,
        descLeadNeed: _descController.text,
        comment: _commentController.text,
        source: _sourceController.text,
        createdBy: widget.lead?.createdBy ?? widget.user.id,
        assignedTo: _selectedEmployeeId ?? widget.user.id,
        createdAt: widget.lead?.createdAt ?? DateTime.now(),
      );

      if (widget.lead == null) {
        context.read<LeadCubit>().addLead(leadData);
      } else {
        // تم تغيير الاستدعاء هنا ليشمل التحديث الكامل
        context.read<LeadCubit>().updateFullLead(leadData);
      }
    }
  }
}