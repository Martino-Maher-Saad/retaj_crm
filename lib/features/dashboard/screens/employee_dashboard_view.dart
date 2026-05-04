import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/dashboard_model.dart';
import '../../../data/models/profile_model.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import 'dashboard_screen.dart';

class EmployeeDashboardView extends StatelessWidget {
  final ProfileModel user;
  // لما المدير يشوف بيانات موظف معين
  final bool isViewedByManager;
  final String? managerViewEmployeeName;

  const EmployeeDashboardView({
    super.key,
    required this.user,
    this.isViewedByManager = false,
    this.managerViewEmployeeName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        // الموظف العادي
        if (state is EmployeeDashboardLoaded && !isViewedByManager) {
          return _buildScaffold(context, state.data, state.selectedDays, false);
        }
        // المدير يشوف بيانات موظف
        if (state is ManagerDashboardLoaded && isViewedByManager) {
          if (state.selectedEmployeeData != null) {
            return _buildScaffold(context, state.selectedEmployeeData!, state.selectedDays, true);
          }
          return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        }
        if (state is DashboardLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
        }
        if (state is DashboardError) {
          return DashboardErrorWidget(
            message: state.message,
            onRetry: () => isViewedByManager
                ? null
                : context.read<DashboardCubit>().loadEmployeeDashboard(userId: user.id),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScaffold(BuildContext context, EmployeeDashboardModel data, int selectedDays, bool managedView) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 48.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Header ───
              if (managedView) ...[
                GestureDetector(
                  onTap: () => context.read<DashboardCubit>().backToCompanyView(),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 18.sp, color: AppColors.brandPrimary),
                      SizedBox(width: 8.w),
                      Text('رجوع لنظرة الشركة',
                          style: AppTextStyles.bodyMain.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Text(
                managedView
                    ? 'تقرير: ${managerViewEmployeeName ?? ''}'
                    : 'أهلاً، ${user.firstName ?? 'موظف'} 👋',
                textAlign: TextAlign.right,
                style: AppTextStyles.h1,
              ),
              SizedBox(height: 6.h),
              Text(
                'ملخص الأداء للفترة المحددة',
                textAlign: TextAlign.right,
                style: AppTextStyles.subtitle,
              ),
              SizedBox(height: 24.h),

              // ─── Time Filter ───
              DashboardTimeFilter(
                selectedDays: selectedDays,
                onChanged: (days) => managedView
                    ? null
                    : context.read<DashboardCubit>().changeEmployeePeriod(userId: user.id, days: days),
              ),
              SizedBox(height: 24.h),

              // ─── Stale Alert ───
              if (data.staleLeadsCount > 0) ...[
                _buildStaleAlert(data.staleLeadsCount),
                SizedBox(height: 20.h),
              ],

              // ─── 4 Summary Cards ───
              Row(
                children: [
                  Expanded(child: DashboardStatCard(
                    title: 'عدد عملائي',
                    value: '${data.leadsCount}',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.brandPrimary,
                  )),
                  SizedBox(width: 14.w),
                  Expanded(child: DashboardStatCard(
                    title: 'تعاقداتي',
                    value: '${data.contractedCount}',
                    icon: Icons.handshake_outlined,
                    color: AppColors.success,
                  )),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(child: DashboardStatCard(
                    title: 'نسبة التحويل',
                    value: '${data.conversionRate.toStringAsFixed(1)}%',
                    icon: Icons.percent_rounded,
                    color: const Color(0xFF8B5CF6),
                  )),
                  SizedBox(width: 14.w),
                  Expanded(child: DashboardStatCard(
                    title: 'عقاراتي المضافة',
                    value: '${data.propertiesCount}',
                    icon: Icons.home_work_outlined,
                    color: AppColors.warning,
                  )),
                ],
              ),
              SizedBox(height: 24.h),

              // ─── Line Chart ───
              if (data.performanceOverTime.isNotEmpty) ...[
                _buildSection(
                  title: 'منحنى أداء العملاء والتعاقدات',
                  subtitle: 'المحور الأفقي: الفترة الزمنية | الخط الأزرق: عملاء جدد | الخط الأخضر: تعاقدات',
                  icon: Icons.show_chart_rounded,
                  child: _buildLineChart(data.performanceOverTime),
                ),
                SizedBox(height: 20.h),
              ],

              // ─── Funnel ───
              if (data.leadsByStatus.isNotEmpty) ...[
                _buildSection(
                  title: 'قمع المبيعات — توزيع حالات العملاء',
                  subtitle: 'يُظهر كيف ينتقل العملاء من مرحلة لأخرى',
                  icon: Icons.filter_alt_outlined,
                  child: _buildFunnel(data.leadsByStatus, data.leadsCount),
                ),
                SizedBox(height: 20.h),
              ],

              // ─── Platforms ───
              if (data.platformsBreakdown.isNotEmpty) ...[
                _buildSection(
                  title: 'أداء المنصات — عملاء وتعاقدات لكل منصة',
                  subtitle: 'النسبة المئوية = تعاقدات ÷ إجمالي عملاء المنصة',
                  icon: Icons.campaign_outlined,
                  child: _buildPlatforms(data.platformsBreakdown),
                ),
                SizedBox(height: 20.h),
              ],

              // ─── Avg Time Per Stage ───
              if (data.avgTimePerStage.isNotEmpty) ...[
                _buildSection(
                  title: 'متوسط وقت التحويل بين المراحل',
                  subtitle: 'متوسط عدد الأيام قبل انتقال العميل من كل مرحلة للتالية (من كل التاريخ)',
                  icon: Icons.timer_outlined,
                  child: _buildAvgTime(data.avgTimePerStage),
                ),
              ] else ...[
                _buildSection(
                  title: 'متوسط وقت التحويل بين المراحل',
                  subtitle: 'سيظهر هذا القسم تدريجياً مع تراكم بيانات التغييرات',
                  icon: Icons.timer_outlined,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      'لا توجد بيانات كافية بعد — ستظهر مع أول تغيير في حالة العملاء',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section Wrapper ───
  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title, style: AppTextStyles.h3),
              SizedBox(width: 10.w),
              Icon(icon, color: AppColors.brandPrimary, size: 24.sp),
            ],
          ),
          SizedBox(height: 6.h),
          Text(subtitle,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDisabled,
                fontSize: 13.sp,
              )),
          SizedBox(height: 18.h),
          child,
        ],
      ),
    );
  }

  Widget _buildStaleAlert(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '$count عملاء لم يُحدَّثوا منذ أكثر من 7 أيام — يحتاجون متابعة عاجلة',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMain.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<PerformancePoint> points) {
    final maxY = (points.map((p) => p.leads).reduce((a, b) => a > b ? a : b).toDouble() + 2);
    return Column(
      children: [
        SizedBox(
          height: 200.h,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderSubtle, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32.w,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textDisabled)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28.h,
                  interval: (points.length / 4).ceilToDouble().clamp(1, 999),
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                    final p = points[idx].period;
                    return Text(p.length > 5 ? p.substring(5) : p,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.textDisabled));
                  },
                ),
              ),
            ),
            minY: 0, maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: points.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.leads.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppColors.brandPrimary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                    show: true, color: AppColors.brandPrimary.withValues(alpha: 0.08)),
              ),
              LineChartBarData(
                spots: points.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.contracted.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppColors.success,
                barWidth: 2.5,
                dashArray: [6, 4],
                dotData: const FlDotData(show: false),
              ),
            ],
          )),
        ),
        SizedBox(height: 14.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(AppColors.success, 'تعاقدات (منقّط)'),
            SizedBox(width: 20.w),
            _legend(AppColors.brandPrimary, 'عملاء جدد'),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 20.w, height: 3.h, color: color),
        SizedBox(width: 6.w),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildFunnel(List<StatusStat> statuses, int total) {
    const statusColors = {
      'جديد': Color(0xFF8B5CF6),
      'تم التواصل': Color(0xFF3B82F6),
      'تفاوض': AppColors.warning,
      'تم التعاقد': AppColors.success,
      'مستبعد': AppColors.error,
    };
    return Column(
      children: statuses.map((s) {
        final pct = total == 0 ? 0.0 : s.count / total;
        final color = statusColors[s.status] ?? AppColors.brandPrimary;
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text('${s.count} عميل',
                        style: AppTextStyles.bodyMain.copyWith(color: color, fontWeight: FontWeight.w800)),
                    SizedBox(width: 8.w),
                    Text('(${(pct * 100).toStringAsFixed(0)}%)',
                        style: AppTextStyles.bodySmall.copyWith(color: color)),
                  ]),
                  Text(s.status, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 14.h,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlatforms(List<PlatformStat> platforms) {
    final maxVal = platforms.map((p) => p.total).reduce((a, b) => a > b ? a : b).toDouble();
    return Column(
      children: platforms.map((p) {
        final pct = maxVal == 0 ? 0.0 : p.total / maxVal;
        final convPct = p.total == 0 ? 0.0 : (p.contracted / p.total * 100);
        return Padding(
          padding: EdgeInsets.only(bottom: 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text('${convPct.toStringAsFixed(0)}% تحويل',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(width: 10.w),
                    Text('${p.contracted} تعاقد',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success, fontWeight: FontWeight.w700)),
                  ]),
                  Row(children: [
                    Text('${p.total} عميل',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    SizedBox(width: 10.w),
                    Text(p.platform,
                        style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12.h,
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAvgTime(List<AvgTimeStat> stats) {
    const statusColors = {
      'جديد': Color(0xFF8B5CF6),
      'تم التواصل': Color(0xFF3B82F6),
      'تفاوض': AppColors.warning,
      'تم التعاقد': AppColors.success,
    };
    return Column(
      children: stats.map((s) {
        final color = statusColors[s.status] ?? AppColors.brandPrimary;
        final days = s.avgDays;
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.timer_outlined, color: color, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    days < 1
                        ? 'أقل من يوم'
                        : '${days.toStringAsFixed(1)} يوم',
                    style: AppTextStyles.h3.copyWith(color: color),
                  ),
                ]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.status,
                        style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w800)),
                    Text('متوسط وقت البقاء في هذه المرحلة',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
