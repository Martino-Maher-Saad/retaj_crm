import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/admin_users_cubit.dart';
import '../cubit/admin_users_state.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminUsersCubit>().fetchAllUsers();
  }

  void _showAddUserBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminUsersCubit>(),
        child: const _AddUserForm(),
      ),
    );
  }

  void _showEditUserDialog(ProfileModel user) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminUsersCubit>(),
        child: _EditUserDialog(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        title: Text('إدارة حسابات الموظفين', style: AppTextStyles.h2),
        backgroundColor: AppColors.bgSurface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserBottomSheet,
        backgroundColor: AppColors.brandPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة موظف',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<AdminUsersCubit, AdminUsersState>(
        listener: (context, state) {
          if (state is AdminUsersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.brandAccent,
              ),
            );
          } else if (state is AdminActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AdminUsersInitial ||
              state is AdminUsersLoading &&
                  context.read<AdminUsersCubit>().state is! AdminUsersLoaded) {
            return Skeletonizer(
              enabled: true,
              child: ListView.separated(
                padding: EdgeInsets.all(AppConstants.p16).copyWith(bottom: 80.h),
                itemCount: 4,
                separatorBuilder: (_, __) => SizedBox(height: AppConstants.p16),
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderSubtle, width: 1.w),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 24.r, backgroundColor: AppColors.bgMain),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('جاري التحميل...', style: AppTextStyles.h3),
                              SizedBox(height: 4.h),
                              Text('loading@example.com', style: AppTextStyles.blue32Bold.copyWith(fontSize: 12.sp)),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          color: Colors.grey.withOpacity(0.1),
                          child: const Text('ROL'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
          final cubitState = context.read<AdminUsersCubit>().state;
          if (cubitState is AdminUsersLoaded) {
            final users = cubitState.users;
            return RefreshIndicator(
              onRefresh: () => context.read<AdminUsersCubit>().fetchAllUsers(),
              child: ListView.separated(
                padding: EdgeInsets.all(
                  AppConstants.p16,
                ).copyWith(bottom: 80.h),
                itemCount: users.length,
                separatorBuilder: (_, __) => SizedBox(height: AppConstants.p16),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.borderSubtle, width: 1.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10.r,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24.r,
                          backgroundColor: AppColors.bgMain,
                          backgroundImage:
                              user.imageUrl != null && user.imageUrl!.isNotEmpty
                              ? NetworkImage(user.imageUrl!)
                              : null,
                          child:
                              (user.imageUrl == null || user.imageUrl!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  color: AppColors.textDisabled,
                                )
                              : null,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName, style: AppTextStyles.h3),
                              SizedBox(height: 4.h),
                              Text(
                                user.email,
                                style: AppTextStyles.blue32Bold.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? AppColors.brandAccent.withOpacity(0.1)
                                : AppColors.brandPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: AppTextStyles.chipLabel.copyWith(
                              color: user.isAdmin
                                  ? AppColors.brandAccent
                                  : AppColors.brandPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _showEditUserDialog(user),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _AddUserForm extends StatefulWidget {
  const _AddUserForm();

  @override
  State<_AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<_AddUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String _selectedRole = 'sales';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: 20.h,
        bottom: bottomInset > 0 ? bottomInset + 20.h : 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('إنشاء حساب موظف جديد', style: AppTextStyles.h2),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الأول',
                        filled: true,
                      ),
                      validator: (v) => v!.isEmpty ? '*' : null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextFormField(
                      controller: _lastCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الاسم الأخير',
                        filled: true,
                      ),
                      validator: (v) => v!.isEmpty ? '*' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  filled: true,
                ),
                validator: (v) => v!.isEmpty ? '*' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الابتدائية',
                  filled: true,
                ),
                validator: (v) => v!.length < 6 ? 'قصير جداً' : null,
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'الصلاحية',
                  filled: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'sales',
                    child: Text('Sales (موظف مبيعات)'),
                  ),
                  DropdownMenuItem(
                    value: 'manager',
                    child: Text('Manager (مدير القسم)'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin (إدارة كاملة)'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: BlocBuilder<AdminUsersCubit, AdminUsersState>(
                  builder: (context, state) {
                    final isLoading = state is AdminUsersLoading;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                context
                                    .read<AdminUsersCubit>()
                                    .createNewUser(
                                      email: _emailCtrl.text,
                                      password: _passCtrl.text,
                                      role: _selectedRole,
                                      firstName: _firstCtrl.text,
                                      lastName: _lastCtrl.text,
                                    )
                                    .then((_) {
                                      if (mounted &&
                                          context.read<AdminUsersCubit>().state
                                              is AdminActionSuccess)
                                        Navigator.pop(context);
                                    });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('تكوين الحساب وإرسال الدخول'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final ProfileModel user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late TextEditingController _emailCtrl;
  late TextEditingController _passCtrl;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.user.email);
    _passCtrl = TextEditingController();
    
    final validRoles = ['sales', 'manager', 'admin', 'user'];
    _selectedRole = validRoles.contains(widget.user.role.toLowerCase())
        ? widget.user.role.toLowerCase()
        : 'sales';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعديل حساب: ${widget.user.firstName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني الجديد',
              ),
            ),
            SizedBox(height: 10.h),
            TextFormField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'كلمة مرور جديدة (اختياري)',
                hintText: 'دعها فارغة لعدم التغيير',
              ),
            ),
            SizedBox(height: 10.h),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'تغيير الصلاحية'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User (عام)')),
                DropdownMenuItem(value: 'sales', child: Text('Sales')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<AdminUsersCubit>(),
                    child: _DeleteUserConfirmationDialog(user: widget.user),
                  ),
                );
              },
              child: const Text(
                'حذف الحساب',
                style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                BlocBuilder<AdminUsersCubit, AdminUsersState>(
                  builder: (context, state) {
                    final isLoading = state is AdminUsersLoading;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context
                                  .read<AdminUsersCubit>()
                                  .updateUserAdmin(
                                    widget.user.id,
                                    email: _emailCtrl.text != widget.user.email
                                        ? _emailCtrl.text
                                        : null,
                                    password: _passCtrl.text.isNotEmpty
                                        ? _passCtrl.text
                                        : null,
                                    role: _selectedRole != widget.user.role
                                        ? _selectedRole
                                        : null,
                                  )
                                  .then((_) {
                                    if (mounted &&
                                        context.read<AdminUsersCubit>().state
                                            is AdminActionSuccess) {
                                      Navigator.pop(context);
                                    }
                                  });
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('حفظ'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DeleteUserConfirmationDialog extends StatefulWidget {
  final ProfileModel user;
  const _DeleteUserConfirmationDialog({required this.user});

  @override
  State<_DeleteUserConfirmationDialog> createState() => _DeleteUserConfirmationDialogState();
}

class _DeleteUserConfirmationDialogState extends State<_DeleteUserConfirmationDialog> {
  final _nameCtrl = TextEditingController();
  bool _canDelete = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحذير خطير: حذف نهائي', style: TextStyle(color: AppColors.brandAccent)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('سيتم حذف هذا الحساب نهائياً، وسيتم معه مسح جميع العقارات والعملاء المرتبطين به بسبب نظام الـ Cascade.'),
          SizedBox(height: 16.h),
          Text('للتأكيد، يرجى كتابة الاسم الأول للموظف בדיוק: "${widget.user.firstName}"', style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          TextFormField(
            controller: _nameCtrl,
            onChanged: (v) {
              setState(() => _canDelete = (v.trim() == widget.user.firstName));
            },
            decoration: const InputDecoration(
              hintText: 'اكتب اسم الموظف هنا...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        BlocBuilder<AdminUsersCubit, AdminUsersState>(
          builder: (context, state) {
            final isLoading = state is AdminUsersLoading;
            return ElevatedButton(
              onPressed: _canDelete && !isLoading ? () {
                context.read<AdminUsersCubit>().deleteUser(widget.user.id).then((_) {
                  if (mounted && context.read<AdminUsersCubit>().state is AdminActionSuccess) {
                    Navigator.pop(context); // إغلاق نافذة التأكيد
                    Navigator.pop(context); // إغلاق نافذة التعديل
                  }
                });
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent),
              child: isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text('حذف نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
        )
      ]
    );
  }
}
