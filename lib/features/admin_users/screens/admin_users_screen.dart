import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/static_data_manager.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/admin_users_cubit.dart';
import '../cubit/admin_users_state.dart';

class AdminUsersScreen extends StatefulWidget {
  final ProfileModel currentUser;
  const AdminUsersScreen({super.key, required this.currentUser});

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
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminUsersCubit>(),
        child: Dialog(
          child: SizedBox(
            width: 500,
            child: _AddUserForm(currentUser: widget.currentUser),
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(ProfileModel user) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminUsersCubit>(),
        child: _EditUserDialog(user: user, currentUser: widget.currentUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: Text('إدارة حسابات الموظفين', style: AppTextStyles.h2),
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            labelColor: AppColors.brandPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.brandPrimary,
            tabs: [
              Tab(text: 'الحسابات النشطة', icon: Icon(Icons.check_circle_outline)),
              Tab(text: 'الحسابات الموقوفة', icon: Icon(Icons.block)),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: "admin_users_fab",
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
                              Text('loading@example.com', style: AppTextStyles.h1.copyWith(fontSize: 12.sp)),
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
            final activeUsers = cubitState.users.where((u) => u.isActive).toList();
            final inactiveUsers = cubitState.users.where((u) => !u.isActive).toList();
            return TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () => context.read<AdminUsersCubit>().fetchAllUsers(),
                  child: _buildUsersTable(activeUsers, context, isActiveTab: true),
                ),
                RefreshIndicator(
                  onRefresh: () => context.read<AdminUsersCubit>().fetchAllUsers(),
                  child: _buildUsersTable(inactiveUsers, context, isActiveTab: false),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    ));
  }

  Widget _buildUsersTable(List<ProfileModel> users, BuildContext context, {required bool isActiveTab}) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          isActiveTab ? 'لا يوجد حسابات نشطة' : 'لا يوجد حسابات موقوفة',
          style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.p16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.brandPrimary.withOpacity(0.05)),
                dataRowMinHeight: 60.h,
                dataRowMaxHeight: 60.h,
                columns: [
                  const DataColumn(label: Text('الموظف', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('البريد الإلكتروني', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text(isActiveTab ? 'إجراءات' : 'إعادة تفعيل', style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: users.map((user) {
                  return DataRow(
                    color: !isActiveTab ? WidgetStateProperty.all(Colors.grey.withOpacity(0.05)) : null,
                    cells: [
                    DataCell(Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundImage: user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
                          child: user.imageUrl == null ? const Icon(Icons.person, size: 16) : null,
                        ),
                        SizedBox(width: 8.w),
                        Text(user.fullName, style: TextStyle(fontWeight: FontWeight.bold, color: isActiveTab ? Colors.black : Colors.grey)),
                      ],
                    )),
                    DataCell(Text(user.email, style: TextStyle(color: isActiveTab ? Colors.black : Colors.grey))),
                    DataCell(Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? AppColors.brandAccent.withOpacity(0.1) : AppColors.brandPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: AppTextStyles.chipLabel.copyWith(
                          color: isActiveTab ? (user.isAdmin ? AppColors.brandAccent : AppColors.brandPrimary) : Colors.grey,
                        ),
                      ),
                    )),
                    DataCell(isActiveTab 
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                          onPressed: () => _showEditUserDialog(user),
                        )
                      : TextButton.icon(
                          onPressed: () {
                            context.read<AdminUsersCubit>().reactivateUser(user.id);
                          },
                          icon: const Icon(Icons.restore, color: Colors.green),
                          label: const Text('إعادة تفعيل', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        )
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddUserForm extends StatefulWidget {
  final ProfileModel currentUser;
  const _AddUserForm({required this.currentUser});

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
              RetajDropdown<String>(
                label: 'الصلاحية',
                value: _selectedRole,
                items: AppPermissions.creatableRoles(widget.currentUser.appRole).map((role) {
                  return DropdownMenuItem<String>(
                    value: role.toDbString(),
                    child: Text(role.nameAr),
                  );
                }).toList(),
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
  final ProfileModel currentUser;
  const _EditUserDialog({required this.user, required this.currentUser});

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
            RetajDropdown<String>(
              label: 'تغيير الصلاحية',
              value: _selectedRole,
              items: () {
                final roles = AppPermissions.creatableRoles(widget.currentUser.appRole).toList();
                final currentRoleObj = AppRole.fromString(_selectedRole);
                if (!roles.contains(currentRoleObj)) {
                  roles.add(currentRoleObj);
                }
                return roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role.toDbString(),
                    child: Text(role.nameAr),
                  );
                }).toList();
              }(),
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
              onPressed: (widget.user.id == widget.currentUser.id || widget.user.appRole == AppRole.superAdmin) ? null : () {
                showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<AdminUsersCubit>(),
                    child: _DeleteUserConfirmationDialog(user: widget.user, currentUser: widget.currentUser),
                  ),
                );
              },
              child: Text(
                'إيقاف الحساب ونقل العهدة',
                style: TextStyle(color: (widget.user.id == widget.currentUser.id || widget.user.appRole == AppRole.superAdmin) ? Colors.grey : AppColors.brandAccent, fontWeight: FontWeight.bold),
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
  final ProfileModel currentUser;
  const _DeleteUserConfirmationDialog({required this.user, required this.currentUser});

  @override
  State<_DeleteUserConfirmationDialog> createState() => _DeleteUserConfirmationDialogState();
}

class _DeleteUserConfirmationDialogState extends State<_DeleteUserConfirmationDialog> {
  final _nameCtrl = TextEditingController();
  String? _replaceWithId;
  bool _canDelete = false;
  int? _leadsCount;
  int? _propertiesCount;
  bool _isLoadingCounts = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    try {
      final counts = await context.read<AdminUsersCubit>().getEmployeeCustodyCount(widget.user.id);
      if (mounted) {
        setState(() {
          _leadsCount = counts['leads'];
          _propertiesCount = counts['properties'];
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCounts) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final hasCustody = (_leadsCount != null && _leadsCount! > 0) || (_propertiesCount != null && _propertiesCount! > 0);

    return AlertDialog(
      title: Text(hasCustody ? 'إيقاف الحساب ونقل العهدة' : 'إيقاف الحساب', style: const TextStyle(color: AppColors.brandAccent)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hasCustody 
            ? 'سيتم إيقاف هذا الحساب لمنعه من الدخول. يمتلك هذا الموظف ($_leadsCount عميل) و ($_propertiesCount عقار).\nيجب عليك اختيار موظف بديل لتنتقل إليه كل هذه العهدة.'
            : 'هذا الموظف لا يمتلك أي عملاء أو عقارات. يمكنك إيقاف الحساب مباشرة.'
          ),
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
          if (hasCustody) ...[
            SizedBox(height: 16.h),
            const Text('إجباري: اختر موظف لنقل العهدة إليه:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('اختر الموظف البديل (مطلوب)'),
              value: _replaceWithId,
              items: di.sl<StaticDataManager>()
                  .employees
                  .where((e) => e.id != widget.user.id)
                  .map((e) => DropdownMenuItem(value: e.id, child: Text("${e.firstName} ${e.lastName}")))
                  .toList(),
              validator: (value) => value == null ? 'الرجاء اختيار موظف بديل' : null,
              onChanged: (v) => setState(() => _replaceWithId = v),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        BlocBuilder<AdminUsersCubit, AdminUsersState>(
          builder: (context, state) {
            final isLoading = state is AdminUsersLoading;
            return ElevatedButton(
              onPressed: _canDelete && (!hasCustody || _replaceWithId != null) && !isLoading ? () {
                context.read<AdminUsersCubit>().deactivateUser(
                  widget.user.id, 
                  replaceWithId: _replaceWithId ?? widget.currentUser.id, // Fallback if no custody
                  adminId: widget.currentUser.id
                ).then((_) {
                  if (mounted && context.read<AdminUsersCubit>().state is AdminActionSuccess) {
                    Navigator.pop(context); // إغلاق نافذة التأكيد
                    Navigator.pop(context); // إغلاق نافذة التعديل
                  }
                });
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandAccent),
              child: isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text(hasCustody ? 'إيقاف ونقل' : 'إيقاف', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
        )
      ]
    );
  }
}
