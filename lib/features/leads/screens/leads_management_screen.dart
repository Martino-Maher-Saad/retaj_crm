import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/widgets/blink_container.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/excel_export_service.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/widgets/retaj_page_header.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/repositories/lead_repository.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/lead_card.dart';
import '../widgets/list/lead_archive_dialog.dart';
import '../widgets/list/lead_delete_dialog.dart';
import '../widgets/list/lead_empty_state.dart';
import '../widgets/list/lead_filter_dialog.dart';
import '../widgets/list/lead_search_bar.dart';
import '../widgets/list/leads_table_view.dart';
import 'bulk_add_leads_screen.dart';
import 'lead_details_screen.dart';
import 'lead_form_screen.dart';

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

  final ScrollController _scrollController = ScrollController();

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool _isAllMonths = false;
  bool _onlyMyLeads = false; // الوضع الافتراضي للمدير: عرض كل عملاء الشركة

  bool get _isManagerRole {
    final r = widget.user.role.toLowerCase();
    return r == 'manager' || r == 'admin' || r == 'ceo';
  }

  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  String _formatMonthYear(DateTime dt) {
    return '${_monthsAr[dt.month - 1]} ${dt.year}';
  }

  Future<void> _refreshLeadsWithCurrentFilters({bool isRefresh = true}) async {
    DateTime? fromDate;
    DateTime? toDate;
    if (!_isAllMonths) {
      fromDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month,
        1,
        0,
        0,
        0,
      );
      toDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
        23,
        59,
        59,
      );
    }

    final filterEmpId = (_isManagerRole && _onlyMyLeads)
        ? widget.user.id
        : null;

    await _cubit.getAllLeads(
      role: widget.user.role,
      userId: widget.user.id,
      filterByEmployeeId: filterEmpId,
      fromDate: fromDate,
      toDate: toDate,
      isRefresh: isRefresh,
    );
  }

  void _changeMonth(DateTime newMonth) {
    setState(() {
      _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
      _isAllMonths = false;
    });
    _refreshLeadsWithCurrentFilters();
  }

  void _setAllMonths() {
    setState(() {
      _isAllMonths = true;
    });
    _refreshLeadsWithCurrentFilters();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<LeadCubit>();
    _refreshLeadsWithCurrentFilters(isRefresh: false);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.6) {
      _cubit.loadMoreLeads(role: widget.user.role, userId: widget.user.id);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      body: Column(
        children: [
          // ─── Header bar ───
          BlocBuilder<LeadCubit, LeadState>(
            builder: (context, state) {
              final String currentFilter = (state is LeadLoaded)
                  ? state.currentFilter
                  : 'الكل';
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
                    filterBar: _isManagerRole
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 48.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.grid_view_rounded,
                                          color: !_isExcelView
                                              ? AppColors.brandPrimary
                                              : Colors.grey,
                                        ),
                                        onPressed: () => setState(
                                          () => _isExcelView = false,
                                        ),
                                        tooltip: 'عرض الكروت',
                                      ),
                                      Container(
                                        width: 1.w,
                                        height: 28.h,
                                        color: Colors.grey.shade300,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.table_chart_rounded,
                                          color: _isExcelView
                                              ? AppColors.brandPrimary
                                              : Colors.grey,
                                        ),
                                        onPressed: () =>
                                            setState(() => _isExcelView = true),
                                        tooltip: 'عرض الجدول',
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Container(
                                  height: 48.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.file_download,
                                      color: AppColors.brandPrimary,
                                    ),
                                    onPressed: _exportLeads,
                                    tooltip: 'تصدير لإكسيل',
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                if (_isBulkSelectMode) ...[
                                  SizedBox(
                                    height: 48.h,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        final loadedState = state is LeadLoaded
                                            ? state
                                            : null;
                                        if (loadedState == null ||
                                            loadedState.filteredLeads.isEmpty)
                                          return;
                                        final visibleIds = loadedState
                                            .filteredLeads
                                            .map((l) => l.id!)
                                            .where((id) => id.isNotEmpty)
                                            .toList();
                                        final allSelected =
                                            visibleIds.isNotEmpty &&
                                            visibleIds.every(
                                              (id) =>
                                                  _selectedLeadIds.contains(id),
                                            );
                                        setState(() {
                                          if (allSelected) {
                                            _selectedLeadIds.removeAll(
                                              visibleIds,
                                            );
                                          } else {
                                            _selectedLeadIds.addAll(visibleIds);
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        (state is LeadLoaded &&
                                                state
                                                    .filteredLeads
                                                    .isNotEmpty &&
                                                state.filteredLeads.every(
                                                  (l) => _selectedLeadIds
                                                      .contains(l.id),
                                                ))
                                            ? Icons.deselect_rounded
                                            : Icons.select_all_rounded,
                                        color: AppColors.brandPrimary,
                                      ),
                                      label: Text(
                                        (state is LeadLoaded &&
                                                state
                                                    .filteredLeads
                                                    .isNotEmpty &&
                                                state.filteredLeads.every(
                                                  (l) => _selectedLeadIds
                                                      .contains(l.id),
                                                ))
                                            ? 'إلغاء تحديد الكل'
                                            : 'تحديد الكل (${(state is LeadLoaded) ? state.filteredLeads.length : 0})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                if (_isBulkSelectMode &&
                                    _selectedLeadIds.isNotEmpty) ...[
                                  SizedBox(
                                    height: 48.h,
                                    child: ElevatedButton.icon(
                                      onPressed: _showBulkReassignDialog,
                                      icon: const Icon(
                                        Icons.swap_horiz,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'نقل (${_selectedLeadIds.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.brandPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  SizedBox(
                                    height: 48.h,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          _showBulkDeleteConfirmationDialog,
                                      icon: const Icon(
                                        Icons.delete_sweep_rounded,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'حذف (${_selectedLeadIds.length})',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                ],
                                SizedBox(
                                  height: 48.h,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _isBulkSelectMode = !_isBulkSelectMode;
                                        if (!_isBulkSelectMode)
                                          _selectedLeadIds.clear();
                                      });
                                    },
                                    icon: Icon(
                                      _isBulkSelectMode
                                          ? Icons.close
                                          : Icons.checklist_rtl,
                                    ),
                                    label: Text(
                                      _isBulkSelectMode
                                          ? 'إلغاء التحديد'
                                          : 'تحديد متعدد',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMonthSelector(),
                                SizedBox(width: 8.w),
                                Container(
                                  height: 24.h,
                                  width: 1.w,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(width: 8.w),
                                _buildQuickFilterBar(currentFilter),
                              ],
                            ),
                          ),
                    extraAction: _isManagerRole
                        ? OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BulkAddLeadsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.grid_on,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'إضافة متعددة / إكسيل',
                              style: TextStyle(color: Colors.green),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : null,
                  ),

                  // ─── شريط الفلاتر السريعة: يُعرض فقط للمدير (لأن الموظفين أصبح مدمجاً في الـ Header مكسباً للمساحة) ───
                  if (_isManagerRole)
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 4.h,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildManagerScopeToggle(),
                            SizedBox(width: 12.w),
                            Container(
                              height: 26.h,
                              width: 1.w,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(width: 12.w),
                            _buildMonthSelector(),
                            SizedBox(width: 12.w),
                            Container(
                              height: 26.h,
                              width: 1.w,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(width: 12.w),
                            _buildQuickFilterBar(currentFilter),
                          ],
                        ),
                      ),
                    ),

                  // شريط بحث ذكي
                  LeadSearchBar(
                    onSearch: (query, type) {
                      if (type == 'general') {
                        _cubit.smartSearch(
                          query,
                          role: widget.user.role,
                          userId: widget.user.id,
                        );
                      } else {
                        _cubit.search(
                          query,
                          type: type,
                          role: widget.user.role,
                          userId: widget.user.id,
                        );
                      }
                    },
                    onClear: () => _cubit.clearSearch(),
                    isSearching: (state is LeadLoaded)
                        ? state.isSearching
                        : false,
                  ),

                  // شريط "فلاتر نشطة"
                  if (_isFiltering)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.p16,
                        vertical: 4.h,
                      ),
                      color: Colors.orange.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نتائج الفلاتر المتقدمة 🎯',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _isFiltering = false);
                              _refreshLeadsWithCurrentFilters();
                            },
                            child: const Text(
                              'إلغاء الفلاتر',
                              style: TextStyle(color: Colors.red),
                            ),
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
                      _refreshLeadsWithCurrentFilters(isRefresh: true);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.brandPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: AppColors.brandPrimary,
                          size: 20.sp,
                        ),
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
                      cacheExtent: 3000,
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
                            phones: const [
                              LeadPhoneModel(
                                phoneNumber: '010000000',
                                isPrimary: true,
                              ),
                            ],
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
                          onRefresh: () =>
                              _refreshLeadsWithCurrentFilters(isRefresh: true),
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
                                  onSelectAll: () {
                                    final visibleIds = state.filteredLeads
                                        .map((l) => l.id!)
                                        .where((id) => id.isNotEmpty)
                                        .toList();
                                    final allSelected =
                                        visibleIds.isNotEmpty &&
                                        visibleIds.every(
                                          (id) => _selectedLeadIds.contains(id),
                                        );
                                    setState(() {
                                      if (allSelected) {
                                        _selectedLeadIds.removeAll(visibleIds);
                                      } else {
                                        _selectedLeadIds.addAll(visibleIds);
                                      }
                                    });
                                  },
                                )
                              : ListView.builder(
                                  cacheExtent: 3000,
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    bottom: 20.h,
                                    top: 10.h,
                                  ),
                                  itemCount:
                                      state.filteredLeads.length +
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
                                          leadStatus: 'لم يتم التواصل معه',
                                          createdBy: widget.user.id,
                                          assignedTo: widget.user.id,
                                        ),
                                        role: widget.user.role,
                                        initialEditMode: true,
                                        isAddingMode: true,
                                        onCancelAdd: () {
                                          setState(
                                            () => _isAddingNewLead = false,
                                          );
                                        },
                                        onTap: () {},
                                        onEdit: () {},
                                        onDelete: () {},
                                      );
                                    }

                                    final actualIndex = _isAddingNewLead
                                        ? index - 1
                                        : index;

                                    if (actualIndex >=
                                        state.filteredLeads.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }

                                    final lead =
                                        state.filteredLeads[actualIndex];
                                    final isBlinking =
                                        lead.id == state.blinkItemId;

                                    final card = BlinkContainer(
                                      isBlinking: isBlinking,
                                      child: LeadCard(
                                        key: ValueKey(lead.id),
                                        lead: lead,
                                        role: widget.user.role,
                                        onTap: () =>
                                            _openDetails(context, lead),
                                        onEdit: () =>
                                            _openForm(context, lead: lead),
                                        onDelete:
                                            (widget.user.role == 'manager' ||
                                                widget.user.role == 'admin' ||
                                                widget.user.role == 'ceo')
                                            ? () => LeadDeleteDialog.show(
                                                context,
                                                lead,
                                                () => _cubit.deleteLead(
                                                  lead.id!,
                                                  widget.user.role,
                                                ),
                                              )
                                            : null,
                                        onArchive: widget.user.role != 'admin'
                                            ? () => LeadArchiveDialog.show(
                                                context,
                                                lead,
                                                () => _cubit.archiveLead(
                                                  lead.id!,
                                                  true,
                                                ),
                                              )
                                            : null,
                                        onPinToggle: () =>
                                            _cubit.toggleLeadPin(lead),
                                      ),
                                    );

                                    if (_isBulkSelectMode) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 4.h,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Checkbox(
                                              value: _selectedLeadIds.contains(
                                                lead.id,
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedLeadIds.add(
                                                      lead.id!,
                                                    );
                                                  } else {
                                                    _selectedLeadIds.remove(
                                                      lead.id,
                                                    );
                                                  }
                                                });
                                              },
                                              activeColor:
                                                  AppColors.brandPrimary,
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
    );
  }

  Widget _buildQuickFilterBar(String currentFilter) {
    final filters = [
      {'key': 'الكل', 'label': 'الكل', 'icon': Icons.apps_rounded},
      {
        'key': 'لم يتم التواصل',
        'label': 'لم يتم التواصل',
        'icon': Icons.mark_chat_unread_rounded,
      },
      {
        'key': 'تم التواصل',
        'label': 'تم التواصل',
        'icon': Icons.check_circle_outline_rounded,
      },
      {'key': 'مهتم', 'label': 'مهتم', 'icon': Icons.thumb_up_alt_rounded},
      {'key': 'غير مهتم', 'label': 'غير مهتم', 'icon': Icons.cancel_outlined},
      {'key': 'لم يرد', 'label': 'لم يرد', 'icon': Icons.phone_missed_rounded},
      {'key': 'VIP', 'label': 'VIP', 'icon': Icons.star_rounded},
      {'key': 'بروكر', 'label': 'بروكر', 'icon': Icons.handshake_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((f) {
          final isSelected = currentFilter == f['key'];
          final isHighlight = f['key'] == 'لم يتم التواصل';

          return Padding(
            padding: EdgeInsets.only(left: 6.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: () {
                _cubit.applyQuickFilter(f['key'] as String);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isHighlight
                            ? const Color(0xFFE11D48)
                            : AppColors.brandPrimary)
                      : (isHighlight ? const Color(0xFFFFF1F2) : Colors.white),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? (isHighlight
                              ? const Color(0xFFE11D48)
                              : AppColors.brandPrimary)
                        : (isHighlight
                              ? const Color(0xFFFECDD3)
                              : Colors.grey.shade300),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                (isHighlight
                                        ? const Color(0xFFE11D48)
                                        : AppColors.brandPrimary)
                                    .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 15.sp,
                      color: isSelected
                          ? Colors.white
                          : (isHighlight
                                ? const Color(0xFFE11D48)
                                : Colors.grey.shade700),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isHighlight
                                  ? const Color(0xFFE11D48)
                                  : Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManagerScopeToggle() {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: EdgeInsets.all(2.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // كل عملاء الشركة
          InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () {
              if (_onlyMyLeads) {
                setState(() => _onlyMyLeads = false);
                _refreshLeadsWithCurrentFilters();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: !_onlyMyLeads
                    ? AppColors.brandPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: !_onlyMyLeads
                    ? [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.domain_rounded,
                    size: 16.sp,
                    color: !_onlyMyLeads ? Colors.white : Colors.grey.shade700,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'كل عملاء الشركة',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: !_onlyMyLeads
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: !_onlyMyLeads
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 2.w),
          // عملائي فقط
          InkWell(
            borderRadius: BorderRadius.circular(8.r),
            onTap: () {
              if (!_onlyMyLeads) {
                setState(() => _onlyMyLeads = true);
                _refreshLeadsWithCurrentFilters();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _onlyMyLeads
                    ? AppColors.brandPrimary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: _onlyMyLeads
                    ? [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_pin_circle_rounded,
                    size: 16.sp,
                    color: _onlyMyLeads ? Colors.white : Colors.grey.shade700,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    'عملائي فقط',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: _onlyMyLeads
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: _onlyMyLeads ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        !_isAllMonths &&
        _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    final monthLabel = _isAllMonths
        ? 'كل الشهور'
        : _formatMonthYear(_selectedMonth);

    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: !_isAllMonths ? AppColors.brandPrimary : Colors.grey.shade300,
          width: !_isAllMonths ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // زر الشهر السابق (في RTL السهم لليمين يعود للماضي)
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20.sp,
              color: Colors.grey.shade700,
            ),
            tooltip: 'الشهر السابق',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30.w, minHeight: 30.h),
            onPressed: () {
              final base = _isAllMonths ? DateTime.now() : _selectedMonth;
              _changeMonth(DateTime(base.year, base.month - 1, 1));
            },
          ),

          // منيو اختيار الشهر
          PopupMenuButton<String>(
            tooltip: 'تغيير الشهر',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            onSelected: (val) {
              if (val == 'ALL') {
                _setAllMonths();
              } else {
                final parts = val.split('-');
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                _changeMonth(DateTime(year, month, 1));
              }
            },
            itemBuilder: (ctx) {
              final items = <PopupMenuEntry<String>>[];

              items.add(
                PopupMenuItem<String>(
                  value: 'ALL',
                  child: Row(
                    children: [
                      Icon(
                        Icons.all_inclusive_rounded,
                        size: 18.sp,
                        color: _isAllMonths
                            ? AppColors.brandPrimary
                            : Colors.grey,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'جميع الشهور (كل الأوقات)',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: _isAllMonths
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _isAllMonths
                              ? AppColors.brandPrimary
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              items.add(const PopupMenuDivider());

              for (int i = 0; i < 12; i++) {
                final d = DateTime(now.year, now.month - i, 1);
                final isThis =
                    !_isAllMonths &&
                    _selectedMonth.year == d.year &&
                    _selectedMonth.month == d.month;
                items.add(
                  PopupMenuItem<String>(
                    value: '${d.year}-${d.month}',
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 18.sp,
                          color: isThis ? AppColors.brandPrimary : Colors.grey,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _formatMonthYear(d) + (i == 0 ? ' (الحالي)' : ''),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: isThis
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isThis
                                ? AppColors.brandPrimary
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return items;
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 17.sp,
                    color: !_isAllMonths
                        ? AppColors.brandPrimary
                        : Colors.grey.shade700,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    monthLabel,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.bold,
                      color: !_isAllMonths
                          ? AppColors.brandPrimary
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (isCurrentMonth) ...[
                    SizedBox(width: 5.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'الحالي',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 18.sp,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // زر الشهر التالي (في RTL السهم لليسار يتقدم للمستقبل)
          IconButton(
            icon: Icon(
              Icons.chevron_left_rounded,
              size: 20.sp,
              color: Colors.grey.shade700,
            ),
            tooltip: 'الشهر التالي',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30.w, minHeight: 30.h),
            onPressed: () {
              final base = _isAllMonths ? DateTime.now() : _selectedMonth;
              _changeMonth(DateTime(base.year, base.month + 1, 1));
            },
          ),
        ],
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
          child: LeadDetailsScreen(leadId: lead.id!, currentUser: widget.user),
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
                  items: state.employees
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                            e.firstName != null
                                ? "${e.firstName} ${e.lastName}"
                                : e.email,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => selectedEmployeeId = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedEmployeeId == null
                    ? null
                    : () {
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
    final leads = await _cubit.fetchAllForExport(
      role: widget.user.role,
      userId: widget.user.id,
    );
    if (leads.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }

    final allColumns = [
      '#',
      'اسم العميل',
      'أرقام الهاتف',
      'المسؤول',
      'تاريخ الإضافة',
      'كود العقار',
      'طلب العميل',
      'المنصة',
      'الحالة الحالية',
      'سبب الاستبعاد',
      'نوع الإعلان',
      'نوع العقار',
      'المدينة',
      'الملاحظات',
    ];

    final dataRows = leads.asMap().entries.map((entry) {
      final i = entry.key;
      final l = entry.value;
      final phonesStr = l.phones.map((p) => p.phoneNumber).join('\n');
      final notesStr = l.notes.isEmpty
          ? '—'
          : l.notes.map((n) => '• ${n.noteText}').join('\n');

      return [
        i + 1,
        l.clientName,
        phonesStr,
        l.assignedToName ?? '—',
        l.createdAt != null
            ? DateFormat("dd/MM/yyyy HH:mm").format(l.createdAt!)
            : '—',
        l.propertyCode ?? '—',
        l.descLeadNeed ?? '—',
        l.platform ?? '—',
        l.leadStatus ?? '—',
        l.exclusionReasonName ?? '—',
        l.listingType ?? '—',
        l.propertyType ?? '—',
        l.city ?? '—',
        notesStr,
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = di.sl<LeadRepository>();
      final dataManager = di.sl<StaticDataManager>();
      final notContactedStatusId =
          dataManager.getIdByName('lead_status', 'لم يتم التواصل معه') ??
          dataManager.getIdByName('lead_status', 'لم يتم التواصل') ??
          '460be748-7685-49ef-abcf-c4dd49511ab7';
      for (final id in _selectedLeadIds) {
        final currentLead = _cubit.state is LeadLoaded
            ? (_cubit.state as LeadLoaded).filteredLeads.firstWhere(
                (l) => l.id == id,
                orElse: () => LeadModel(
                  id: '',
                  clientName: '',
                  createdBy: '',
                  assignedTo: '',
                ),
              )
            : null;
        if (currentLead != null && currentLead.id!.isNotEmpty) {
          await repository.updateLeadStatusAndEmployee(
            id,
            notContactedStatusId,
            employeeId,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم النقل بنجاح')));
        setState(() {
          _isBulkSelectMode = false;
          _selectedLeadIds.clear();
        });
        _refreshLeadsWithCurrentFilters(isRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل النقل: $e')));
      }
    }
  }

  void _showBulkDeleteConfirmationDialog() {
    if (_selectedLeadIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: Colors.red.shade700,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 10.w),
            const Text(
              'تأكيد حذف العملاء',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف (${_selectedLeadIds.length}) عميل نهائياً؟\nهذا الإجراء سيقوم بحذف العملاء وكافة أرقام هواتفهم وملاحظاتهم نهائياً ولا يمكن التراجع عنه.',
          style: TextStyle(fontSize: 14.sp, height: 1.6),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            label: const Text(
              'نعم، حذف نهائي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performBulkDelete();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = _selectedLeadIds.length;
      await _cubit.bulkDeleteLeads(_selectedLeadIds.toList());

      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف $count عميل بنجاح'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() {
          _isBulkSelectMode = false;
          _selectedLeadIds.clear();
        });
        _refreshLeadsWithCurrentFilters(isRefresh: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
      }
    }
  }
}
