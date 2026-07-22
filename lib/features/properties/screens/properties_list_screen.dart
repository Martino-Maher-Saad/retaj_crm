import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

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
import '../widgets/list/advanced_filter_dialog.dart';
import 'property_details_screen.dart';
import 'property_form_screen.dart';

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
    _cubit = di.sl<PropertiesCubit>()..fetchMyProperties(
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: _cubit,
      child: ResponsiveDebouncerWrapper(
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
                    onAdd: () => _openForm(context: context, cubit: _cubit),
                    onFilter: () => _openAdvancedFilter(context),
                  ),
                  PropertySearchBar(
                    showToggle: widget.role == 'sales',
                    searchAll: _cubit.searchAll,
                    onToggleSearchAll: (val) {
                      _cubit.toggleSearchAll(val);
                      // If there is an active search, re-trigger it with new scope
                      if (_cubit.state is PropertiesSuccess && (_cubit.state as PropertiesSuccess).isSearching) {
                        _cubit.clearSearch();
                      }
                      setState(() {});
                    },
                    onSearch: (val, type) {
                      final assignedToFilter = widget.role == 'sales'
                          ? (_cubit.searchAll ? null : widget.userId)
                          : null;
                      if (type == 'general') {
                        _cubit.smartSearch(val, assignedTo: assignedToFilter);
                      } else {
                        // For 'phone' type, it should always be restricted to user's properties for 'sales'
                        final actualAssignedTo = (type == 'phone' && widget.role == 'sales') ? widget.userId : assignedToFilter;
                        _cubit.search(val, type: type, assignedTo: actualAssignedTo);
                      }
                    },
                    onFilterTap: () => _openAdvancedFilter(context),
                    onClear: () => _cubit.clearSearch(),
                    isSearching: state is PropertiesSuccess ? state.isSearching : false,
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
              
      if (properties.isEmpty) return const Center(child: Text("لا توجد نتائج"));

      final int totalCount = successState.isSearching 
          ? properties.length 
          : successState.isFiltering 
              ? successState.filteredTotalCount 
              : successState.myTotalCount;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Text(
              "عدد النتائج: $totalCount",
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              itemCount: properties.length +
                  (successState.isSearching
                      ? (successState.hasMoreSmartSearch ? 1 : 0)
                      : (properties.length < totalCount ? 1 : 0)),
              itemBuilder: (context, index) {
                if (index == properties.length) {
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
                final property = properties[index];
                return PropertyCard(
                  key: ValueKey(property.id),
                  property: property,
                  currentUserId: widget.userId,
                  role: widget.role,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailsScreen(
                        property: property,
                        currentUserId: widget.userId,
                        role: widget.role,
                      ),
                    ),
                  ),
                  onEdit: () =>
                      _openForm(context: context, cubit: _cubit, property: property),
                  onArchive: () => PropertyArchiveDialog.show(
                    context,
                    property,
                    () => _cubit.archiveProperty(property.id, true),
                  ),
                  onDelete: () => PropertyDeleteDialog.show(
                    context,
                    property,
                    () => _cubit.deleteFullProperty(property.id),
                  ),
                  onShareInternal: () => import_helper.InternalShareDialog.show(
                    context,
                    property,
                    widget.userId,
                    _cubit,
                  ),
                  onPinToggle: () => _cubit.togglePropertyPin(property),
                );
              },
            ),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _openForm({
    required BuildContext context,
    required PropertiesCubit cubit,
    PropertyModel? property,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PropertyFormScreen(
            property: property,
            userId: widget.userId,
            userRole: widget.role,
          ),
        ),
      ),
    );
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
