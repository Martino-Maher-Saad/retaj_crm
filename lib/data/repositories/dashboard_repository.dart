import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';
import '../../core/di/injection_container.dart' as di;
import '../../core/utils/static_data_manager.dart';
import 'lead_repository.dart';
import '../models/lead_model.dart';

/// Repository الداشبورد — الوسيط بين الـ Cubit والـ Service
class DashboardRepository {
  final DashboardService _service;

  DashboardRepository(this._service);

  Future<DashboardStatsModel> getFilteredDashboardStats({
    required String role,
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) async {
    // 1. جلب العملاء للفترة المحددة
    final leads = await di.sl<LeadRepository>().fetchDashboardExcelLeads(
      role: role,
      userId: userId,
      filterByEmployeeId: employeeId,
      fromDate: startDate,
      toDate: endDate,
    );

    final int leadsCount = leads.length;

    // حساب توزيع حالات العملاء
    final Map<String, int> statusGroups = {};
    for (final l in leads) {
      final status = l.leadStatus ?? 'غير محدد';
      statusGroups[status] = (statusGroups[status] ?? 0) + 1;
    }
    final leadsByStatus = statusGroups.entries.map((e) => StatusStat(status: e.key, count: e.value)).toList();

    // حساب نوع الإعلان للعملاء
    final Map<String, int> listingTypeGroups = {};
    for (final l in leads) {
      final type = l.listingType ?? 'غير محدد';
      listingTypeGroups[type] = (listingTypeGroups[type] ?? 0) + 1;
    }
    final leadsByListingType = listingTypeGroups.entries.map((e) => ListingTypeStat(listingType: e.key, count: e.value)).toList();

    // حساب نوع العقار للعملاء
    final Map<String, int> propertyTypeGroups = {};
    for (final l in leads) {
      final type = l.propertyType ?? 'غير محدد';
      propertyTypeGroups[type] = (propertyTypeGroups[type] ?? 0) + 1;
    }
    final leadsByPropertyType = propertyTypeGroups.entries.map((e) => PropertyTypeStat(propertyType: e.key, count: e.value)).toList();

    // حساب المدن النشطة للعملاء
    final Map<String, int> cityGroups = {};
    for (final l in leads) {
      final city = l.city ?? 'غير محدد';
      cityGroups[city] = (cityGroups[city] ?? 0) + 1;
    }
    final leadsByCity = cityGroups.entries.map((e) => CityStat(city: e.key, count: e.value)).toList();

    // حساب مصادر المنصات والـ ROI
    final Map<String, List<LeadModel>> platformLeads = {};
    for (final l in leads) {
      final platform = l.platform ?? 'غير محدد';
      platformLeads.putIfAbsent(platform, () => []).add(l);
    }
    final List<PlatformStat> platformsBreakdown = [];
    for (final entry in platformLeads.entries) {
      final total = entry.value.length;
      final contracted = entry.value.where((l) => l.leadStatus == 'تم التعاقد').length;

      double sumClosing = 0;
      int countClosed = 0;
      for (final l in entry.value) {
        if (l.leadStatus == 'تم التعاقد') {
          final logs = l.logs.where((log) => log.action == 'status_changed' && log.newStatusName == 'تم التعاقد');
          final DateTime closedDate = logs.isNotEmpty ? logs.first.createdAt : (l.updatedAt ?? l.createdAt ?? DateTime.now());
          final DateTime createdDate = l.createdAt ?? DateTime.now();
          final diff = closedDate.difference(createdDate).inDays;
          sumClosing += diff >= 0 ? diff : 0;
          countClosed++;
        }
      }

      platformsBreakdown.add(PlatformStat(
        platform: entry.key,
        total: total,
        contracted: contracted,
        conversionPct: total == 0 ? 0.0 : (contracted / total) * 100,
        avgClosingDays: countClosed == 0 ? 0.0 : sumClosing / countClosed,
      ));
    }

    // حساب أداء الموظفين (لوحة المتصدرين)
    final Map<String, List<LeadModel>> employeeLeads = {};
    for (final l in leads) {
      if (l.assignedTo != null) {
        employeeLeads.putIfAbsent(l.assignedTo!, () => []).add(l);
      }
    }
    final List<EmployeeStat> employeesPerformance = [];
    for (final entry in employeeLeads.entries) {
      final total = entry.value.length;
      final contracted = entry.value.where((l) => l.leadStatus == 'تم التعاقد').length;

      double sumClosing = 0;
      int countClosed = 0;
      for (final l in entry.value) {
        if (l.leadStatus == 'تم التعاقد') {
          final logs = l.logs.where((log) => log.action == 'status_changed' && log.newStatusName == 'تم التعاقد');
          final DateTime closedDate = logs.isNotEmpty ? logs.first.createdAt : (l.updatedAt ?? l.createdAt ?? DateTime.now());
          final DateTime createdDate = l.createdAt ?? DateTime.now();
          final diff = closedDate.difference(createdDate).inDays;
          sumClosing += diff >= 0 ? diff : 0;
          countClosed++;
        }
      }

      final empProfile = di.sl<StaticDataManager>().employees.where((e) => e.id == entry.key).firstOrNull;
      final empName = empProfile != null ? empProfile.fullName : 'غير محدد';

      employeesPerformance.add(EmployeeStat(
        employeeId: entry.key,
        name: empName,
        leads: total,
        contracted: contracted,
        conversionPct: total == 0 ? 0.0 : (contracted / total) * 100,
        avgClosingDays: countClosed == 0 ? 0.0 : sumClosing / countClosed,
      ));
    }

    // عدد التعاقدات والعملاء الراكدين
    final int contractedCount = leads.where((l) => l.leadStatus == 'تم التعاقد').length;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final int staleLeadsCount = leads.where((l) {
      if (l.leadStatus == 'تم التعاقد' || l.leadStatus == 'مستبعد') return false;
      if (l.updatedAt == null) return false;
      return l.updatedAt!.isBefore(sevenDaysAgo);
    }).length;

    // متوسط وقت الإغلاق الكلي
    double totalClosingSum = 0;
    int totalClosedCount = 0;
    for (final l in leads) {
      if (l.leadStatus == 'تم التعاقد') {
        final logs = l.logs.where((log) => log.action == 'status_changed' && log.newStatusName == 'تم التعاقد');
        final DateTime closedDate = logs.isNotEmpty ? logs.first.createdAt : (l.updatedAt ?? l.createdAt ?? DateTime.now());
        final DateTime createdDate = l.createdAt ?? DateTime.now();
        final diff = closedDate.difference(createdDate).inDays;
        totalClosingSum += diff >= 0 ? diff : 0;
        totalClosedCount++;
      }
    }
    final double avgClosingDays = totalClosedCount == 0 ? 0.0 : totalClosingSum / totalClosedCount;

    // حساب عدد العقارات المضافة في الفترة المحددة
    int propertiesCount = 0;
    try {
      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();
      final propsResponse = await _service.getRawPropertiesForPeriod(startDate: startIso, endDate: endIso);
      propertiesCount = propsResponse.length;
    } catch (_) {}

    return DashboardStatsModel(
      leadsCount: leadsCount,
      propertiesCount: propertiesCount,
      contractedCount: contractedCount,
      staleLeadsCount: staleLeadsCount,
      avgClosingDays: avgClosingDays,
      leadsByStatus: leadsByStatus,
      leadsByListingType: leadsByListingType,
      leadsByPropertyType: leadsByPropertyType,
      leadsByCity: leadsByCity,
      platformsBreakdown: platformsBreakdown,
      employeesPerformance: employeesPerformance,
    );
  }

  /// جلب وتجميع إحصائيات العقارات المضافة خلال الفترة
  Future<PropertyAddedStats> getPropertyAddedStats({
    required DateTime startDate,
    required DateTime endDate,
    String? employeeId,
  }) async {
    try {
      final response = await _service.getRawPropertiesForPeriod(
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
      );

      final dataManager = di.sl<StaticDataManager>();

      final Map<String, int> propertiesByEmployee = {};
      final Map<String, int> propertiesByPropertyType = {};
      final Map<String, int> propertiesByListingType = {};
      final Map<String, int> propertiesByCity = {};

      for (final row in response) {
        final createdBy = row['created_by'] as String?;
        final propertyTypeId = row['property_type_id'] as String?;
        final listingTypeId = row['listing_type_id'] as String?;
        final cityId = row['city_id'] as int?;

        // 1. الموظف
        if (createdBy != null) {
          if (employeeId != null && createdBy != employeeId) {
            continue;
          }
          final emp = dataManager.employees.where((e) => e.id == createdBy).firstOrNull;
          final name = emp != null ? emp.fullName : 'غير محدد';
          propertiesByEmployee[name] = (propertiesByEmployee[name] ?? 0) + 1;
        } else if (employeeId != null) {
          // إذا كان مفلتر على موظف، نتخطى السجلات التي ليس لها منشئ
          continue;
        }

        // 2. نوع العقار
        if (propertyTypeId != null) {
          final type = dataManager.getOptionModels('property_type').where((o) => o.id == propertyTypeId).firstOrNull;
          final name = type != null ? type.nameAr : 'غير محدد';
          propertiesByPropertyType[name] = (propertiesByPropertyType[name] ?? 0) + 1;
        }

        // 3. نوع الإعلان
        if (listingTypeId != null) {
          final type = dataManager.getOptionModels('listing_type').where((o) => o.id == listingTypeId).firstOrNull;
          final name = type != null ? type.nameAr : 'غير محدد';
          propertiesByListingType[name] = (propertiesByListingType[name] ?? 0) + 1;
        }

        // 4. المدينة
        if (cityId != null) {
          final city = dataManager.allCities.where((c) => c.id == cityId).firstOrNull;
          final name = city != null ? city.name : 'غير محدد';
          propertiesByCity[name] = (propertiesByCity[name] ?? 0) + 1;
        }
      }

      return PropertyAddedStats(
        propertiesByEmployee: propertiesByEmployee,
        propertiesByPropertyType: propertiesByPropertyType,
        propertiesByListingType: propertiesByListingType,
        propertiesByCity: propertiesByCity,
      );
    } catch (e) {
      debugPrint("Error calculating properties added stats: $e");
      return PropertyAddedStats.empty();
    }
  }
}
