/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/services/lead_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_card_widget.dart';
import 'lead_form_screen.dart';
import 'lead_details_screen.dart';



class LeadsManagementScreen extends StatefulWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  State<LeadsManagementScreen> createState() => _LeadsManagementScreenState();
}

class _LeadsManagementScreenState extends State<LeadsManagementScreen> with AutomaticKeepAliveClientMixin {
  late LeadCubit _cubit;
  final List<String> _filters = ['الكل', 'جديد', 'تم التواصل', 'تفاوض', 'تم التعاقد', 'مستبعد'];

  @override
  bool get wantKeepAlive => true; // للحفاظ على حالة الصفحة عند التنقل في الـ Tabs

  @override
  void initState() {
    super.initState();
    // إنشاء الـ Cubit يدوياً كما تفعل في شاشة العقارات
    _cubit = LeadCubit(
      LeadRepository(LeadService()),
    )..getAllLeads();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // توفير الـ Cubit للـ Context الحالي وللشاشات التي سيتم فتحها
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: Text('إدارة العملاء', style: AppTextStyles.h2),
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.brandPrimary,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _openForm(context),
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: BlocConsumer<LeadCubit, LeadState>(
                listener: (context, state) {
                  if (state is LeadError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppColors.brandAccent),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is LeadLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
                  } else if (state is LeadLoaded) {
                    if (state.filteredLeads.isEmpty) return _buildEmptyState();

                    return RefreshIndicator(
                      onRefresh: () => _cubit.getAllLeads(),
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 80.h),
                        itemCount: state.filteredLeads.length,
                        itemBuilder: (context, index) {
                          final lead = state.filteredLeads[index];
                          return LeadCardWidget(
                            lead: lead,
                            onTap: () => _openDetails(context, lead),
                            onEdit: () => _openForm(context, lead: lead),
                            onDelete: () => _confirmDelete(context, lead),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- [ UI Components ] ---

  Widget _buildFilterBar() {
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        String currentFilter = (state is LeadLoaded) ? state.currentFilter : 'الكل';
        return Container(
          height: 60.h,
          padding: EdgeInsets.symmetric(vertical: AppConstants.p8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppConstants.p16),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              bool isSelected = currentFilter == _filters[index];
              return Padding(
                padding: EdgeInsets.only(left: AppConstants.p8),
                child: ChoiceChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (_) => _cubit.filterLeads(_filters[index]),
                  selectedColor: AppColors.brandPrimary,
                  labelStyle: AppTextStyles.chipLabel.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.bgSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.r8)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("لا يوجد عملاء حالياً", style: AppTextStyles.tableCellSub),
    );
  }

  // --- [ Navigation Logic ] ---

  void _openForm(BuildContext context, {LeadModel? lead}) async {
    // نستخدم BlocProvider.value لتمرير الـ Cubit الحالي للشاشة القادمة
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadFormScreen(lead: lead, currentUserId: widget.user.id!),
        ),
      ),
    );

    if (result != null && result is LeadModel) {
      if (lead == null) {
        _cubit.addLead(result);
      } else {
        // إذا كنت ستعدل كل البيانات، تأكد أن الـ Cubit يدعم ذلك
        _cubit.updateLeadStatus(lead.id!, result.leadStatus!);
      }
    }
  }

  void _openDetails(BuildContext context, LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadDetailsScreen(lead: lead),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تأكيد الحذف", style: AppTextStyles.h3),
        content: Text("هل تريد حذف ${lead.clientName}؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              _cubit.deleteLead(lead.id!);
              Navigator.pop(ctx);
            },
            child: const Text("حذف", style: TextStyle(color: AppColors.brandAccent)),
          ),
        ],
      ),
    );
  }
}*/




import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retaj_crm/data/services/lead_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_card_widget.dart';
import 'lead_form_screen.dart';
import 'lead_details_screen.dart';


class LeadsManagementScreen extends StatefulWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  State<LeadsManagementScreen> createState() => _LeadsManagementScreenState();
}

class _LeadsManagementScreenState extends State<LeadsManagementScreen> with AutomaticKeepAliveClientMixin {
  late LeadCubit _cubit;
  final List<String> _filters = ['الكل', 'جديد', 'تم التواصل', 'تفاوض', 'تم التعاقد', 'مستبعد'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = LeadCubit(
      LeadRepository(LeadService()),
    )..getAllLeads();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: Text('إدارة العملاء', style: AppTextStyles.h2),
          backgroundColor: AppColors.bgSurface,
          elevation: 0,
          centerTitle: true,
        ),
        // تم إزالة الـ FloatingActionButton من هنا
        body: Column(
          children: [
            _buildTopActionsBar(context), // البار العلوي الجديد (إضافة + فلاتر)
            Expanded(
              child: BlocConsumer<LeadCubit, LeadState>(
                listener: (context, state) {
                  if (state is LeadError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: AppColors.brandAccent),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is LeadLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary));
                  } else if (state is LeadLoaded) {
                    if (state.filteredLeads.isEmpty) return _buildEmptyState();

                    return RefreshIndicator(
                      onRefresh: () => _cubit.getAllLeads(),
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                        itemCount: state.filteredLeads.length,
                        itemBuilder: (context, index) {
                          final lead = state.filteredLeads[index];
                          return LeadCardWidget(
                            lead: lead,
                            onTap: () => _openDetails(context, lead),
                            onEdit: () => _openForm(context, lead: lead),
                            onDelete: () => _confirmDelete(context, lead),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- [ UI Components ] ---

  Widget _buildTopActionsBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      color: AppColors.bgSurface,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.p16),
            child: Row(
              children: [
                // زر الإضافة الجديد
                ElevatedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: Text("إضافة عميل", style: AppTextStyles.buttonLarge.copyWith(fontSize: 14.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.r8)),
                  ),
                ),
                SizedBox(width: 12.w),
                // الفلاتر بجانب الزر
                Expanded(child: _buildFilterBar()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return BlocBuilder<LeadCubit, LeadState>(
      builder: (context, state) {
        String currentFilter = (state is LeadLoaded) ? state.currentFilter : 'الكل';
        return SizedBox(
          height: 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              bool isSelected = currentFilter == _filters[index];
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: ChoiceChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (_) => _cubit.filterLeads(_filters[index]),
                  selectedColor: AppColors.brandPrimary,
                  // تحسين الخط والحجم ليكون واضحاً وغير مقصوص
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  labelStyle: AppTextStyles.chipLabel.copyWith(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.bgMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.r8),
                    side: BorderSide(color: isSelected ? AppColors.brandPrimary : AppColors.borderSubtle),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text("لا يوجد عملاء حالياً", style: AppTextStyles.tableCellSub),
    );
  }

  // --- [ Navigation Logic ] ---

  void _openForm(BuildContext context, {LeadModel? lead}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadFormScreen(lead: lead, currentUserId: widget.user.id!),
        ),
      ),
    );
    // ملاحظة: لم نعد نحتاج للـ Result هنا لأن الفورم أصبح يكلم الكيوبيت مباشرة
  }

  void _openDetails(BuildContext context, LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadDetailsScreen(lead: lead),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, LeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("تأكيد الحذف", style: AppTextStyles.h3),
        content: Text("هل تريد حذف ${lead.clientName}؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              _cubit.deleteLead(lead.id!);
              Navigator.pop(ctx);
            },
            child: const Text("حذف", style: TextStyle(color: AppColors.brandAccent)),
          ),
        ],
      ),
    );
  }
}