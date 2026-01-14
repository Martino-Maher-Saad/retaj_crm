import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_debouncer_wrapper.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/property_service.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/build_pagination_bar.dart';
import '../widgets/property_card.dart';
import 'property_details_screen.dart';
import 'property_form_screen.dart';

class PropertiesListScreen extends StatefulWidget {
  final String userId;
  final String role;

  const PropertiesListScreen({super.key, required this.userId, required this.role});

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> with AutomaticKeepAliveClientMixin {
  late PropertiesCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = PropertiesCubit(PropertiesRepository(PropertiesService()))
      ..fetchPage(userId: widget.userId, role: widget.role, page: 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _cubit,
      child: ResponsiveDebouncerWrapper(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocConsumer<PropertiesCubit, PropertiesState>(
            listener: (context, state) {
              if (state is PropertiesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }

              // --- معالجة مشكلة حذف آخر عنصر في الصفحة ---
              if (state is PropertiesSuccess) {
                // حساب عدد الصفحات الكلي المتاح حالياً (مثلاً لو الإجمالي 15 والصفحة 15، النتيجة 0 وهي الصفحة الأولى)
                int maxAvailablePage = state.totalCount <= 0
                    ? 0
                    : (state.totalCount / AppConstants.pageSize).ceil() - 1;

                // إذا كان المستخدم في صفحة (مثلاً 2) وأصبحت أقصى صفحة متاحة (1)
                if (state.currentPage > 0 && state.currentPage > maxAvailablePage) {
                  _cubit.fetchPage(
                    page: maxAvailablePage,
                    userId: widget.userId,
                    role: widget.role,
                    city: state.city,
                    type: state.type,
                    sortByPrice: state.sortByPrice,
                  );
                }
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  _buildFilterSection(state),
                  Expanded(
                    child: _buildBody(state),
                  ),
                  if (state is PropertiesSuccess && state.totalCount > AppConstants.pageSize)
                    BuildPaginationBar(
                      state: state,
                      cubit: _cubit,
                      userId: widget.userId,
                      role: widget.role,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PropertiesState state) {
    int total = 0;
    if (state is PropertiesSuccess) total = state.totalCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Properties Inventory", style: AppTextStyles.blue20Medium.copyWith(fontSize: 22.sp, fontWeight: FontWeight.bold, color: Colors.black)),
              SizedBox(height: 4.h),
              Text("Manage and track your real estate listings ($total units)", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _openForm(context: context, cubit: _cubit),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add Property"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(PropertiesState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by ID, Location...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.greyLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.greyLight)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
              ),
            ),
          ),
          SizedBox(width: 15.w),
          _buildQuickFilter("City"),
          SizedBox(width: 10.w),
          _buildQuickFilter("Type"),
          SizedBox(width: 10.w),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.sort_rounded),
            tooltip: "Sort by Price",
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyLight),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12.sp)),
          Icon(Icons.arrow_drop_down, size: 18.sp),
        ],
      ),
    );
  }

  Widget _buildBody(PropertiesState state) {
    if (state is PropertiesLoading) {
      return _buildShimmerList();
    } else if (state is PropertiesSuccess) {
      final properties = state.currentProperties;
      if (properties.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 50.sp, color: Colors.grey),
              SizedBox(height: 10.h),
              const Text("No Properties Found in this page"),
            ],
          ),
        );
      }

      return ListView.builder(
        key: PageStorageKey('properties_page_${state.currentPage}'),
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return PropertyCard(
            key: ValueKey(property.id),
            property: property,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property)),
            ),
            onEdit: () => _openForm(context: context, cubit: _cubit, property: property),
            onDelete: () => _cubit.deleteProperty(property.id),
          );
        },
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: EdgeInsets.only(bottom: 15.h),
          height: 130.h,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        ),
      ),
    );
  }

  Future<void> _openForm({required BuildContext context, required PropertiesCubit cubit, PropertyModel? property}) async {
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
}