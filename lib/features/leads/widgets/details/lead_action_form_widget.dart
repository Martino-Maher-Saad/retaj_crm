import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../data/models/lead_model.dart';
import '../../../../data/models/profile_model.dart';
import '../../../auth/cubit/auth_cubit.dart';
import '../../../auth/cubit/auth_states.dart';
import '../../cubit/leads_cubit.dart';

class LeadActionFormWidget extends StatefulWidget {
  final LeadModel lead;

  const LeadActionFormWidget({super.key, required this.lead});

  @override
  State<LeadActionFormWidget> createState() => _LeadActionFormWidgetState();
}

class _LeadActionFormWidgetState extends State<LeadActionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _meetingLocationController =
      TextEditingController();
  String? _selectedMeetingPurpose;
  final TextEditingController _dealPropertyCodeController =
      TextEditingController();
  final TextEditingController _dealCommissionController =
      TextEditingController();

  bool _isAddingAction = false;
  String? _selectedStatusId;
  bool _clientReplied = true;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _exclusionReason;

  @override
  void initState() {
    super.initState();
    _selectedStatusId = widget.lead.statusId;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _meetingLocationController.dispose();
    _dealPropertyCodeController.dispose();
    _dealCommissionController.dispose();
    super.dispose();
  }

  String _getBehavior(String? statusId) {
    if (statusId == null) return '';
    final status = sl<StaticDataManager>().getOptionById(
      'lead_status',
      statusId,
    );
    if (status == null) return '';
    final stageTypeId = status.extra?['stage_type_id'];
    if (stageTypeId == null) return '';
    final stageType = sl<StaticDataManager>().getOptionById(
      'stage_types',
      stageTypeId,
    );
    return stageType?.extra?['behavior'] ?? '';
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _submitAction() async {
    if (!_formKey.currentState!.validate()) return;

    final newStatusId = _selectedStatusId;
    if (newStatusId == null) return;

    final behavior = _getBehavior(newStatusId);

    // Validations
    if ((behavior == 'meeting' ||
            behavior == 'following' ||
            behavior == 'fresh' ||
            behavior == 'done_deal') &&
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء تحديد التاريخ والوقت')),
      );
      return;
    }

    if (behavior == 'meeting' && _selectedMeetingPurpose == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('برجاء تحديد غرض المقابلة')));
      return;
    }

    if (behavior == 'exclusion' && _exclusionReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء تحديد سبب الاستبعاد')),
      );
      return;
    }

    setState(() => _isAddingAction = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess) {
        throw 'المستخدم غير مسجل الدخول';
      }
      final profile = authState.user;

      double? profit;
      if (behavior == 'done_deal' &&
          _dealCommissionController.text.isNotEmpty) {
        profit = double.tryParse(_dealCommissionController.text.trim());
      }

      DateTime? scheduled;
      if (_selectedDate != null && _selectedTime != null) {
        scheduled = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      await context.read<LeadCubit>().addLeadAction(
        leadId: widget.lead.id!,
        comment: _commentController.text.trim(),
        nextStatusId: newStatusId,
        scheduledAt: scheduled,
        meetingTypeId: null, // Depending on if we have meeting types dropdown
        meetingPurposeId: _selectedMeetingPurpose,
        meetingLocation: behavior == 'meeting'
            ? _meetingLocationController.text.trim()
            : null,
        exclusionReasonId: behavior == 'exclusion' ? _exclusionReason : null,
        propertyCode: behavior == 'done_deal'
            ? _dealPropertyCodeController.text.trim()
            : null,
        companyProfit: profit,
        role: profile.role,
        userId: profile.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الأكشن بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _commentController.clear();
        _meetingLocationController.clear();
        _selectedMeetingPurpose = null;
        _dealPropertyCodeController.clear();
        _dealCommissionController.clear();
        setState(() {
          _selectedDate = null;
          _selectedTime = null;
        });
      }
    } catch (e, stackTrace) {
      print('====================================');
      print('SUBMIT ACTION ERROR: $e');
      print('STACKTRACE: $stackTrace');
      print('====================================');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final behavior = _getBehavior(_selectedStatusId);
    final dataManager = sl<StaticDataManager>();
    final statuses = dataManager.getOptions('lead_status');

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إضافة إجراء (Action)',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.brandPrimary,
              ),
            ),
            SizedBox(height: 16.h),

            // رد العميل
            Row(
              children: [
                Text(
                  'هل رد العميل؟',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 16.w),
                ChoiceChip(
                  label: const Text('نعم'),
                  selected: _clientReplied,
                  onSelected: (v) => setState(() => _clientReplied = true),
                  selectedColor: Colors.green.shade100,
                ),
                SizedBox(width: 8.w),
                ChoiceChip(
                  label: const Text('لا'),
                  selected: !_clientReplied,
                  onSelected: (v) => setState(() => _clientReplied = false),
                  selectedColor: Colors.red.shade100,
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // الحالة الجديدة (Next Stage)
            RetajDropdown<String>(
              label: 'حالة العميل (المرحلة القادمة)',
              prefixIcon: Icons.low_priority,
              value: _selectedStatusId != null
                  ? dataManager
                        .getOptionById('lead_status', _selectedStatusId!)
                        ?.nameAr
                  : null,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'اختر الحالة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ...statuses.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s)),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(
                    () => _selectedStatusId = dataManager.getIdByName(
                      'lead_status',
                      v,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 16.h),

            // الحقول الشرطية
            if (behavior == 'meeting') ...[
              _buildTextField(
                _meetingLocationController,
                'مكان المقابلة',
                Icons.location_on,
                true,
              ),
              SizedBox(height: 12.h),
              RetajDropdown<String>(
                label: 'الغرض من المقابلة',
                prefixIcon: Icons.flag,
                value: _selectedMeetingPurpose,
                items: dataManager
                    .getOptions('meeting_purposes')
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMeetingPurpose = v),
              ),
              SizedBox(height: 12.h),
            ],

            if (behavior == 'done_deal') ...[
              _buildTextField(
                _dealPropertyCodeController,
                'كود العقار',
                Icons.home,
                true,
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                _dealCommissionController,
                'نسبة العمولة (%)',
                Icons.percent,
                true,
                isNumber: true,
              ),
              SizedBox(height: 12.h),
            ],

            if (behavior == 'exclusion') ...[
              RetajDropdown<String>(
                label: 'سبب الاستبعاد',
                prefixIcon: Icons.cancel,
                value: _exclusionReason,
                items: dataManager
                    .getOptions('lead_exclusion_reasons')
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _exclusionReason = v),
              ),
              SizedBox(height: 12.h),
            ],

            if (behavior == 'meeting' ||
                behavior == 'following' ||
                behavior == 'fresh' ||
                behavior == 'done_deal') ...[
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: AppColors.brandPrimary,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _selectedDate == null
                            ? 'حدد التاريخ والوقت *'
                            : DateFormat('yyyy-MM-dd HH:mm').format(
                                DateTime(
                                  _selectedDate!.year,
                                  _selectedDate!.month,
                                  _selectedDate!.day,
                                  _selectedTime!.hour,
                                  _selectedTime!.minute,
                                ),
                              ),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _selectedDate == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // التعليق
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: behavior == 'exclusion'
                    ? 'تفاصيل إضافية (اختياري)'
                    : 'ملاحظات / تعليق *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.comment),
              ),
              validator: (v) {
                if (behavior != 'exclusion' &&
                    (v == null || v.trim().isEmpty)) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              },
            ),
            SizedBox(height: 16.h),

            // زر الحفظ
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isAddingAction ? null : _submitAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isAddingAction
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'حفظ الأكشن',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isRequired, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: '$label ${isRequired ? '*' : ''}',
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) return 'مطلوب';
        return null;
      },
    );
  }
}
