import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/excel_export_service.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/utils/responsive_debouncer_wrapper.dart';
import '../../../core/widgets/retaj_page_header.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../../auth/cubit/auth_states.dart';
import '../../../../core/widgets/blink_container.dart';
import '../widgets/lead_card.dart';
import '../widgets/list/lead_delete_dialog.dart';
import '../widgets/list/lead_archive_dialog.dart';
import '../widgets/list/lead_empty_state.dart';
import '../widgets/list/lead_filter_dialog.dart';
import '../widgets/list/lead_search_bar.dart';
import '../widgets/list/leads_status_filter_bar.dart';
import 'lead_details_screen.dart';
import 'lead_form_screen.dart';
import 'bulk_add_leads_screen.dart';
import '../widgets/list/leads_table_view.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/repositories/lead_repository.dart';

/// شاشة إدارة العملاء (Leads)
class LeadsManagementScreen extends StatefulWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  State<LeadsManagementScreen> createState() => _LeadsManagementScreenState();
}

class _LeadsManagementScreenState extends State<LeadsManagementScreen>
    with AutomaticKeepAliveClientMixin {
  late LeadCubit _cubit;
  bool _isFiltering = false;
  bool _isAddingNewLead = false;
  
  bool _isExcelView = false;
  bool _isBulkSelectMode = false;
  final Set<String> _selectedLeadIds = {};

  final _dataManager = di.sl<StaticDataManager>();

  // شريط الفلاتر السريع - الأسماء للعرض فقط، التصفية بالـ ID
  List<String> get _filters =>
      ['الكل', ...(_dataManager.getOptions('lead_status'))];

  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<LeadCubit>()
      ..getAllLeads(role: widget.user.role, userId: widget.user.id);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.6) {
      _cubit.loadMoreLeads(
        role: widget.user.role,
        userId: widget.user.id,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openFilterDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: LeadFilterDialog(
          role: widget.user.role,
          currentUserId: widget.user.id,
        ),
      ),
    ).then((_) {
      // تحقق إذا الكيوبيت غيّر حالته بفلاتر جديدة
      setState(() => _isFiltering = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FB),
        body: Column(
          children: [
            // ─── Header bar ───
            BlocBuilder<LeadCubit, LeadState>(
              builder: (context, state) {
                final String currentFilter =
                    (state is LeadLoaded) ? state.currentFilter : 'الكل';
                final int total = (state is LeadLoaded) ? state.totalCount : 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header الموحّد ───
                    RetajPageHeader(
                      title: 'العملاء المحتملين',
                      subtitle: 'تتبع وإدارة وتحويل فرص الاستثمار العقاري',
                      addLabel: 'إضافة عميل',
                      onAdd: () {
                        setState(() {
                          _isAddingNewLead = true;
                          // سكرول لأعلى القائمة لرؤية الكارت الجديد
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      },
                      totalCount: total,
                      onFilter: () => _openFilterDialog(context),
                      filterLabel: 'فلاتر متقدمة',
                      filterBar: LeadsStatusFilterBar(
                        filters: _filters,
                        currentFilter: currentFilter,
                        onFilterSelected: (filter) {
                          setState(() => _isFiltering = false);
                          final statusId = filter == 'الكل'
                              ? null
                              : _dataManager.getIdByName('lead_status', filter);
                          _cubit.getAllLeads(
                            role: widget.user.role,
                            userId: widget.user.id,
                            isRefresh: true,
                            leadStatusId: statusId,
                          );
                        },
                      ),
                      extraAction: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BulkAddLeadsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.grid_on, color: Colors.green),
                              label: const Text('إضافة متعددة / إكسيل', style: TextStyle(color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                    ),

                    // شريط بحث ذكي
                    LeadSearchBar(
                      onSearch: (query, type) {
                        if (type == 'general') {
                          _cubit.smartSearch(query, role: widget.user.role, userId: widget.user.id);
                        } else {
                          _cubit.search(query, type: type, role: widget.user.role, userId: widget.user.id);
                        }
                      },
                      onClear: () => _cubit.clearSearch(),
                      isSearching: (state is LeadLoaded) ? state.isSearching : false,
                    ),

                    // شريط الأدوات (Toggle View & Bulk Select)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppConstants.p16, vertical: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Toggle View
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.grid_view_rounded, color: !_isExcelView ? AppColors.brandPrimary : Colors.grey),
                                  onPressed: () => setState(() => _isExcelView = false),
                                  tooltip: 'عرض الكروت',
                                ),
                                Container(width: 1.w, height: 24.h, color: Colors.grey.shade300),
                                IconButton(
                                  icon: Icon(Icons.table_chart_rounded, color: _isExcelView ? AppColors.brandPrimary : Colors.grey),
                                  onPressed: () => setState(() => _isExcelView = true),
                                  tooltip: 'عرض الجدول',
                                ),
                              ],
                            ),
                          ),
                          
                          // Export Button
                          if (widget.user.role == 'manager' || widget.user.role == 'admin' || widget.user.role == 'ceo')
                            IconButton(
                              icon: const Icon(Icons.file_download, color: AppColors.brandPrimary),
                              onPressed: _exportLeads,
                              tooltip: 'تصدير لإكسيل',
                            ),
                          
                          const Spacer(),
                          // Bulk Select & Reassign (Admins only)
                          if (widget.user.role == 'manager' || widget.user.role == 'admin' || widget.user.role == 'ceo')
                            Row(
                              children: [
                                if (_isBulkSelectMode && _selectedLeadIds.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: _showBulkReassignDialog,
                                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                                    label: Text('نقل للموظف (${_selectedLeadIds.length})', style: const TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                                  ),
                                SizedBox(width: 8.w),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isBulkSelectMode = !_isBulkSelectMode;
                                      if (!_isBulkSelectMode) _selectedLeadIds.clear();
                                    });
                                  },
                                  icon: Icon(_isBulkSelectMode ? Icons.close : Icons.checklist_rtl),
                                  label: Text(_isBulkSelectMode ? 'إلغاء التحديد' : 'تحديد متعدد'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // شريط "فلاتر نشطة"
                    if (_isFiltering)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.p16, vertical: 4.h),
                        color: Colors.orange.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('نتائج الفلاتر المتقدمة 🎯',
                                style: TextStyle(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp)),
                            TextButton(
                              onPressed: () {
                                setState(() => _isFiltering = false);
                                _cubit.getAllLeads(
                                  role: widget.user.role,
                                  userId: widget.user.id,
                                  isRefresh: true,
                                );
                              },
                              child: const Text('إلغاء الفلاتر',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),

            // شريط التحديثات الجديدة (Realtime)
            BlocBuilder<LeadCubit, LeadState>(
              builder: (context, state) {
                if (state is LeadLoaded && state.hasNewUpdates) {
                  return GestureDetector(
                    onTap: () {
                      if (state.pendingLeads.isNotEmpty) {
                        _cubit.applyPendingUpdates();
                      } else {
                        _cubit.getAllLeads(
                          role: widget.user.role,
                          userId: widget.user.id,
                          isRefresh: true,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, color: AppColors.brandPrimary, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'يوجد تحديثات جديدة للعملاء، انقر للتحديث',
                            style: TextStyle(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ─── قائمة العملاء ───
            Expanded(
              child: BlocConsumer<LeadCubit, LeadState>(
                listener: (context, state) {
                  if (state is LeadError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.brandAccent,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is LeadLoading) {
                    return Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return LeadCard(
                            lead: LeadModel(
                              id: 'dummy',
                              propertyCode: 'PROP-XXXX',
                              clientName: 'تحميل اسم العميل',
                              city: 'مدينة افتراضية',
                              leadStatus: 'جديد',
                              phones: const [LeadPhoneModel(phoneNumber: '010000000', isPrimary: true)],
                              createdBy: '',
                              assignedTo: '',
                            ),
                            role: widget.user.role,
                            onTap: () {},
                            onEdit: () {},
                            onDelete: () {},
                          );
                        },
                      ),
                    );
                  }

                  if (state is LeadLoaded) {
                    if (state.filteredLeads.isEmpty && !_isAddingNewLead) {
                      return const LeadEmptyState();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => _cubit.getAllLeads(
                              role: widget.user.role,
                              userId: widget.user.id,
                              isRefresh: true,
                            ),
                            child: _isExcelView
                                ? LeadsTableView(
                                    leads: state.filteredLeads,
                                    isBulkSelectMode: _isBulkSelectMode,
                                    selectedIds: _selectedLeadIds,
                                    scrollController: _scrollController,
                                    isLoadingMore: state.isLoadingMore,
                                    blinkItemId: state.blinkItemId,
                                    onSelect: (id, isSelected) {
                                      setState(() {
                                        if (isSelected == true) {
                                          _selectedLeadIds.add(id);
                                        } else {
                                          _selectedLeadIds.remove(id);
                                        }
                                      });
                                    },
                                  )
                                : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: 20.h, top: 10.h),
                        itemCount: state.filteredLeads.length +
                            (state.isLoadingMore ? 1 : 0) +
                            (_isAddingNewLead ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isAddingNewLead && index == 0) {
                            return LeadCard(
                              key: const ValueKey('new_lead_inline'),
                              lead: LeadModel(
                                id: '',
                                clientName: '',
                                phones: const [],
                                propertyCode: '',
                                leadStatus: 'جديد',
                                createdBy: widget.user.id,
                                assignedTo: widget.user.id,
                                isActive: true,
                              ),
                              role: widget.user.role,
                              initialEditMode: true,
                              isAddingMode: true,
                              onCancelAdd: () {
                                setState(() => _isAddingNewLead = false);
                              },
                              onTap: () {},
                              onEdit: () {},
                              onDelete: () {},
                            );
                          }

                          final actualIndex = _isAddingNewLead ? index - 1 : index;

                          if (actualIndex >= state.filteredLeads.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          final lead = state.filteredLeads[actualIndex];
                          final isBlinking = lead.id == state.blinkItemId;
                          
                          final card = BlinkContainer(
                            isBlinking: isBlinking,
                            child: LeadCard(
                              key: ValueKey(lead.id),
                              lead: lead,
                              role: widget.user.role,
                              onTap: () => _openDetails(context, lead),
                              onEdit: () => _openForm(context, lead: lead),
                              onDelete: (widget.user.role == 'manager' || widget.user.role == 'admin' || widget.user.role == 'ceo')
                                  ? () => LeadDeleteDialog.show(
                                        context,
                                        lead,
                                        () => _cubit.deleteLead(lead.id!, widget.user.role),
                                      )
                                  : null,
                              onArchive: widget.user.role != 'admin'
                                ? () => LeadArchiveDialog.show(
                                    context,
                                    lead,
                                    () => _cubit.archiveLead(lead.id!, true),
                                  )
                                : null,
                              onPinToggle: () => _cubit.toggleLeadPin(lead),
                            ),
                          );

                          if (_isBulkSelectMode) {
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _selectedLeadIds.contains(lead.id),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedLeadIds.add(lead.id!);
                                        } else {
                                          _selectedLeadIds.remove(lead.id);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.brandPrimary,
                                  ),
                                  Expanded(child: card),
                                ],
                              ),
                            );
                          }
                          return card;
                        },
                            ),
                          ),
                        ),
                      ],
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

  void _openForm(BuildContext context, {LeadModel? lead}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadFormScreen(lead: lead, user: widget.user),
        ),
      ),
    );
  }

  void _openDetails(BuildContext context, LeadModel lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: LeadDetailsScreen(
            leadId: lead.id!,
            currentUser: widget.user,
          ),
        ),
      ),
    );
  }

  void _showBulkReassignDialog() {
    final state = _cubit.state;
    if (state is! LeadLoaded || state.employees.isEmpty) return;

    String? selectedEmployeeId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('نقل العملاء المحددين'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('اختر الموظف لنقل ${_selectedLeadIds.length} عميل إليه:'),
                SizedBox(height: 16.h),
                RetajDropdown<String>(
                  label: "الموظف المسؤول",
                  value: selectedEmployeeId,
                  items: state.employees.map((e) => DropdownMenuItem<String>(
                    value: e.id,
                    child: Text(e.firstName != null ? "${e.firstName} ${e.lastName}" : e.email),
                  )).toList(),
                  onChanged: (val) => setStateDialog(() => selectedEmployeeId = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedEmployeeId == null ? null : () {
                  Navigator.pop(ctx);
                  _performBulkReassign(selectedEmployeeId!);
                },
                child: const Text('تأكيد النقل'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _exportLeads() async {
    final leads = await _cubit.fetchAllForExport(role: widget.user.role, userId: widget.user.id);
    if (leads.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }
    
    final allColumns = [
      '#', 'اسم العميل', 'أرقام الهاتف', 'المسؤول', 'تاريخ الإضافة',
      'كود العقار', 'طلب العميل', 'المنصة', 'الحالة الحالية',
      'سبب الاستبعاد', 'نوع الإعلان', 'نوع العقار', 'المدينة', 'الملاحظات'
    ];
    
    final dataRows = leads.asMap().entries.map((entry) {
      final i = entry.key;
      final l = entry.value;
      final phonesStr = l.phones.map((p) => p.phoneNumber).join('\n');
      final notesStr = l.notes.isEmpty ? '—' : l.notes.map((n) => '• ${n.noteText}').join('\n');
      
      return [
        i + 1,
        l.clientName,
        phonesStr,
        l.assignedToName ?? '—',
        l.createdAt != null ? DateFormat("dd/MM/yyyy HH:mm").format(l.createdAt!) : '—',
        l.propertyCode ?? '—',
        l.descLeadNeed ?? '—',
        l.platform ?? '—',
        l.leadStatus ?? '—',
        l.exclusionReasonName ?? '—',
        l.listingType ?? '—',
        l.propertyType ?? '—',
        l.city ?? '—',
        notesStr
      ];
    }).toList();

    if (mounted) {
      await ExcelExportService.showExportDialog(
        context: context,
        title: 'العملاء',
        allColumns: allColumns,
        dataRows: dataRows,
      );
    }
  }

  Future<void> _performBulkReassign(String employeeId) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    try {
      final repository = di.sl<LeadRepository>();
      for (final id in _selectedLeadIds) {
        final currentLead = _cubit.state is LeadLoaded ? (_cubit.state as LeadLoaded).filteredLeads.firstWhere((l) => l.id == id, orElse: () => LeadModel(id: '', clientName: '', createdBy: '', assignedTo: '')) : null;
        if (currentLead != null && currentLead.id!.isNotEmpty) {
          await repository.updateLeadStatusAndEmployee(id, '460be748-7685-49ef-abcf-c4dd49511ab7', employeeId);
        }
      }
      
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النقل بنجاح')));
        setState(() {
          _isBulkSelectMode = false;
          _selectedLeadIds.clear();
        });
        _cubit.getAllLeads(role: widget.user.role, userId: widget.user.id, isRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل النقل: $e')));
      }
    }
  }
}

