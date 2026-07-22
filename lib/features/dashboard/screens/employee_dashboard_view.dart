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
import '../widgets/dashboard_leads_table.dart';
import 'dashboard_screen.dart';

class EmployeeDashboardView extends StatelessWidget {
  final ProfileModel user;
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
        if (state is EmployeeDashboardLoaded && !isViewedByManager) {
          return _buildScaffold(
            context,
            state.data,
            state.propertyAddedStats,
            state.startDate,
            state.endDate,
            false,
          );
        }
        if (state is ManagerDashboardLoaded && isViewedByManager) {
          final data = state.data;
          return _buildScaffold(
            context,
            data,
            state.propertyAddedStats,
            state.startDate,
            state.endDate,
            true,
          );
        }
        if (state is DashboardLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary),
          );
        }
        if (state is DashboardError) {
          return DashboardErrorWidget(
            message: state.message,
            onRetry: () {
              if (isViewedByManager) {
                context.read<DashboardCubit>().loadManagerDashboard(
                  employeeId: user.id,
                );
              } else {
                context.read<DashboardCubit>().loadEmployeeDashboard(
                  userId: user.id,
                );
              }
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    DashboardStatsModel data,
    PropertyAddedStats propStats,
    DateTime startDate,
    DateTime endDate,
    bool managedView,
  ) {
    final String currentUserId = managedView
        ? ((context.read<DashboardCubit>().state as ManagerDashboardLoaded)
                .selectedEmployeeId ??
            user.id)
        : user.id;

    return Scaffold(
      backgroundColor: AppColors.bgMain,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 48.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Filter (Topmost)
              DashboardDateFilter(
                startDate: startDate,
                endDate: endDate,
                onChanged: (start, end) {
                  if (managedView) {
                    context.read<DashboardCubit>().changeManagerFilters(
                      startDate: start,
                      endDate: end,
                      employeeId: currentUserId,
                      employeeName: managerViewEmployeeName,
                    );
                  } else {
                    context.read<DashboardCubit>().changeEmployeePeriod(
                      userId: user.id,
                      startDate: start,
                      endDate: end,
                    );
                  }
                },
              ),
              SizedBox(height: 24.h),

              // Header
              if (managedView) ...[
                GestureDetector(
                  onTap: () {
                    context.read<DashboardCubit>().loadManagerDashboard();
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20.sp,
                        color: AppColors.brandPrimary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'رجوع لنظرة الشركة',
                        style: AppTextStyles.bodyMain.copyWith(
                          color: AppColors.brandPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              Text(
                managedView
                    ? 'تقرير أداء: ${managerViewEmployeeName ?? ''}'
                    : 'أهلاً، ${user.firstName ?? 'موظف'} 👋',
                textAlign: TextAlign.right,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28.sp,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'ملخص الأداء والإنتاجية للفترة المحددة',
                textAlign: TextAlign.right,
                style: AppTextStyles.subtitle.copyWith(
                  fontSize: 16.sp,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(height: 24.h),

              // Stale leads count warning alert
              if (data.staleLeadsCount > 0) ...[
                _buildStaleAlert(data.staleLeadsCount),
                SizedBox(height: 20.h),
              ],

              // Summary Cards Grid
              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title: 'عدد عملائي الكلي',
                      value: '${data.leadsCount}',
                      icon: Icons.people_outline_rounded,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: DashboardStatCard(
                      title: 'عدد العقارات الكلية بالشركة',
                      value: '${data.propertiesCount}',
                      icon: Icons.home_work_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: DashboardStatCard(
                      title: 'نسبة التحويل للعملاء',
                      value: '${data.conversionRate.toStringAsFixed(1)}%',
                      icon: Icons.percent_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: DashboardStatCard(
                      title: 'التعاقدات المكتملة',
                      value: '${data.contractedCount}',
                      icon: Icons.handshake_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              DashboardStatCard(
                title: 'متوسط وقت الإغلاق (أيام)',
                value: data.avgClosingDays == 0
                    ? 'لا توجد تعاقدات بعد'
                    : data.avgClosingDays < 1
                    ? 'أقل من يوم'
                    : '${data.avgClosingDays.toStringAsFixed(1)} يوم',
                icon: Icons.timer_rounded,
                color: const Color(0xFF0EA5E9),
                subtitle: 'الوقت المستغرق من إنشاء العميل وحتى التعاقد الفعلي',
              ),
              SizedBox(height: 32.h),

              // ─── [ GROUP 1: LEAD REPORTS & CHARTS ] ───
              _buildSectionHeader(
                'تحليلات وتقارير العملاء والمنصات 👥',
                Icons.people_rounded,
              ),
              SizedBox(height: 16.h),
              if (data.leadsCount > 0) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSection(
                        title: 'توزيع الحالات (قمع المبيعات)',
                        icon: Icons.pie_chart_rounded,
                        child: _buildStatusPieChart(data.leadsByStatus),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: _buildSection(
                        title: 'نسبة البيع إلى الإيجار للعملاء',
                        icon: Icons.donut_large_rounded,
                        child: _buildListingTypeDonutChart(
                          data.leadsByListingType,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSection(
                        title: 'مصادر العملاء (المنصات)',
                        icon: Icons.campaign_rounded,
                        child: _buildPlatformsDonutChart(
                          data.platformsBreakdown,
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: _buildSection(
                        title: 'أعلى 5 مدن نشطة للعملاء',
                        icon: Icons.bar_chart_rounded,
                        child: _buildCitiesBarChart(data.leadsByCity),
                      ),
                    ),
                  ],
                ),
              ] else
                _buildNoDataWidget(
                  'لا توجد بيانات عملاء كافية لعرض الرسومات البيانية',
                ),
              SizedBox(height: 32.h),

              // ─── [ GROUP 2: PROPERTY REPORTS & CHARTS ] ───
              _buildSectionHeader(
                'تحليلات وتقارير العقارات المضافة 🏢',
                Icons.analytics_rounded,
              ),
              SizedBox(height: 16.h),
              if (propStats.propertiesByPropertyType.isNotEmpty ||
                  propStats.propertiesByListingType.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildSection(
                        title: 'توزيع العقارات حسب نوع العقار',
                        icon: Icons.home_work_outlined,
                        child: _buildPropertyTypePieChart(
                          propStats.propertiesByPropertyType,
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),
                    Expanded(
                      child: _buildSection(
                        title: 'توزيع العقارات حسب نوع الإعلان',
                        icon: Icons.sell_outlined,
                        child: _buildPropertyListingTypeDonutChart(
                          propStats.propertiesByListingType,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildSection(
                  title: 'توزيع العقارات المضافة حسب المدينة الجغرافية',
                  icon: Icons.location_city_outlined,
                  child: _buildPropertyCitiesBarChart(
                    propStats.propertiesByCity,
                  ),
                ),
              ] else
                _buildNoDataWidget(
                  'لا توجد عقارات مضافة في هذه الفترة لعرض الإحصائيات المتجهة',
                ),

              // ─── [ GROUP 3: VISUAL SEPARATOR ] ───
              SizedBox(height: 40.h),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                      thickness: 2.w,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'جدول تفاصيل ومتابعة العملاء والتقارير',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: AppColors.brandPrimary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.table_chart_rounded,
                            color: AppColors.brandPrimary,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                      thickness: 2.w,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Interactive Excel-like Leads Table
              DashboardLeadsTable(
                role: managedView ? 'manager' : 'sales',
                userId: currentUserId,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppTextStyles.h2.copyWith(
            fontSize: 22.sp,
            color: AppColors.brandPrimaryDark,
            fontFamily: 'Cairo',
          ),
        ),
        SizedBox(width: 10.w),
        Icon(icon, color: AppColors.brandPrimaryDark, size: 26.sp),
      ],
    );
  }

  Widget _buildNoDataWidget(String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  fontSize: 18.sp,
                  fontFamily: 'Cairo',
                ),
              ),
              SizedBox(width: 10.w),
              Icon(icon, color: AppColors.brandPrimary, size: 22.sp),
            ],
          ),
          SizedBox(height: 20.h),
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
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '$count عملاء لم يُحدَّثوا منذ أكثر من 7 أيام — يحتاجون متابعة عاجلة',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMain.copyWith(
                color: const Color(0xFF92400E),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CHARTS BUILDERS ---

  Widget _buildStatusPieChart(List<StatusStat> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
    ];
    return Column(
      children: [
        SizedBox(
          height: 300.h,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              sections: stats.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final color = colors[idx % colors.length];
                return PieChartSectionData(
                  color: color,
                  value: s.count.toDouble(),
                  title: '${s.count}',
                  radius: 110.r,
                  titleStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 6.h,
          alignment: WrapAlignment.center,
          children: stats.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final color = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12.w, height: 12.h, color: color),
                SizedBox(width: 6.w),
                Text(
                  s.status,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListingTypeDonutChart(List<ListingTypeStat> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final List<Color> colors = [AppColors.brandPrimary, AppColors.success];
    return Column(
      children: [
        SizedBox(
          height: 300.h,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 65.r,
              sections: stats.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final color = colors[idx % colors.length];
                return PieChartSectionData(
                  color: color,
                  value: s.count.toDouble(),
                  title: '${s.count}',
                  radius: 50.r,
                  titleStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          alignment: WrapAlignment.center,
          children: stats.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final color = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12.w, height: 12.h, color: color),
                SizedBox(width: 6.w),
                Text(
                  s.listingType,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlatformsDonutChart(List<PlatformStat> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.grey,
    ];
    return Column(
      children: [
        SizedBox(
          height: 300.h,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 65.r,
              sections: stats.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final color = colors[idx % colors.length];
                return PieChartSectionData(
                  color: color,
                  value: s.total.toDouble(),
                  title: '${s.total}',
                  radius: 50.r,
                  titleStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 4.h,
          alignment: WrapAlignment.center,
          children: stats.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final color = colors[idx % colors.length];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12.w, height: 12.h, color: color),
                SizedBox(width: 4.w),
                Text(
                  s.platform,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCitiesBarChart(List<CityStat> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final topStats = stats.take(5).toList();
    final double maxVal = topStats
        .map((s) => s.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return SizedBox(
      height: 320.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal == 0 ? 5 : maxVal + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topStats.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        topStats[index].city,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 32.h,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: topStats.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: s.count.toDouble(),
                  color: AppColors.brandPrimary,
                  width: 22.w,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- PROPERTY ANALYTICS CHARTS ---

  Widget _buildPropertyTypePieChart(Map<String, int> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];
    final total = stats.values.fold(0, (sum, item) => sum + item);
    return Column(
      children: [
        SizedBox(
          height: 300.h,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              sections: stats.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final color = colors[idx % colors.length];
                return PieChartSectionData(
                  color: color,
                  value: e.value.toDouble(),
                  title: '${e.value}',
                  radius: 110.r,
                  titleStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 6.h,
          alignment: WrapAlignment.center,
          children: stats.entries.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color = colors[idx % colors.length];
            final pct = total == 0 ? 0.0 : (e.value / total) * 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12.w, height: 12.h, color: color),
                SizedBox(width: 6.w),
                Text(
                  '${e.key} (${pct.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyListingTypeDonutChart(Map<String, int> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final List<Color> colors = [AppColors.brandPrimary, AppColors.success];
    final total = stats.values.fold(0, (sum, item) => sum + item);
    return Column(
      children: [
        SizedBox(
          height: 300.h,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 65.r,
              sections: stats.entries.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final color = colors[idx % colors.length];
                return PieChartSectionData(
                  color: color,
                  value: e.value.toDouble(),
                  title: '${e.value}',
                  radius: 50.r,
                  titleStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          alignment: WrapAlignment.center,
          children: stats.entries.toList().asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            final color = colors[idx % colors.length];
            final pct = total == 0 ? 0.0 : (e.value / total) * 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12.w, height: 12.h, color: color),
                SizedBox(width: 6.w),
                Text(
                  '${e.key} (${pct.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyCitiesBarChart(Map<String, int> stats) {
    if (stats.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    final entries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topStats = entries.take(5).toList();
    final double maxVal = topStats
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return SizedBox(
      height: 320.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal == 0 ? 5 : maxVal + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < topStats.length) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        topStats[index].key,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 32.h,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: topStats.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  color: AppColors.warning,
                  width: 22.w,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
