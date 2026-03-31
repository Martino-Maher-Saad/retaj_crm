import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/responsive_debouncer_wrapper.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/property_service.dart';
import '../../../data/services/storage_service.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/list/property_delete_dialog.dart';
import '../widgets/list/property_list_header.dart';
import '../widgets/list/property_search_bar.dart';
import '../widgets/list/property_shimmer_list.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = PropertiesCubit(
      PropertyRepository(
        PropertyService(),
        StorageService(Supabase.instance.client),
        AiService(),
      ),
    )..fetchMyProperties(
        userId: widget.userId, 
        role: widget.role, 
        isRefresh: true,
      );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_cubit.state is PropertiesSuccess) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _cubit.fetchMyProperties(userId: widget.userId, role: widget.role);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
              final total = state is PropertiesSuccess ? state.myTotalCount : 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PropertyListHeader(
                    totalCount: total,
                    onAdd: () => _openForm(context: context, cubit: _cubit),
                  ),
                  PropertySearchBar(
                    onSearch: (v) => _cubit.smartSearch(v),
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
      final properties = state.isSearching 
          ? state.searchedProperties 
          : state.isFiltering 
              ? state.filteredProperties 
              : state.myProperties;
              
      if (properties.isEmpty) return const Center(child: Text("لا توجد نتائج"));

      final int totalCount = state.isSearching 
          ? properties.length // البحث الشامل لا يدعم الـ pagination حالياً
          : state.isFiltering 
              ? state.filteredTotalCount 
              : state.myTotalCount;

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount:
            properties.length +
            (properties.length < totalCount ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == properties.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
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
            onDelete: () => PropertyDeleteDialog.show(
              context,
              property,
              () => _cubit.deleteFullProperty(property.id),
            ),
          );
        },
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
          child: PropertyFormScreen(property: property, userId: widget.userId),
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
