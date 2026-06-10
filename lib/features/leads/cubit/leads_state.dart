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
  final List<ProfileModel> employees;
  const LeadLoaded({
    required this.allLeads,
    required this.filteredLeads,
    this.currentFilter = 'الكل',
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.isSearching = false,
    this.employees = const [],
  });

  LeadLoaded copyWith({
    List<LeadModel>? allLeads,
    List<LeadModel>? filteredLeads,
    String? currentFilter,
    int? totalCount,
    bool? isLoadingMore,
    bool? isSearching,
    List<ProfileModel>? employees,
  }) {
    return LeadLoaded(
      allLeads: allLeads ?? this.allLeads,
      filteredLeads: filteredLeads ?? this.filteredLeads,
      currentFilter: currentFilter ?? this.currentFilter,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearching: isSearching ?? this.isSearching,
      employees: employees ?? this.employees,
    );
  }

  @override
  List<Object?> get props => [allLeads, filteredLeads, currentFilter, totalCount, isLoadingMore, isSearching, employees];
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