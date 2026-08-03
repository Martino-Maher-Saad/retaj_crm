import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/excel_export_service.dart';
import '../../../core/utils/responsive_debouncer_wrapper.dart';
import '../../../data/models/property_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/property_sync_notifier.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/list/property_delete_dialog.dart';
import '../widgets/list/property_archive_dialog.dart';
import '../widgets/list/property_list_header.dart';
import '../widgets/list/property_search_bar.dart';
import '../widgets/list/property_shimmer_list.dart';
import '../widgets/list/internal_share_dialog.dart' as import_helper;
import '../widgets/property_card.dart';
import '../../../../core/widgets/blink_container.dart';
import '../widgets/list/advanced_filter_dialog.dart';

class PropertiesListScreen extends StatefulWidget {
  final String userId;
  final String role;

  const PropertiesListScreen({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen>
    with AutomaticKeepAliveClientMixin {
  late PropertiesCubit _cubit;
  late PropertySyncNotifier _sync;
  final ScrollController _scrollController = ScrollController();
  bool _searchAll = false;
  bool _isAddingNewProperty = false;

  @override
  bool get wantKeepAlive => true;

  void _onPropertySync() {
    final updated = _sync.consumeUpdate();
    if (updated != null) {
      _cubit.patchProperty(updated);
      return;
    }
    final deletedId = _sync.consumeDeletion();
    if (deletedId != null) {
      _cubit.removeProperty(deletedId);
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PropertiesCubit>()..fetchMyProperties(
        userId: widget.userId, 
        role: widget.role, 
        isRefresh: true,
      );
    _sync = di.sl<PropertySyncNotifier>()..addListener(_onPropertySync);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sync.removeListener(_onPropertySync);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_cubit.state is PropertiesSuccess) {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent * 0.6) {
        final current = _cubit.state as PropertiesSuccess;

        // البحث لا يدعم pagination حالياً
        if (current.isSearching) return;

        // أثناء الفلتر: لازم نكمّل filteredProperties فقط
        if (current.isFiltering) {
          _cubit.loadMoreFilteredProperties();
          return;
        }

        // بدون فلتر: كمّل القائمة الأساسية
        _cubit.fetchMyProperties(userId: widget.userId, role: widget.role);
      }
    }
  }

  Future<void> _exportProperties() async {
    final isManagerOrAdmin = widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo';
    if (!isManagerOrAdmin) return;

    final properties = await _cubit.fetchAllForExport(role: widget.role, userId: widget.userId);
    if (properties.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للتصدير')));
      return;
    }

    final allColumns = [
      '#', 'تاريخ الإضافة', 'كود العقار', 'السعر', 
      'اسم المالك', 'أرقام المالك', 'المنشئ', 'نوع العقار',
      'نوع الإعلان', 'المدينة', 'وصف العقار', 'ملاحظات إدارية', 'ملاحظات داخلية'
    ];

    final dataRows = properties.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;

      return [
        i + 1,
        p.createdAt != null ? DateFormat("dd/MM/yyyy HH:mm").format(p.createdAt!) : '—',
        p.propertyCode ?? '—',
        NumberFormat.currency(symbol: '').format(p.price),
        p.ownerName ?? '—',
        p.ownerPhone ?? '—',
        p.createdByName ?? '—',
        p.propertyTypeAr,
        p.listingTypeAr,
        p.cityAr,
        p.descAr,
        p.managerNotes ?? '—',
        p.internalNotes ?? '—',
      ];
    }).toList();

    if (mounted) {
      await ExcelExportService.showExportDialog(
        context: context,
        title: 'العقارات',
        allColumns: allColumns,
        dataRows: dataRows,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveDebouncerWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: BlocConsumer<PropertiesCubit, PropertiesState>(
            listener: (context, state) {
              if (state is PropertiesError) {
                print('==================================================================');
                print('❌ [PROPERTIES INVENTORY ERROR DETECTED]:');
                print('Message: ${state.message}');
                print('==================================================================');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              int total = 0;
              if (state is PropertiesSuccess) {
                total = state.isSearching 
                  ? state.searchedProperties.length 
                  : state.isFiltering 
                      ? state.filteredTotalCount 
                      : state.myTotalCount;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PropertyListHeader(
                    totalCount: total,
                    onAdd: () {
                      setState(() {
                        _isAddingNewProperty = true;
                      });
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    extraAction: (widget.role == 'manager' || widget.role == 'admin' || widget.role == 'ceo')
                        ? OutlinedButton.icon(
                            onPressed: _exportProperties,
                            icon: const Icon(Icons.file_download, size: 18),
                            label: const Text('تصدير'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandPrimary,
                              side: BorderSide(color: AppColors.brandPrimary, width: 1.5),
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          )
                        : null,
                    onFilter: () => _openAdvancedFilter(context),
                    filterBar: PropertySearchBar(
                      showToggle: widget.role == 'sales' || widget.role == 'marketing',
                      searchAll: _cubit.searchAll,
                      onToggleSearchAll: (val) {
                        _cubit.toggleSearchAll(val);
                        if (_cubit.state is PropertiesSuccess && (_cubit.state as PropertiesSuccess).isSearching) {
                          _cubit.clearSearch();
                        }
                        setState(() {});
                      },
                      onSearch: (val, type) {
                        final assignedToFilter = (widget.role == 'sales' || widget.role == 'marketing')
                            ? (_cubit.searchAll ? null : widget.userId)
                            : null;
                        if (type == 'general') {
                          _cubit.smartSearch(val, assignedTo: assignedToFilter);
                        } else {
                          final actualAssignedTo = (type == 'phone' && (widget.role == 'sales' || widget.role == 'marketing')) ? widget.userId : assignedToFilter;
                          _cubit.search(val, type: type, assignedTo: actualAssignedTo);
                        }
                      },
                      onFilterTap: () => _openAdvancedFilter(context),
                      onClear: () => _cubit.clearSearch(),
                      isSearching: state is PropertiesSuccess ? state.isSearching : false,
                    ),
                  ),
                  if (state is PropertiesSuccess && state.isFiltering)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                      color: Colors.orange.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("نتائج الفلتر المتقدم 🎯", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13.sp)),
                          TextButton(
                            onPressed: () => _cubit.clearFilter(),
                            child: const Text("إلغاء", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  BlocBuilder<PropertiesCubit, PropertiesState>(
                    builder: (context, state) {
                      if (state is PropertiesSuccess && state.hasNewUpdates) {
                        return GestureDetector(
                          onTap: () {
                            if (state.pendingProperties.isNotEmpty) {
                              _cubit.applyPendingUpdates();
                            } else {
                              _cubit.fetchMyProperties(
                                userId: widget.userId,
                                role: widget.role,
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
                                  'يوجد تحديثات للعقارات، انقر للتحديث',
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
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _cubit.fetchMyProperties(
                        userId: widget.userId,
                        role: widget.role,
                        isRefresh: true,
                      ),
                      child: _buildBody(state),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
  }

  Widget _buildBody(PropertiesState state) {
    if (state is PropertiesLoading && state is! PropertiesSuccess) {
      return const PropertyShimmerList();
    }

    if (state is PropertiesSuccess) {
      final successState = state;
      final properties = successState.isSearching 
          ? successState.searchedProperties 
          : successState.isFiltering 
              ? successState.filteredProperties 
              : successState.myProperties;
              
      if (properties.isEmpty && !_isAddingNewProperty) return const Center(child: Text("لا توجد نتائج"));

      final int totalCount = successState.isSearching 
          ? properties.length 
          : successState.isFiltering 
              ? successState.filteredTotalCount 
              : successState.myTotalCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              itemCount: properties.length +
                  (successState.isSearching
                      ? (successState.hasMoreSmartSearch ? 1 : 0)
                      : (properties.length < totalCount ? 1 : 0)) +
                  (_isAddingNewProperty ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAddingNewProperty && index == 0) {
                  return PropertyCard(
                    key: const ValueKey('new_property_inline'),
                    property: PropertyModel(
                      id: '',
                      status: true,
                      isPinned: false,
                      ownerName: '',
                      ownerPhone: '',
                      createdBy: widget.userId,
                      listingTypeAr: 'للبيع',
                      propertyTypeAr: 'شقة',
                      propertyCode: '',
                      price: 0,
                      internalNotes: '',
                      images: const [],
                      titleAr: '',
                      descAr: '',
                      governorateAr: '',
                      cityAr: '',
                    ),
                    currentUserId: widget.userId,
                    role: widget.role,
                    initialEditMode: true,
                    isAddingMode: true,
                    onCancelAdd: () {
                      setState(() => _isAddingNewProperty = false);
                    },
                    onTap: () {},
                    onEdit: () {},
                  );
                }

                final actualIndex = _isAddingNewProperty ? index - 1 : index;

                if (actualIndex == properties.length) {
                  if (successState.isSearching) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 30.w),
                        child: _cubit.isLoadingMoreSmartSearch
                            ? const CircularProgressIndicator()
                            : OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.brandPrimary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                                ),
                                onPressed: () {
                                  _cubit.loadMoreSmartSearch().then((_) {
                                    setState(() {}); // trigger rebuild to update spinner state
                                  });
                                },
                                icon: const Icon(Icons.refresh_rounded, color: AppColors.brandPrimary),
                                label: Text(
                                  "عرض المزيد من نتائج البحث 🔄",
                                  style: TextStyle(
                                    color: AppColors.brandPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                }
                final property = properties[actualIndex];
                final isBlinking = property.id == successState.blinkItemId;
                
                final isManagerOrAdmin = widget.role.toLowerCase() == 'manager' || widget.role.toLowerCase() == 'admin' || widget.role.toLowerCase() == 'ceo';
                final canEdit = isManagerOrAdmin || property.createdBy == widget.userId;

                return BlinkContainer(
                  isBlinking: isBlinking,
                  child: PropertyCard(
                    key: ValueKey(property.id),
                    property: property,
                    currentUserId: widget.userId,
                    role: widget.role,
                    onTap: () {},
                    onEdit: canEdit ? () {} : null,
                    onArchive: canEdit ? () => PropertyArchiveDialog.show(
                      context,
                      property,
                      () => _cubit.archiveProperty(property.id, true),
                    ) : null,
                    onDelete: canEdit ? () => PropertyDeleteDialog.show(
                      context,
                      property,
                      () => _cubit.deleteFullProperty(property.id),
                    ) : null,
                    onShareInternal: canEdit ? () => import_helper.InternalShareDialog.show(
                      context,
                      property,
                      widget.userId,
                      _cubit,
                    ) : null,
                    onPinToggle: canEdit ? () {
                      _cubit.togglePropertyPin(property);
                    } : null,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }



  void _openAdvancedFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: _cubit, 
        child: AdvancedFilterDialog(
          role: widget.role,
          currentUserId: widget.userId,
        ),
      ),
    );
  }
}
