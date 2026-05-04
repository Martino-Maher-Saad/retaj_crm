// ──────────────────────────────────────────────
// Models للداشبورد — تُملأ من RPC Responses
// ──────────────────────────────────────────────

/// بيانات المنصة (عدد العملاء والتعاقدات)
class PlatformStat {
  final String platform;
  final int total;
  final int contracted;
  final double conversionPct;
  final double avgClosingDays; // متوسط وقت الإغلاق لهذه المنصة

  const PlatformStat({
    required this.platform,
    required this.total,
    required this.contracted,
    required this.conversionPct,
    this.avgClosingDays = 0,
  });

  factory PlatformStat.fromJson(Map<String, dynamic> json) => PlatformStat(
        platform:       json['platform'] as String? ?? 'غير محدد',
        total:          (json['total'] as num).toInt(),
        contracted:     (json['contracted'] as num).toInt(),
        conversionPct:  (json['conversion_pct'] as num?)?.toDouble() ?? (
            (json['total'] as num).toInt() == 0
                ? 0.0
                : (json['contracted'] as num).toDouble() /
                    (json['total'] as num).toDouble() *
                    100),
        avgClosingDays: (json['avg_closing_days'] as num?)?.toDouble() ?? 0,
      );
}

/// حالة العميل وعددها
class StatusStat {
  final String status;
  final int count;

  const StatusStat({required this.status, required this.count});

  factory StatusStat.fromJson(Map<String, dynamic> json) => StatusStat(
        status: json['status'] as String? ?? 'غير محدد',
        count:  (json['count'] as num).toInt(),
      );
}

/// نقطة بيانات في الرسم البياني الزمني
class PerformancePoint {
  final String period; // يوم أو أسبوع أو شهر
  final int leads;
  final int contracted;

  const PerformancePoint({
    required this.period,
    required this.leads,
    required this.contracted,
  });

  factory PerformancePoint.fromJson(Map<String, dynamic> json) =>
      PerformancePoint(
        period:     json['period'] as String,
        leads:      (json['leads'] as num).toInt(),
        contracted: (json['contracted'] as num).toInt(),
      );
}

/// أداء موظف (للمدير)
class EmployeeStat {
  final String employeeId;
  final String name;
  final int leads;
  final int contracted;
  final double conversionPct;
  final double avgClosingDays; // متوسط وقت الإغلاق لهذا الموظف

  const EmployeeStat({
    required this.employeeId,
    required this.name,
    required this.leads,
    required this.contracted,
    required this.conversionPct,
    this.avgClosingDays = 0,
  });

  factory EmployeeStat.fromJson(Map<String, dynamic> json) => EmployeeStat(
        employeeId:    json['employee_id'] as String,
        name:          json['name'] as String? ?? 'موظف',
        leads:         (json['leads'] as num).toInt(),
        contracted:    (json['contracted'] as num).toInt(),
        conversionPct: (json['conversion_pct'] as num?)?.toDouble() ?? 0,
        avgClosingDays:(json['avg_closing_days'] as num?)?.toDouble() ?? 0,
      );
}

/// توزيع جغرافي (للمدير)
class GovernorateStat {
  final String governorate;
  final int count;

  const GovernorateStat({required this.governorate, required this.count});

  factory GovernorateStat.fromJson(Map<String, dynamic> json) =>
      GovernorateStat(
        governorate: json['governorate'] as String? ?? 'غير محدد',
        count:       (json['count'] as num).toInt(),
      );
}

/// متوسط وقت التحويل بين المراحل
class AvgTimeStat {
  final String status;   // الحالة التي غادرها العميل
  final double avgDays;  // متوسط عدد الأيام فيها قبل الانتقال

  const AvgTimeStat({required this.status, required this.avgDays});

  factory AvgTimeStat.fromJson(Map<String, dynamic> json) => AvgTimeStat(
        status:  json['status'] as String? ?? 'غير محدد',
        avgDays: (json['avg_days'] as num?)?.toDouble() ?? 0,
      );
}

/// ملخص الفترة السابقة مقابل الحالية (للمدير)
class PeriodComparison {
  final int currentLeads;
  final int previousLeads;
  final int currentContracted;
  final int previousContracted;

  const PeriodComparison({
    required this.currentLeads,
    required this.previousLeads,
    required this.currentContracted,
    required this.previousContracted,
  });

  double get leadsGrowthPct {
    if (previousLeads == 0) return currentLeads > 0 ? 100 : 0;
    return ((currentLeads - previousLeads) / previousLeads) * 100;
  }

  double get contractedGrowthPct {
    if (previousContracted == 0) return currentContracted > 0 ? 100 : 0;
    return ((currentContracted - previousContracted) / previousContracted) * 100;
  }

  factory PeriodComparison.fromJson(Map<String, dynamic> json) =>
      PeriodComparison(
        currentLeads:       (json['current_leads'] as num).toInt(),
        previousLeads:      (json['previous_leads'] as num).toInt(),
        currentContracted:  (json['current_contracted'] as num).toInt(),
        previousContracted: (json['previous_contracted'] as num).toInt(),
      );
}

/// آخر عميل (للموظف)
class RecentLead {
  final String id;
  final String clientName;
  final String? leadStatus;
  final String? platform;
  final DateTime? createdAt;

  const RecentLead({
    required this.id,
    required this.clientName,
    this.leadStatus,
    this.platform,
    this.createdAt,
  });

  factory RecentLead.fromJson(Map<String, dynamic> json) => RecentLead(
        id:         json['id'] as String,
        clientName: json['client_name'] as String? ?? '',
        leadStatus: json['lead_status'] as String?,
        platform:   json['platform'] as String?,
        createdAt:  json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String).toLocal()
            : null,
      );
}

// ──────────────────────────────────────────────
// الـ Model الرئيسي لداشبورد الموظف
// ──────────────────────────────────────────────
class EmployeeDashboardModel {
  final int propertiesCount;
  final int leadsCount;
  final int contractedCount;
  final int staleLeadsCount;
  final double avgClosingDays; // متوسط وقت الإغلاق لهذا الموظف
  final List<StatusStat> leadsByStatus;
  final List<PlatformStat> platformsBreakdown;
  final List<PerformancePoint> performanceOverTime;
  final List<RecentLead> recentLeads;
  final List<AvgTimeStat> avgTimePerStage;

  double get conversionRate =>
      leadsCount == 0 ? 0 : (contractedCount / leadsCount) * 100;

  const EmployeeDashboardModel({
    required this.propertiesCount,
    required this.leadsCount,
    required this.contractedCount,
    required this.staleLeadsCount,
    this.avgClosingDays = 0,
    required this.leadsByStatus,
    required this.platformsBreakdown,
    required this.performanceOverTime,
    required this.recentLeads,
    required this.avgTimePerStage,
  });

  factory EmployeeDashboardModel.fromJson(Map<String, dynamic> json) =>
      EmployeeDashboardModel(
        propertiesCount:     (json['properties_count'] as num?)?.toInt() ?? 0,
        leadsCount:          (json['leads_count'] as num?)?.toInt() ?? 0,
        contractedCount:     (json['contracted_count'] as num?)?.toInt() ?? 0,
        staleLeadsCount:     (json['stale_leads_count'] as num?)?.toInt() ?? 0,
        avgClosingDays:      (json['avg_closing_days'] as num?)?.toDouble() ?? 0,
        leadsByStatus: (json['leads_by_status'] as List?)
                ?.map((e) => StatusStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        platformsBreakdown: (json['platforms_breakdown'] as List?)
                ?.map((e) => PlatformStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        performanceOverTime: (json['performance_over_time'] as List?)
                ?.map((e) => PerformancePoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recentLeads: (json['recent_leads'] as List?)
                ?.map((e) => RecentLead.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        avgTimePerStage: (json['avg_time_per_stage'] as List?)
                ?.map((e) => AvgTimeStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ──────────────────────────────────────────────
// الـ Model الرئيسي لداشبورد المدير
// ──────────────────────────────────────────────
class ManagerDashboardModel {
  final int totalProperties;
  final int totalLeads;
  final int totalContracted;
  final int totalStaleLeads;
  final List<StatusStat> leadsByStatus;
  final List<EmployeeStat> employeesPerformance;
  final List<PlatformStat> platformsBreakdown;
  final List<GovernorateStat> topGovernorates;
  final List<PerformancePoint> performanceOverTime;
  final PeriodComparison? periodComparison;
  final List<AvgTimeStat> avgTimePerStage;

  double get conversionRate =>
      totalLeads == 0 ? 0 : (totalContracted / totalLeads) * 100;

  const ManagerDashboardModel({
    required this.totalProperties,
    required this.totalLeads,
    required this.totalContracted,
    required this.totalStaleLeads,
    required this.leadsByStatus,
    required this.employeesPerformance,
    required this.platformsBreakdown,
    required this.topGovernorates,
    required this.performanceOverTime,
    this.periodComparison,
    required this.avgTimePerStage,
  });

  factory ManagerDashboardModel.fromJson(Map<String, dynamic> json) =>
      ManagerDashboardModel(
        totalProperties:  (json['total_properties'] as num?)?.toInt() ?? 0,
        totalLeads:       (json['total_leads'] as num?)?.toInt() ?? 0,
        totalContracted:  (json['total_contracted'] as num?)?.toInt() ?? 0,
        totalStaleLeads:  (json['total_stale_leads'] as num?)?.toInt() ?? 0,
        leadsByStatus: (json['leads_by_status'] as List?)
                ?.map((e) => StatusStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        employeesPerformance: (json['employees_performance'] as List?)
                ?.map((e) => EmployeeStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        platformsBreakdown: (json['platforms_breakdown'] as List?)
                ?.map((e) => PlatformStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        topGovernorates: (json['top_governorates'] as List?)
                ?.map((e) => GovernorateStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        performanceOverTime: (json['performance_over_time'] as List?)
                ?.map((e) => PerformancePoint.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        periodComparison: json['period_comparison'] != null
            ? PeriodComparison.fromJson(
                json['period_comparison'] as Map<String, dynamic>)
            : null,
        avgTimePerStage: (json['avg_time_per_stage'] as List?)
                ?.map((e) => AvgTimeStat.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
