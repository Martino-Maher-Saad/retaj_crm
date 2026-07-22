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
import 'property_preview_side_sheet.dart';
import 'property_form_screen.dart';
import '../widgets/list/properties_table_view.dart';
import '../widgets/list/properties_grid_view.dart';

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
    // Bulk Transfer: إعادة تحميل كل العقارات
    if (_sync.consumeRefresh()) {
      _cubit.fetchMyProperties(
        userId: widget.userId,
        role: widget.role,
        isRefresh: true,
      );
      return;
    }
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
    _cubit = di.sl<PropertiesCubit>()
      ..setCurrentUser(widget.userId, widget.role)
      ..fetchMyProperties(
          userId: widget.userId,
          role: widget.role,
          isRefresh: true,
        );
    _sync = di.sl<PropertySyncNotifier>()..addListener(_onPropertySync);
  }

  @override
  void dispose() {
    _sync.removeListener(_onPropertySync);
    super.dispose();
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
                    searchBar: PropertySearchBar(
                      showToggle: widget.role == 'sales',
                      searchAll: _cubit.searchAll,
                      onToggleSearchAll: (val) {
                        _cubit.toggleSearchAll(val);
                        if (_cubit.state is PropertiesSuccess && (_cubit.state as PropertiesSuccess).isSearching) {
                          _cubit.clearSearch();
                        }
                        setState(() {});
                        _cubit.fetchMyProperties(userId: widget.userId, role: widget.role);
                      },
                      onSearch: (val, type) {
                        final actualAssignedTo = _cubit.searchAll ? null : widget.userId;
                        if (type == 'general') {
                          _cubit.smartSearch(val, assignedTo: actualAssignedTo);
                        } else {
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

      final isLoadingMore = successState.isSearching 
          ? _cubit.isLoadingMoreSmartSearch
          : false;

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
            child: PropertiesTableView(
              properties: properties,
              role: widget.role,
              isLoadingMore: isLoadingMore,
              hasMore: properties.length < totalCount,
              onTap: _goToDetails,
              onLoadMore: _handleLoadMore,
              onEdit: (property) => _openForm(context: context, cubit: _cubit, property: property),
              onArchive: (property) => PropertyArchiveDialog.show(
                context,
                property,
                () => _cubit.archiveProperty(property.id, true),
              ),
              onDelete: (property) => PropertyDeleteDialog.show(
                context,
                property,
                () => _cubit.deleteFullProperty(property.id),
              ),
              onShareInternal: (property) => import_helper.InternalShareDialog.show(
                context,
                property,
                widget.userId,
                _cubit,
              ),
              onPinToggle: (property) => _cubit.togglePropertyPin(property),
            ),
          ),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  void _goToDetails(PropertyModel property) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PropertyPreview',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: PropertyPreviewSideSheet(
              property: property,
              currentUserId: widget.userId,
              role: widget.role,
              cubit: _cubit,
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    ).then((result) {
      if (result == true) {
        _cubit.fetchMyProperties(
          userId: widget.userId,
          role: widget.role,
          isRefresh: true,
        );
      }
    });
  }

  void _handleLoadMore() {
    final state = _cubit.state;
    if (state is PropertiesSuccess) {
      if (state.isSearching) {
        if (state.hasMoreSmartSearch) {
          _cubit.loadMoreSmartSearch().then((_) => setState(() {}));
        }
      } else if (state.isFiltering) {
        _cubit.loadMoreFilteredProperties();
      } else {
        _cubit.fetchMyProperties(userId: widget.userId, role: widget.role);
      }
    }
  }

  Future<void> _openForm({
    required BuildContext context,
    required PropertiesCubit cubit,
    PropertyModel? property,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'PropertyForm',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: BlocProvider.value(
              value: cubit,
              child: PropertyFormScreen(
                property: property,
                userId: widget.userId,
                userRole: widget.role,
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
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
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
