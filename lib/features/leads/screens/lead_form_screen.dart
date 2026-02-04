
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


class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;
  final String currentUserId;

  const LeadFormScreen({super.key, this.lead, required this.currentUserId});

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
  List<City> _allCities = [];
  bool _isLoadingCities = true;

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

    return BlocListener<LeadCubit, LeadState>(
      listener: (context, state) {
        if (state is LeadLoaded) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ البيانات بنجاح"), backgroundColor: Colors.green),
          );
        } else if (state is LeadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.brandAccent),
          );
        }
      },
      child: Scaffold(
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
            padding: EdgeInsets.all(AppConstants.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("المعلومات الأساسية"),
                _buildTextField(_nameController, "اسم العميل بالكامل *", Icons.person_outline, isRequired: true),
                SizedBox(height: AppConstants.p16),
                _buildSectionTitle("أرقام التواصل *"),
                ..._buildPhoneFields(),
                SizedBox(height: AppConstants.p16),
                Row(
                  children: [
                    Expanded(child: _buildCityDropdown()),
                    SizedBox(width: AppConstants.p16),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                ),
                SizedBox(height: AppConstants.p24),
                _buildSectionTitle("تفاصيل العقار والاحتياج"),
                _buildTextField(_propertyCodeController, "كود العقار المهتم به", Icons.home_work_outlined),
                SizedBox(height: AppConstants.p16),
                _buildTextField(_sourceController, "مصدر العميل (فيسبوك، ترشيح...)", Icons.campaign_outlined),
                SizedBox(height: AppConstants.p16),
                _buildTextField(_descController, "وصف دقيق لما يبحث عنه العميل", Icons.description_outlined, maxLines: 3),
                SizedBox(height: AppConstants.p16),
                _buildTextField(_commentController, "ملاحظات إضافية للموظف", Icons.note_alt_outlined, maxLines: 2),
                SizedBox(height: AppConstants.p32),
                _buildSubmitButton(isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- [ UI Build Methods ] ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppConstants.p8, right: AppConstants.p4),
      child: Text(title, style: AppTextStyles.inputLabel),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.brandPrimary, size: AppConstants.iconMd),
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding: EdgeInsets.all(AppConstants.p16),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.r8), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.r8), borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5)),
      ),
      validator: (val) => isRequired && (val == null || val.isEmpty) ? "هذا الحقل مطلوب" : null,
    );
  }

  List<Widget> _buildPhoneFields() {
    return _phoneControllers.asMap().entries.map((entry) {
      int idx = entry.key;
      return Padding(
        padding: EdgeInsets.only(bottom: AppConstants.p8),
        child: Row(
          children: [
            Expanded(child: _buildTextField(entry.value, "رقم التليفون", Icons.phone_android_rounded, isRequired: idx == 0)),
            SizedBox(width: AppConstants.p8),
            if (idx == 0)
              _buildCircularAction(Icons.add, AppColors.success, () => setState(() => _phoneControllers.add(TextEditingController())))
            else
              _buildCircularAction(Icons.remove, AppColors.brandAccent, () => setState(() => _phoneControllers.removeAt(idx))),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildCityDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSectionTitle("المدينة"), DropdownButtonFormField<String>(value: _selectedCity, isExpanded: true, icon: const Icon(Icons.arrow_drop_down, color: AppColors.brandPrimary), style: AppTextStyles.inputText, decoration: _dropdownDecoration(), items: _allCities.map((city) => DropdownMenuItem(value: city.nameAr, child: Text(city.nameAr, overflow: TextOverflow.ellipsis))).toList(), onChanged: (val) => setState(() => _selectedCity = val))]);
  }

  Widget _buildStatusDropdown() {
    final statuses = ['جديد', 'تم التواصل', 'تفاوض', 'تم التعاقد', 'مستبعد'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildSectionTitle("الحالة"), DropdownButtonFormField<String>(value: _selectedStatus, icon: const Icon(Icons.arrow_drop_down, color: AppColors.brandPrimary), style: AppTextStyles.inputText, decoration: _dropdownDecoration(), items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (val) => setState(() => _selectedStatus = val))]);
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(filled: true, fillColor: AppColors.bgSurface, contentPadding: EdgeInsets.symmetric(horizontal: AppConstants.p16, vertical: AppConstants.p8), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.r8), borderSide: const BorderSide(color: AppColors.borderSubtle)));
  }

  Widget _buildCircularAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: EdgeInsets.all(AppConstants.p8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: AppConstants.iconMd)));
  }

  Widget _buildSubmitButton(bool isEdit) {
    // 1. نستخدم BlocBuilder لمراقبة حالة الكيوبيت
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        // 2. نتحقق هل الحالة الحالية هي حالة تحميل؟
        final isLoading = state is LeadLoading;

        return SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton(
            // 3. إذا كان يحمل، نجعل onPressed تساوي null لتعطيل الزر
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.r8)),
              elevation: 0,
            ),
            // 4. هنا الشرط: إذا كان يحمل أظهر مؤشر التحميل، وإلا أظهر النص العادي
            child: isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(
              isEdit ? 'تحديث بيانات العميل' : 'حفظ العميل الجديد',
              style: AppTextStyles.buttonLarge,
            ),
          ),
        );
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
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
        createdBy: widget.lead?.createdBy ?? widget.currentUserId,
        assignedTo: widget.lead?.assignedTo ?? widget.currentUserId,
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