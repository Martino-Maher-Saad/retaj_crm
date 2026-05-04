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
import 'employee_dashboard_view.dart';

class ManagerDashboardView extends StatelessWidget {
  final ProfileModel user;
  const ManagerDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgMain,
          body: SafeArea(
            child: switch (state) {
              DashboardLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.brandPrimary)),
              DashboardError(:final message) => DashboardErrorWidget(
                  message: message,
                  onRetry: () => context.read<DashboardCubit>().loadManagerDashboard(days: 30)),
              ManagerDashboardLoaded() => _buildContent(context, state),
              _ => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ManagerDashboardLoaded state) {
    // لو المدير اختار موظف — نعرض تقرير الموظف
    if (state.isViewingEmployee) {
      return EmployeeDashboardView(
        user: user,
        isViewedByManager: true,
        managerViewEmployeeName: state.selectedEmployeeName,
      );
    }
    // نظرة الشركة الافتراضية
    return _buildCompanyView(context, state.data, state.selectedDays);
  }

  Widget _buildCompanyView(BuildContext context, ManagerDashboardModel data, int selectedDays) {
    final comp = data.periodComparison;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 48.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ───
          Text('لوحة قيادة الشركة 📊',
              textAlign: TextAlign.right, style: AppTextStyles.h1),
          SizedBox(height: 6.h),
          Text('نظرة شاملة على أداء الشركة وفريق المبيعات',
              textAlign: TextAlign.right, style: AppTextStyles.subtitle),
          SizedBox(height: 24.h),

          // ─── Time Filter ───
          DashboardTimeFilter(
            selectedDays: selectedDays,
            onChanged: (days) => context.read<DashboardCubit>().changeManagerPeriod(days: days),
          ),
          SizedBox(height: 24.h),

          // ─── 4 Summary Cards مع مقارنة ───
          Row(children: [
            Expanded(child: DashboardStatCard(
              title: 'إجمالي العملاء',
              value: '${data.totalLeads}',
              icon: Icons.people_outline_rounded,
              color: AppColors.brandPrimary,
              subtitle: comp != null ? '${comp.leadsGrowthPct >= 0 ? '+' : ''}${comp.leadsGrowthPct.toStringAsFixed(0)}%' : null,
              isUp: comp != null ? comp.leadsGrowthPct >= 0 : null,
            )),
            SizedBox(width: 14.w),
            Expanded(child: DashboardStatCard(
              title: 'إجمالي التعاقدات',
              value: '${data.totalContracted}',
              icon: Icons.handshake_outlined,
              color: AppColors.success,
              subtitle: comp != null ? '${comp.contractedGrowthPct >= 0 ? '+' : ''}${comp.contractedGrowthPct.toStringAsFixed(0)}%' : null,
              isUp: comp != null ? comp.contractedGrowthPct >= 0 : null,
            )),
          ]),
          SizedBox(height: 14.h),
          Row(children: [
            Expanded(child: DashboardStatCard(
              title: 'نسبة التحويل الكلية',
              value: '${data.conversionRate.toStringAsFixed(1)}%',
              icon: Icons.percent_rounded,
              color: const Color(0xFF8B5CF6),
            )),
            SizedBox(width: 14.w),
            Expanded(child: DashboardStatCard(
              title: 'عقارات مضافة',
              value: '${data.totalProperties}',
              icon: Icons.home_work_outlined,
              color: AppColors.warning,
            )),
          ]),
          SizedBox(height: 24.h),

          // ─── Line Chart نمو الشركة ───
          if (data.performanceOverTime.isNotEmpty) ...[
            _buildSection(
              title: 'منحنى نمو الشركة — عملاء وتعاقدات',
              subtitle: 'المحور الأفقي: الفترة الزمنية | الخط الأزرق: عملاء جدد | الخط الأخضر: تعاقدات',
              icon: Icons.show_chart_rounded,
              child: _buildLineChart(data.performanceOverTime),
            ),
            SizedBox(height: 20.h),
          ],

          // ─── Funnel الشركة ───
          if (data.leadsByStatus.isNotEmpty) ...[
            _buildSection(
              title: 'قمع مبيعات الشركة — توزيع حالات العملاء',
              subtitle: 'يُظهر كيف ينتقل عملاء الشركة من مرحلة لأخرى',
              icon: Icons.filter_alt_outlined,
              child: _buildFunnel(data.leadsByStatus, data.totalLeads),
            ),
            SizedBox(height: 20.h),
          ],

          // ─── Platform ROI ───
          if (data.platformsBreakdown.isNotEmpty) ...[
            _buildSection(
              title: 'ROI المنصات — العائد على كل قناة إعلانية',
              subtitle: 'نسبة التحويل = تعاقدات ÷ إجمالي عملاء المنصة × 100',
              icon: Icons.campaign_outlined,
              child: _buildPlatformROI(data.platformsBreakdown),
            ),
            SizedBox(height: 20.h),
          ],

          // ─── Avg Time Per Stage ───
          _buildSection(
            title: 'متوسط وقت التحويل بين المراحل — على مستوى الشركة',
            subtitle: 'متوسط عدد الأيام قبل انتقال العميل من كل مرحلة للتالية',
            icon: Icons.timer_outlined,
            child: data.avgTimePerStage.isNotEmpty
                ? _buildAvgTime(data.avgTimePerStage)
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Text(
                      'لا توجد بيانات كافية بعد — ستظهر مع أول تغيير في حالة العملاء',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
          ),
          SizedBox(height: 20.h),

          // ─── Leaderboard كل الموظفين ───
          if (data.employeesPerformance.isNotEmpty) ...[
            _buildSection(
              title: 'أداء فريق المبيعات',
              subtitle: 'اضغط على أي موظف لعرض تقريره الكامل',
              icon: Icons.leaderboard_rounded,
              child: _buildLeaderboard(context, data.employeesPerformance),
            ),
          ],
        ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
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
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled, fontSize: 13.sp)),
          SizedBox(height: 18.h),
          child,
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
              show: true, drawVerticalLine: false,
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
                spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.leads.toDouble())).toList(),
                isCurved: true, color: AppColors.brandPrimary, barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppColors.brandPrimary.withValues(alpha: 0.08)),
              ),
              LineChartBarData(
                spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.contracted.toDouble())).toList(),
                isCurved: true, color: AppColors.success, barWidth: 2.5, dashArray: [6, 4],
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

  Widget _legend(Color color, String label) => Row(children: [
    Container(width: 20.w, height: 3.h, color: color),
    SizedBox(width: 6.w),
    Text(label, style: AppTextStyles.bodySmall),
  ]);

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
                  value: pct, minHeight: 14.h,
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

  Widget _buildPlatformROI(List<PlatformStat> platforms) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(children: [
            Expanded(flex: 2, child: Text('وقت الإغلاق', textAlign: TextAlign.left,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 2, child: Text('التحويل', textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 2, child: Text('تعاقدات', textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 2, child: Text('عملاء', textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 3, child: Text('المنصة', textAlign: TextAlign.right,
                style: AppTextStyles.tableHeader)),
          ]),
        ),
        Divider(color: AppColors.borderSubtle),
        ...platforms.map((p) {
          final convColor = p.conversionPct >= 20
              ? AppColors.success
              : p.conversionPct >= 10
                  ? AppColors.warning
                  : AppColors.error;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(children: [
              // ✅ وقت الإغلاق
              Expanded(
                flex: 2,
                child: Text(
                  p.avgClosingDays == 0
                      ? '-'
                      : p.avgClosingDays < 1
                          ? '< يوم'
                          : '${p.avgClosingDays.toStringAsFixed(1)}ي',
                  textAlign: TextAlign.left,
                  style: AppTextStyles.tableCellSub.copyWith(
                      color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: convColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text('${p.conversionPct.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.tableCellMain.copyWith(color: convColor)),
                ),
              ),
              Expanded(flex: 2, child: Text('${p.contracted}', textAlign: TextAlign.center,
                  style: AppTextStyles.tableCellMain.copyWith(color: AppColors.success, fontWeight: FontWeight.w800))),
              Expanded(flex: 2, child: Text('${p.total}', textAlign: TextAlign.center,
                  style: AppTextStyles.tableCellMain)),
              Expanded(flex: 3, child: Text(p.platform, textAlign: TextAlign.right,
                  style: AppTextStyles.tableCellMain.copyWith(fontWeight: FontWeight.w800))),
            ]),
          );
        }),
      ],
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
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
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
                  Icon(Icons.timer_outlined, color: color, size: 22.sp),
                  SizedBox(width: 8.w),
                  Text(
                    s.avgDays < 1 ? 'أقل من يوم' : '${s.avgDays.toStringAsFixed(1)} يوم',
                    style: AppTextStyles.h3.copyWith(color: color),
                  ),
                ]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.status, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w800)),
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

  Widget _buildLeaderboard(BuildContext context, List<EmployeeStat> employees) {
    const medals = ['🥇', '🥈', '🥉'];
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(children: [
            Expanded(flex: 2, child: Text('وقت الإغلاق', textAlign: TextAlign.left,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 2, child: Text('التحويل', textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 2, child: Text('تعاقدات', textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 2, child: Text('عملاء', textAlign: TextAlign.center,
                style: AppTextStyles.tableHeader)),
            Expanded(flex: 3, child: Text('الموظف', textAlign: TextAlign.right,
                style: AppTextStyles.tableHeader)),
          ]),
        ),
        Divider(color: AppColors.borderSubtle),
        ...employees.asMap().entries.map((entry) {
          final i = entry.key;
          final emp = entry.value;
          final convColor = emp.conversionPct >= 20
              ? AppColors.success
              : emp.conversionPct >= 10
                  ? AppColors.warning
                  : AppColors.error;

          return Column(
            children: [
              InkWell(
                onTap: () => context.read<DashboardCubit>().viewEmployee(
                      employeeId:   emp.employeeId,
                      employeeName: emp.name,
                    ),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                  child: Row(children: [
                    // ✅ وقت الإغلاق
                    Expanded(
                      flex: 2,
                      child: Text(
                        emp.avgClosingDays == 0
                            ? '-'
                            : emp.avgClosingDays < 1
                                ? '< يوم'
                                : '${emp.avgClosingDays.toStringAsFixed(1)}ي',
                        textAlign: TextAlign.left,
                        style: AppTextStyles.tableCellSub.copyWith(
                            color: const Color(0xFF0EA5E9), fontWeight: FontWeight.w700),
                      ),
                    ),
                    // Conversion
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: convColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text('${emp.conversionPct.toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.tableCellMain.copyWith(color: convColor)),
                      ),
                    ),
                    // تعاقدات
                    Expanded(
                      flex: 2,
                      child: Text('${emp.contracted}', textAlign: TextAlign.center,
                          style: AppTextStyles.tableCellMain.copyWith(
                              color: AppColors.success, fontWeight: FontWeight.w800)),
                    ),
                    // عملاء
                    Expanded(
                      flex: 2,
                      child: Text('${emp.leads}', textAlign: TextAlign.center,
                          style: AppTextStyles.tableCellMain),
                    ),
                    // الاسم + ميدالية
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(emp.name,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.tableCellMain.copyWith(fontWeight: FontWeight.w800)),
                          ),
                          SizedBox(width: 8.w),
                          Text(i < 3 ? medals[i] : '  ',
                              style: TextStyle(fontSize: 20.sp)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
              if (entry.key < employees.length - 1)
                Divider(color: AppColors.borderSubtle.withValues(alpha: 0.5), height: 1),
            ],
          );
        }),
        SizedBox(height: 8.h),
        Text(
          'اضغط على أي موظف لعرض تقريره الكامل',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.brandPrimary),
        ),
      ],
    );
  }
}
