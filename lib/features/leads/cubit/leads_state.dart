import 'package:equatable/equatable.dart';
import '../../../data/models/lead_model.dart';


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

  const LeadLoaded({
    required this.allLeads,
    required this.filteredLeads,
    this.currentFilter = 'الكل',
    this.totalCount = 0,
    this.isLoadingMore = false,
  });

  LeadLoaded copyWith({
    List<LeadModel>? allLeads,
    List<LeadModel>? filteredLeads,
    String? currentFilter,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return LeadLoaded(
      allLeads: allLeads ?? this.allLeads,
      filteredLeads: filteredLeads ?? this.filteredLeads,
      currentFilter: currentFilter ?? this.currentFilter,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [allLeads, filteredLeads, currentFilter, totalCount, isLoadingMore];
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