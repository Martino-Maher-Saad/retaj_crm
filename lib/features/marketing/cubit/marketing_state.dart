import 'package:equatable/equatable.dart';
import '../../../data/models/property_model.dart';

abstract class MarketingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MarketingInitial extends MarketingState {}

class MarketingLoading extends MarketingState {}

class MarketingSuccess extends MarketingState {
  final List<PropertyModel> originalProperties; // الكاش بتاع العقارات بدون فلتر
  final List<PropertyModel> properties;         // العقارات المعروضة حالياً
  final List<PropertyModel> pendingProperties;  // العقارات الجديدة (لم يتم عرضها بعد)
  final bool hasMore;
  final int page;
  final bool isFiltered;
  final bool hasNewUpdates;
  final int totalCount;
  final int originalTotalCount;

  // فلاتر نشطة
  final String? filterEmployeeId;
  final String? filterApprovalStatusId;
  final DateTime? filterFromDate;
  final DateTime? filterToDate;
  final String? filterPropertyCode;

  MarketingSuccess({
    this.originalProperties = const [],
    this.properties = const [],
    this.pendingProperties = const [],
    this.hasMore = true,
    this.page = 0,
    this.isFiltered = false,
    this.hasNewUpdates = false,
    this.totalCount = 0,
    this.originalTotalCount = 0,
    this.filterEmployeeId,
    this.filterApprovalStatusId,
    this.filterFromDate,
    this.filterToDate,
    this.filterPropertyCode,
  });

  bool get hasActiveFilter =>
      filterEmployeeId != null ||
      filterApprovalStatusId != null ||
      filterFromDate != null ||
      filterToDate != null ||
      (filterPropertyCode != null && filterPropertyCode!.isNotEmpty);

  MarketingSuccess copyWith({
    List<PropertyModel>? originalProperties,
    List<PropertyModel>? properties,
    List<PropertyModel>? pendingProperties,
    bool? hasMore,
    int? page,
    bool? isFiltered,
    bool? hasNewUpdates,
    int? totalCount,
    int? originalTotalCount,
    String? filterEmployeeId,
    String? filterApprovalStatusId,
    DateTime? filterFromDate,
    DateTime? filterToDate,
    String? filterPropertyCode,
    bool clearEmployeeFilter = false,
    bool clearStatusFilter = false,
    bool clearFromDate = false,
    bool clearToDate = false,
    bool clearCodeFilter = false,
  }) {
    return MarketingSuccess(
      originalProperties: originalProperties ?? this.originalProperties,
      properties: properties ?? this.properties,
      pendingProperties: pendingProperties ?? this.pendingProperties,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      isFiltered: isFiltered ?? this.isFiltered,
      hasNewUpdates: hasNewUpdates ?? this.hasNewUpdates,
      totalCount: totalCount ?? this.totalCount,
      originalTotalCount: originalTotalCount ?? this.originalTotalCount,
      filterEmployeeId: clearEmployeeFilter ? null : (filterEmployeeId ?? this.filterEmployeeId),
      filterApprovalStatusId: clearStatusFilter ? null : (filterApprovalStatusId ?? this.filterApprovalStatusId),
      filterFromDate: clearFromDate ? null : (filterFromDate ?? this.filterFromDate),
      filterToDate: clearToDate ? null : (filterToDate ?? this.filterToDate),
      filterPropertyCode: clearCodeFilter ? null : (filterPropertyCode ?? this.filterPropertyCode),
    );
  }

  @override
  List<Object?> get props => [
        originalProperties,
        properties,
        pendingProperties,
        hasMore,
        page,
        isFiltered,
        hasNewUpdates,
        totalCount,
        originalTotalCount,
        filterEmployeeId,
        filterApprovalStatusId,
        filterFromDate,
        filterToDate,
        filterPropertyCode,
      ];
}

class MarketingError extends MarketingState {
  final String message;
  MarketingError(this.message);

  @override
  List<Object?> get props => [message];
}
