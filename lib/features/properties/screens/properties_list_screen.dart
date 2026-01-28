import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive_debouncer_wrapper.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../../../data/services/property_service.dart';
import '../../../data/services/storage_service.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // نلتزم بطريقتك الأصلية في استدعاء وإنشاء الـ Cubit
    _cubit = PropertiesCubit(
      PropertyRepository(
        PropertyService(),
        StorageService(Supabase.instance.client),
      ),
    )..fetchMyProperties(userId: widget.userId, isRefresh: true);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_cubit.state is PropertiesSuccess) {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _cubit.fetchMyProperties(userId: widget.userId);
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

    // العودة لاستخدام BlocProvider.value لضمان توفر الـ Cubit في الـ Context
    return BlocProvider.value(
      value: _cubit,
      child: ResponsiveDebouncerWrapper(
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: BlocConsumer<PropertiesCubit, PropertiesState>(
            listener: (context, state) {
              if (state is PropertiesError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
              // تم إزالة التحقق من state.message هنا لتجنب الخطأ الذي ظهر سابقاً
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(state),
                  _buildFilterSection(),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _cubit.fetchMyProperties(userId: widget.userId, isRefresh: true),
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

  Widget _buildHeader(PropertiesState state) {
    int total = 0;
    if (state is PropertiesSuccess) total = state.myTotalCount;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 45.h, 20.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("مخزون العقارات",
                  style: AppTextStyles.blue16Bold.copyWith(fontSize: 22.sp, color: Colors.black)),
              SizedBox(height: 4.h),
              Text("إدارة الوحدات ($total وحدة)", style: const TextStyle(color: Colors.grey)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _openForm(context: context, cubit: _cubit),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("إضافة وحدة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => _cubit.search(value),
              decoration: InputDecoration(
                hintText: "بحث سريع...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          _buildQuickFilterIcon(),
        ],
      ),
    );
  }

  Widget _buildQuickFilterIcon() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
      child: const Icon(Icons.tune, color: AppColors.primaryBlue),
    );
  }

  Widget _buildBody(PropertiesState state) {
    if (state is PropertiesLoading && state is! PropertiesSuccess) return _buildShimmerList();

    if (state is PropertiesSuccess) {
      final properties = state.myProperties;
      if (properties.isEmpty) return const Center(child: Text("لا توجد نتائج"));

      return ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount: properties.length + (properties.length < state.myTotalCount ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == properties.length) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
          final property = properties[index];
          return PropertyCard(
            key: ValueKey(property.id),
            property: property,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PropertyDetailsScreen(property: property))
            ),
            onEdit: () => _openForm(context: context, cubit: _cubit, property: property),
            onDelete: () => _confirmDelete(property),
          );
        },
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  void _confirmDelete(PropertyModel property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("حذف العقار"),
        content: Text("هل أنت متأكد من حذف ${property.titleAr}؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(
            onPressed: () {
              _cubit.deleteFullProperty(property.id);
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
            height: 120.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r))
        ),
      ),
    );
  }

  Future<void> _openForm({required BuildContext context, required PropertiesCubit cubit, PropertyModel? property}) async {
    await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BlocProvider.value(value: cubit, child: PropertyFormScreen(property: property, userId: widget.userId)))
    );
  }
}