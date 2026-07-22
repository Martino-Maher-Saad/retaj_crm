import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/export_helper.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/widgets/retaj_page_header.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/form_field_model.dart';
import '../../../data/services/dropdown_service.dart';
import '../cubit/leads_cubit.dart';
import '../cubit/leads_state.dart';
import '../widgets/list/lead_empty_state.dart';
import '../widgets/list/lead_filter_dialog.dart';
import '../widgets/list/lead_search_bar.dart';
import '../widgets/list/leads_table_view.dart';
import 'lead_form_screen.dart';
import 'lead_preview_side_sheet.dart';

class LeadsManagementScreen extends StatefulWidget {
  final ProfileModel user;
  const LeadsManagementScreen({super.key, required this.user});

  @override
  State<LeadsManagementScreen> createState() => _LeadsManagementScreenState();
}

class _LeadsManagementScreenState extends State<LeadsManagementScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late List<LeadCubit> _cubits;
  bool _isFiltering = false;

  final _dataManager = di.sl<StaticDataManager>();
  late TabController _tabController;

  final List<String> _baseTabs = [
    'عملائي',
    'عملاء فريش',
    'عملاء متأخرين',
    'عملاء محولين',
    'سلة المهملات',
    'مكررين',
  ];

  List<String> get _tabs {
    if (AppRole.fromString(widget.user.role).isAtLeast(AppRole.leader)) {
      return ['كل العملاء', ..._baseTabs];
    }
    return _baseTabs;
  }

  LeadCubit get _cubit => _cubits[_tabController.index];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubits = List.generate(_tabs.length, (_) => di.sl<LeadCubit>());
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTab(0);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // Rebuild to provide the active tab's cubit
    if (_cubit.state is LeadInitial) {
      _loadTab(_tabController.index);
    }
  }

  void _loadTab(int index) {
    setState(() => _isFiltering = false);
    final tabName = _tabs[index];
    final targetCubit = _cubits[index];

    String? filterByEmployeeId;
    List<String>? statusIds;
    bool? delayFilter;
    bool? isTransferred;
    bool? isTrash = false;
    bool? isDuplicate;

    if (tabName == 'عملائي') {
      filterByEmployeeId = widget.user.id;
    } else if (tabName == 'عملاء فريش') {
      filterByEmployeeId = widget.user.id;
      statusIds = _dataManager.getStatusIdsByBehavior('fresh');
    } else if (tabName == 'عملاء متأخرين') {
      filterByEmployeeId = widget.user.id;
      delayFilter = true;
    } else if (tabName == 'عملاء محولين') {
      filterByEmployeeId =
          AppRole.fromString(widget.user.role).isAtLeast(AppRole.leader)
          ? null
          : widget.user.id;
      isTransferred = true;
    } else if (tabName == 'سلة المهملات') {
      isTrash = true;
    } else if (tabName == 'كل العملاء') {
      filterByEmployeeId = null;
    } else if (tabName == 'مكررين') {
      isDuplicate = true;
      filterByEmployeeId = widget.user.id;
    }

    targetCubit.getAllLeads(
      role: widget.user.role,
      userId: widget.user.id,
      isRefresh: true,
      filterByEmployeeId: filterByEmployeeId,
      statusIds: statusIds,
      delayFilter: delayFilter,
      isTransferred: isTransferred,
      isTrash: isTrash,
      isDuplicate: isDuplicate,
    );
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
      setState(() => _isFiltering = true);
    });
  }

  void _openForm(BuildContext context, {LeadModel? lead}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LeadForm',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: SizedBox(
              width: (MediaQuery.of(context).size.width * 0.5).clamp(360.0, 900.0), // Same width as PropertyPreviewSideSheet
              child: BlocProvider.value(
                value: _cubit,
                child: LeadFormScreen(lead: lead, user: widget.user),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    ).then((val) {
      if (val == true) _loadTab(_tabController.index);
    });
  }

  void _openDetails(BuildContext context, LeadModel lead) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LeadPreview',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: BlocProvider.value(
              value: _cubit,
              child: LeadPreviewSideSheet(
                leadId: lead.id!,
                currentUser: widget.user,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    ).then((val) {
      if (val == true) _loadTab(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    // نغلق كل الـ cubits المُنشأة في هذه الشاشة عشان منخدوش memory leaks
    for (final cubit in _cubits) {
      cubit.close();
    }
    super.dispose();
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
            BlocBuilder<LeadCubit, LeadState>(
              builder: (context, state) {
                final int total = (state is LeadLoaded) ? state.totalCount : 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.brandPrimary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.brandPrimary,
                        tabs: _tabs.map((t) => Tab(text: t)).toList(),
                      ),
                    ),
                    RetajPageHeader(
                      title: 'مخزون العملاء',
                      subtitle: 'تتبع وإدارة وتحويل فرص الاستثمار العقاري',
                      addLabel: 'إضافة عميل',
                      onAdd: () => _openForm(context),
                      totalCount: total,
                      onFilter: () => _openFilterDialog(context),
                      filterLabel: 'فلاتر متقدمة',
                      onExport:
                          AppRole.fromString(
                            widget.user.role,
                          ).isAtLeast(AppRole.leader)
                          ? () async {
                                  if (state is LeadLoaded) {
                                    final selectedCols =
                                        await _showExportColumnsDialog(context);
                                    if (selectedCols == null ||
                                        selectedCols.isEmpty)
                                      return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'جاري تصدير العملاء للـ Excel...',
                                    ),
                                  ),
                                );
                                try {
                                  final allFiltered = await _cubit
                                      .exportFilteredLeads(
                                        role: widget.user.role,
                                        userId: widget.user.id,
                                      );
                                  await ExportHelper.exportLeadsToExcel(
                                    allFiltered,
                                    selectedCols,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم التصدير بنجاح'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'حدث خطأ أثناء التصدير: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      hasActiveFilters: _cubit.hasAdvancedFilters,
                      onClearFilter: () {
                        _cubit.clearAdvancedFilters();
                        setState(() => _isFiltering = false);
                      },
                      searchBar: LeadSearchBar(
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
                    ),
                  ],
                );
              },
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (index) {
                  return LeadTabContent(
                    cubit: _cubits[index],
                    tabName: _tabs[index],
                    user: widget.user,
                    onRefresh: () async => _loadTab(index),
                    onOpenDetails: (lead) => _openDetails(context, lead),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusesBar(String tabName) {
    List<LookupOptionModel> statuses = _dataManager.getOptionModels(
      'lead_status',
    );
    if (tabName == 'عملاء فريش') {
      statuses = statuses
          .where(
            (s) => (s.extra?['stage_type'] as Map?)?['behavior'] == 'fresh',
          )
          .toList();
    }
    if (statuses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: ActionChip(
                label: const Text('الكل'),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  _cubit.filterByQuickStatus(
                    null,
                    role: widget.user.role,
                    userId: widget.user.id!,
                  );
                },
              ),
            ),
            ...statuses.map((status) {
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: ActionChip(
                  label: Text(status.nameAr),
                  backgroundColor: AppColors.brandPrimary.withValues(
                    alpha: 0.1,
                  ),
                  labelStyle: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onPressed: () {
                    // Filter leads by this status via backend
                    _cubit.filterByQuickStatus(
                      status.id,
                      role: widget.user.role,
                      userId: widget.user.id!,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<List<FormFieldModel>?> _showExportColumnsDialog(
    BuildContext context,
  ) async {
    final staticManager = di.sl<StaticDataManager>();
    final exportableFields = staticManager.formFields.where((f) => f.isExportable).toList();
    
    final Map<FormFieldModel, bool> selected = {
      for (var field in exportableFields) field: false,
    };

    return showDialog<List<FormFieldModel>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'اختر الأعمدة للتصدير',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: exportableFields.map((field) {
                    return CheckboxListTile(
                      title: Text(
                        field.titleAr,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: selected[field],
                      onChanged: (val) {
                        setState(() {
                          selected[field] = val ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cols = selected.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    Navigator.pop(ctx, cols);
                  },
                  child: const Text(
                    'تصدير',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class LeadTabContent extends StatefulWidget {
  final LeadCubit cubit;
  final String tabName;
  final ProfileModel user;
  final Future<void> Function() onRefresh;
  final void Function(LeadModel) onOpenDetails;

  const LeadTabContent({
    super.key,
    required this.cubit,
    required this.tabName,
    required this.user,
    required this.onRefresh,
    required this.onOpenDetails,
  });

  @override
  State<LeadTabContent> createState() => _LeadTabContentState();
}

class _LeadTabContentState extends State<LeadTabContent> with AutomaticKeepAliveClientMixin {
  final _dataManager = di.sl<StaticDataManager>();

  @override
  bool get wantKeepAlive => true;

  Widget _buildQuickStatusesBar(String tabName) {
    List<LookupOptionModel> statuses = _dataManager.getOptionModels('lead_status');
    if (tabName == 'عملاء فريش') {
      statuses = statuses
          .where((s) => (s.extra?['stage_type'] as Map?)?['behavior'] == 'fresh')
          .toList();
    }
    if (statuses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: ActionChip(
                label: const Text('الكل'),
                backgroundColor: Colors.white,
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  widget.cubit.filterByQuickStatus(
                    null,
                    role: widget.user.role,
                    userId: widget.user.id!,
                  );
                },
              ),
            ),
            ...statuses.map((status) {
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: ActionChip(
                  label: Text(status.nameAr),
                  backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  onPressed: () {
                    widget.cubit.filterByQuickStatus(
                      status.id,
                      role: widget.user.role,
                      userId: widget.user.id!,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<LeadCubit, LeadState>(
      bloc: widget.cubit,
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
            child: LeadsTableView(
              role: widget.user.role,
              onTap: (_) {},
              leads: List.generate(
                4,
                (index) => LeadModel(
                  id: 'dummy',
                  clientName: 'تحميل...',
                  createdBy: '',
                  assignedTo: '',
                ),
              ),
            ),
          );
        }

        if (state is LeadLoaded) {
          if (state.filteredLeads.isEmpty) return const LeadEmptyState();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (['عملائي', 'كل العملاء'].contains(widget.tabName))
                _buildQuickStatusesBar(widget.tabName),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 8.h,
                ),
                child: Row(
                  children: [
                    Text(
                      "عدد النتائج: ${state.isSearching ? state.filteredLeads.length : state.totalCount}",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (widget.tabName == 'مكررين') ...[
                      SizedBox(width: 16.w),
                      ElevatedButton.icon(
                        onPressed: widget.onRefresh,
                        icon: Icon(Icons.search_rounded, size: 18.sp),
                        label: Text('فحص التكرارات', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        ),
                      ),
                    ],
                    if (widget.tabName == 'عملاء متأخرين') ...[
                      SizedBox(width: 16.w),
                      ElevatedButton.icon(
                        onPressed: widget.onRefresh,
                        icon: Icon(Icons.refresh_rounded, size: 18.sp),
                        label: Text('تحديث المتأخرين', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  child: LeadsTableView(
                    role: widget.user.role,
                    leads: state.filteredLeads,
                    isLoadingMore: state.isLoadingMore,
                    flashingIds: state.flashingIds,
                    hasMore: state.filteredLeads.length < state.totalCount,
                    onTap: widget.onOpenDetails,
                    onLoadMore: () {
                      widget.cubit.loadMoreLeads(
                        role: widget.user.role,
                        userId: widget.user.id,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
