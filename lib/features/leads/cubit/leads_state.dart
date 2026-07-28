import 'package:equatable/equatable.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';


abstract class LeadState extends Equatable {
  const LeadState();
  @override
  List<Object?> get props => [];
}

// الحالة الابتدائية
class LeadInitial extends LeadState {}

// حالة التحميل (Loading)
class LeadLoading extends LeadState {}

// حالة النجاح في جلب البيانات وعرضها
class LeadLoaded extends LeadState {
  final List<LeadModel> allLeads;
  final List<LeadModel> filteredLeads;
  final String currentFilter;
  final int totalCount;
  final bool isLoadingMore;
  final bool isSearching;
  final bool hasNewUpdates;
  final String? blinkItemId;
  final List<ProfileModel> employees;
  final List<LeadModel> pendingLeads;

  const LeadLoaded({
    required this.allLeads,
    required this.filteredLeads,
    this.currentFilter = 'الكل',
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.hasNewUpdates = false,
    this.blinkItemId,
    this.employees = const [],
    this.pendingLeads = const [],
  });

  LeadLoaded copyWith({
    List<LeadModel>? allLeads,
    List<LeadModel>? filteredLeads,
    String? currentFilter,
    int? totalCount,
    bool? isLoadingMore,
    bool? isSearching,
    bool? hasNewUpdates,
    String? blinkItemId,
    List<ProfileModel>? employees,
    List<LeadModel>? pendingLeads,
  }) {
    return LeadLoaded(
      allLeads: allLeads ?? this.allLeads,
      filteredLeads: filteredLeads ?? this.filteredLeads,
      currentFilter: currentFilter ?? this.currentFilter,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      hasNewUpdates: hasNewUpdates ?? this.hasNewUpdates,
      blinkItemId: blinkItemId, // Can be null to clear blink
      employees: employees ?? this.employees,
      pendingLeads: pendingLeads ?? this.pendingLeads,
    );
  }

  @override
  List<Object?> get props => [allLeads, filteredLeads, currentFilter, totalCount, isLoadingMore, isSearching, hasNewUpdates, blinkItemId, employees, pendingLeads];
}

// حالة الخطأ
class LeadError extends LeadState {
  final String message;
  const LeadError(this.message);

  @override
  List<Object?> get props => [message];
}

// حالة خاصة بالعمليات السريعة (مثل نجاح الحذف أو الإضافة) لتنبيه الـ UI
class LeadActionSuccess extends LeadState {
  final String message;
  const LeadActionSuccess(this.message);
}