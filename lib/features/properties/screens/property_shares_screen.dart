import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/property_shares_cubit.dart';
import '../widgets/property_share_card.dart';
import '../../../data/models/profile_model.dart';
import '../../admin_users/cubit/admin_users_cubit.dart';
import '../../admin_users/cubit/admin_users_state.dart';
import '../../../core/di/injection_container.dart' as di;

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
                return TabBarView(
                  children: [
                    _buildTabContent(context, state.inbox, isInbox: true, targetId: targetId),
                    _buildTabContent(context, state.sent, isInbox: false, targetId: targetId),
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

  Widget _buildTabContent(BuildContext context, List shares, {required bool isInbox, required String targetId}) {
    if (shares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isInbox ? Icons.inbox_rounded : Icons.send_rounded, size: 60.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              isInbox ? "لا توجد عقارات مرسلة إليك حالياً" : "لم تقم بمشاركة أي عقار بعد",
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          child: Text(
            "عدد المشاركات: ${shares.length}",
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 8.h, bottom: 32.h),
      itemCount: shares.length,
      itemBuilder: (context, index) {
        final share = shares[index];
        return PropertyShareCard(
          share: share,
          isInbox: isInbox,
          currentUserId: widget.user.id,
          onDelete: () {
            // Confirm delete
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
                      context.read<PropertySharesCubit>().deleteShare(share.id, !isInbox);
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
    );
  }
}
