import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/property_shares_cubit.dart';
import '../widgets/property_card.dart';
import '../../../data/models/profile_model.dart';
import '../../admin_users/cubit/admin_users_cubit.dart';
import '../../admin_users/cubit/admin_users_state.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/static_data_manager.dart';
import 'package:intl/intl.dart';

class PropertySharesScreen extends StatefulWidget {
  final ProfileModel user;

  const PropertySharesScreen({super.key, required this.user});

  @override
  State<PropertySharesScreen> createState() => _PropertySharesScreenState();
}

class _PropertySharesScreenState extends State<PropertySharesScreen> {
  String? _selectedEmployeeId;
  late AdminUsersCubit _adminCubit;
  late PropertySharesCubit _sharesCubit;

  @override
  void initState() {
    super.initState();
    _adminCubit = di.sl<AdminUsersCubit>();
    _sharesCubit = PropertySharesCubit(widget.user.id);
    final role = widget.user.role;
    if (role == 'admin' || role == 'manager' || role == 'ceo') {
      _adminCubit.fetchAllUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canFilter = widget.user.role == 'admin' || widget.user.role == 'manager' || widget.user.role == 'ceo';

    return BlocProvider.value(
      value: _sharesCubit,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.bgMain,
          appBar: AppBar(
            title: Text('مشاركات العقارات', style: AppTextStyles.h2),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (canFilter)
                BlocBuilder<AdminUsersCubit, AdminUsersState>(
                  bloc: _adminCubit,
                  builder: (context, adminState) {
                    if (adminState is AdminUsersLoaded) {
                      final employees = adminState.users;
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Container(
                            height: 40.h,
                            constraints: BoxConstraints(maxWidth: 180.w),
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: AppColors.bgMain,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedEmployeeId,
                                hint: const Text("الكل"),
                                isExpanded: true,
                                icon: const Icon(Icons.filter_list_rounded, color: AppColors.brandPrimary),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text("أنا (شخصي)"),
                                  ),
                                  ...employees.map((e) => DropdownMenuItem(
                                        value: e.id,
                                        child: Text(
                                          "${e.firstName ?? ''} ${e.lastName ?? ''}".trim(),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedEmployeeId = val);
                                  _sharesCubit.fetchShares(filterByUserId: val ?? widget.user.id);
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    if (adminState is AdminUsersLoading) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator())),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
            bottom: const TabBar(
              indicatorColor: AppColors.brandPrimary,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "صندوق الوارد"),
                Tab(text: "المرسلة مني"),
              ],
            ),
          ),
          body: BlocBuilder<PropertySharesCubit, PropertySharesState>(
            builder: (context, state) {
              final targetId = _selectedEmployeeId ?? widget.user.id;
              
              if (state is PropertySharesLoading || state is PropertySharesInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is PropertySharesError) {
                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
              } else if (state is PropertySharesLoaded) {
                return Column(
                  children: [
                    if (state.hasNewUpdates)
                      GestureDetector(
                        onTap: () => _sharesCubit.fetchShares(filterByUserId: _selectedEmployeeId ?? widget.user.id),
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: AppColors.brandPrimary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'يوجد تحديثات للمشاركات، انقر للتحديث',
                                style: TextStyle(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Expanded(
                      child: TabBarView(
                        children: [
                          _TabWithFilters(shares: state.inbox, isInbox: true, targetId: targetId, user: widget.user),
                          _TabWithFilters(shares: state.sent, isInbox: false, targetId: targetId, user: widget.user),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _TabWithFilters extends StatefulWidget {
  final List shares;
  final bool isInbox;
  final String targetId;
  final ProfileModel user;

  const _TabWithFilters({
    required this.shares,
    required this.isInbox,
    required this.targetId,
    required this.user,
  });

  @override
  State<_TabWithFilters> createState() => _TabWithFiltersState();
}

class _TabWithFiltersState extends State<_TabWithFilters> {
  String? _selectedEmployeeId;
  DateTime? _selectedShareDate;
  DateTime? _selectedPropertyDate;

  @override
  Widget build(BuildContext context) {
    List filteredShares = widget.shares.where((share) {
      if (_selectedEmployeeId != null) {
        final otherId = widget.isInbox ? share.sender?.id : share.receiver?.id;
        if (otherId != _selectedEmployeeId) return false;
      }
      if (_selectedShareDate != null) {
        final shareDateStr = share.createdAt;
        if (shareDateStr != null) {
          final shareDate = DateTime.tryParse(shareDateStr);
          if (shareDate != null) {
            if (shareDate.year != _selectedShareDate!.year ||
                shareDate.month != _selectedShareDate!.month ||
                shareDate.day != _selectedShareDate!.day) {
              return false;
            }
          }
        }
      }
      if (_selectedPropertyDate != null) {
        final propDateStr = share.property?.createdAt;
        if (propDateStr != null) {
          final propDate = DateTime.tryParse(propDateStr);
          if (propDate != null) {
            if (propDate.year != _selectedPropertyDate!.year ||
                propDate.month != _selectedPropertyDate!.month ||
                propDate.day != _selectedPropertyDate!.day) {
              return false;
            }
          }
        }
      }
      return true;
    }).toList();

    final employees = di.sl<StaticDataManager>().employees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownMenu<String>(
                  expandedInsets: EdgeInsets.zero,
                  menuHeight: 200,
                  enableFilter: true,
                  label: Text(widget.isInbox ? "المرسل" : "المستقبل", style: TextStyle(fontSize: 14.sp)),
                  initialSelection: _selectedEmployeeId ?? '',
                  onSelected: (val) {
                    setState(() {
                      _selectedEmployeeId = (val == null || val.isEmpty) ? null : val;
                    });
                  },
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(value: '', label: "الكل"),
                    ...employees.map((e) => DropdownMenuEntry<String>(
                          value: e.id,
                          label: "${e.firstName} ${e.lastName}".trim(),
                        )),
                  ],
                  inputDecorationTheme: InputDecorationTheme(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedShareDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedShareDate = date);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedShareDate == null
                                ? "تاريخ المشاركة"
                                : DateFormat('yyyy-MM-dd').format(_selectedShareDate!),
                            style: TextStyle(fontSize: 12.sp, color: _selectedShareDate == null ? Colors.grey[600] : Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 1,
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedPropertyDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _selectedPropertyDate = date);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPropertyDate == null
                                ? "تاريخ العقار"
                                : DateFormat('yyyy-MM-dd').format(_selectedPropertyDate!),
                            style: TextStyle(fontSize: 12.sp, color: _selectedPropertyDate == null ? Colors.grey[600] : Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedEmployeeId != null || _selectedShareDate != null || _selectedPropertyDate != null)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.red, size: 20.sp),
                  onPressed: () {
                    setState(() {
                      _selectedEmployeeId = null;
                      _selectedShareDate = null;
                      _selectedPropertyDate = null;
                    });
                  },
                ),
            ],
          ),
        ),
        if (filteredShares.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.isInbox ? Icons.inbox_rounded : Icons.send_rounded, size: 60.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    "لا توجد نتائج",
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Text(
              "النتائج: ${filteredShares.length}",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8.h, bottom: 32.h),
              itemCount: filteredShares.length,
              itemBuilder: (context, index) {
                final share = filteredShares[index];
                final otherPerson = widget.isInbox ? share.sender : share.receiver;
                final otherName = otherPerson != null
                    ? "${otherPerson.firstName} ${otherPerson.lastName}".trim()
                    : null;

                if (share.property == null) {
                  return Padding(
                    padding: EdgeInsets.all(24.h),
                    child: Center(
                      child: Text(
                        "تم حذف هذا العقار من النظام",
                        style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                      ),
                    ),
                  );
                }

                return PropertyCard(
                  property: share.property!,
                  currentUserId: widget.user.id,
                  role: widget.user.role,
                  isSharedView: true,
                  sharedNotes: share.notes,
                  sharedBy: otherName,
                  onTap: () {},
                  onDelete: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تأكيد الإزالة'),
                        content: const Text('هل أنت متأكد من إزالة هذا العقار من قائمتك؟\n(لن يتم إزالته من قائمة الطرف الآخر)'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.read<PropertySharesCubit>().deleteShare(share.id, !widget.isInbox);
                            },
                            child: const Text('نعم، أزل', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
