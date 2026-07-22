import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/models/task_model.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/static_data_manager.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../core/widgets/custom_button.dart';
import '../cubit/tasks_cubit.dart';

class TaskFormDialog extends StatefulWidget {
  final ProfileModel currentUser;
  final TaskModel? task;
  final String? prefilledLeadId;
  final String? prefilledPropertyId;
  final TasksCubit? cubit; // Optional: if null, we create or locate one. But passing is safer.

  const TaskFormDialog({
    super.key,
    required this.currentUser,
    this.task,
    this.prefilledLeadId,
    this.prefilledPropertyId,
    this.cubit,
  });

  static Future<void> show(
    BuildContext context, {
    required ProfileModel currentUser,
    TaskModel? task,
    String? prefilledLeadId,
    String? prefilledPropertyId,
    TasksCubit? cubit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TaskFormDialog(
        currentUser: currentUser,
        task: task,
        prefilledLeadId: prefilledLeadId,
        prefilledPropertyId: prefilledPropertyId,
        cubit: cubit,
      ),
    );
  }

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _assignedToId;
  String? _taskStatusId;

  final _dataManager = di.sl<StaticDataManager>();
  late bool _isManager;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isManager = widget.currentUser.appRole.isAtLeast(AppRole.manager);
    
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedDate = widget.task!.endDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.endDate.toLocal());
      _assignedToId = widget.task!.assignedTo;
      _taskStatusId = widget.task!.statusId;
    } else {
      _assignedToId = widget.currentUser.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (time != null) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_taskStatusId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار حالة المهمة')));
      return;
    }

    setState(() => _isLoading = true);

    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final task = TaskModel(
      id: widget.task?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      createdBy: widget.currentUser.id,
      assignedTo: _assignedToId ?? widget.currentUser.id,
      endDate: dateTime,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      statusId: _taskStatusId!,
      leadId: widget.task?.leadId ?? widget.prefilledLeadId,
      propertyId: widget.task?.propertyId ?? widget.prefilledPropertyId,
    );

    try {
      final cubitToUse = widget.cubit ?? di.sl<TasksCubit>();
      if (widget.task == null) {
        await cubitToUse.addTask(task); // Assuming this is an async operation, if not we ignore wait.
      } else {
        await cubitToUse.updateTask(task.id, task);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 500.w,
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.task == null ? "إضافة مهمة جديدة" : "تعديل المهمة",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 24.h),
              
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RetajTextField(
                        label: "عنوان المهمة",
                        controller: _titleController,
                        validator: (v) => v == null || v.isEmpty ? "مطلوب" : null,
                      ),
                      SizedBox(height: 16.h),
                      RetajTextField(
                        label: "الوصف",
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      SizedBox(height: 16.h),
                      RetajDropdown<String>(
                        label: "حالة المهمة",
                        value: _taskStatusId,
                        items: _dataManager.getOptionModels('task_status')
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameAr)))
                            .toList(),
                        onChanged: (v) => setState(() => _taskStatusId = v),
                      ),
                      SizedBox(height: 16.h),
                      if (_isManager)
                        RetajDropdown<String>(
                          label: "إسناد إلى",
                          value: _assignedToId,
                          items: _dataManager.employees
                              .map((e) => DropdownMenuItem(value: e.id, child: Text("${e.firstName} ${e.lastName}")))
                              .toList(),
                          onChanged: (v) => setState(() => _assignedToId = v),
                        ),
                      SizedBox(height: 16.h),
                      InkWell(
                        onTap: _selectDateTime,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderStrong),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "الموعد: ${DateFormat('yyyy-MM-dd').format(_selectedDate)} - ${_selectedTime.format(context)}",
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              Icon(Icons.calendar_today, size: 20.sp, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      isCenter: true,
                      title: "حفظ المهمة",
                      onTap: _saveTask,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
