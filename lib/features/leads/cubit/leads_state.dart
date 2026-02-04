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
  final List<LeadModel> allLeads;      // المصدر الرئيسي
  final List<LeadModel> filteredLeads; // ما يراه المستخدم حالياً
  final String currentFilter;         // "الكل", "جديد", إلخ

  const LeadLoaded({
    required this.allLeads,
    required this.filteredLeads,
    this.currentFilter = 'الكل',
  });

  @override
  List<Object?> get props => [allLeads, filteredLeads, currentFilter];
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