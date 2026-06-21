import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/dashboard_cubit.dart';
import 'employee_dashboard_view.dart';
import 'manager_dashboard_view.dart';

class DashboardScreen extends StatefulWidget {
  final ProfileModel user;

  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  late DashboardCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<DashboardCubit>();
    if (widget.user.role == 'sales') {
      _cubit.loadEmployeeDashboard(userId: widget.user.id);
    } else {
      _cubit.loadManagerDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: widget.user.role == 'sales'
          ? EmployeeDashboardView(user: widget.user)
          : ManagerDashboardView(user: widget.user),
    );
  }
}

/// ─── Date Filter Bar (Date Range Picker Button) ───
class DashboardDateFilter extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final void Function(DateTime start, DateTime end) onChanged;

  const DashboardDateFilter({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startStr = intl.DateFormat('yyyy/MM/dd').format(startDate);
    final endStr = intl.DateFormat('yyyy/MM/dd').format(endDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: InkWell(
        onTap: () => _pickDateRange(context),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.arrow_drop_down, color: AppColors.brandPrimary, size: 24.sp),
              const Spacer(),
              Text(
                '$endStr  ◀  $startStr',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'الفترة الزمنيّة:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A2E), fontFamily: 'Cairo'),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.calendar_month_rounded, color: AppColors.brandPrimary, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
    if (picked != null) {
      onChanged(picked.start, picked.end);
    }
  }
}

/// ─── Summary Card ───
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool? isUp; // null = neutral

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            Colors.white,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (subtitle != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: (isUp == true
                            ? const Color(0xFF10B981)
                            : isUp == false
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF888899))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isUp == true
                              ? const Color(0xFF10B981)
                              : isUp == false
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF888899),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        isUp == true
                            ? Icons.trending_up_rounded
                            : isUp == false
                                ? Icons.trending_down_rounded
                                : Icons.remove_rounded,
                        size: 13.sp,
                        color: isUp == true
                            ? const Color(0xFF10B981)
                            : isUp == false
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF888899),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Section Card Wrapper ───
class DashboardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const DashboardSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(icon, color: AppColors.brandPrimary, size: 20.sp),
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }
}

/// ─── Error & Loading helpers ───
class DashboardErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const DashboardErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 60.sp, color: const Color(0xFFEF4444)),
          SizedBox(height: 16.h),
          Text('حدث خطأ في تحميل البيانات',
              style: TextStyle(
                  fontSize: 18.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 8.h),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp, color: const Color(0xFFAAAAAA))),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
