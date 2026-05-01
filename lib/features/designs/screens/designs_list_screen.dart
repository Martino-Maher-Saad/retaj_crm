import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/retaj_page_header.dart';
import '../cubit/designs_cubit.dart';
import '../cubit/designs_state.dart';
import 'add_design_screen.dart';
import 'design_details_screen.dart';
import 'edit_design_screen.dart';
import '../widgets/design_card.dart';

import '../../../core/di/injection_container.dart' as di;

class DesignsListScreen extends StatefulWidget {
  const DesignsListScreen({super.key});

  @override
  State<DesignsListScreen> createState() => _DesignsListScreenState();
}

class _DesignsListScreenState extends State<DesignsListScreen>
    with AutomaticKeepAliveClientMixin {
  late DesignsCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<DesignsCubit>();
    _scrollController.addListener(_onScroll);
    _cubit.fetchDesigns(isRefresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.fetchDesigns();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _cubit.searchDesigns(query);
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: const AddDesignScreen(),
        ),
      ),
    );
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
            // ─── Header الموحّد ───
            RetajPageHeader(
              title: 'مكتبة التصاميم',
              subtitle: 'تصفح وإدارة جميع التصاميم والوحدات المعروضة',
              addLabel: 'إضافة تصميم',
              onAdd: _openAddScreen,
              // شريط البحث ضمن الـ Header
              searchBar: Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFEAEAF0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  style: TextStyle(fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: 'بحث ذكي عن تصميم...',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: const Color(0xFFBBBBCC),
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.brandPrimary, size: 20.sp),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _cubit.fetchDesigns(isRefresh: true);
                            },
                          )
                        : null,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 0, horizontal: 16.w),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // ─── المحتوى ───
            Expanded(
              child: BlocBuilder<DesignsCubit, DesignsState>(
                builder: (context, state) {
                  if (state is DesignsInitial || state is DesignsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DesignsError) {
                    return Center(child: Text("خطأ: ${state.message}"));
                  }

                  List designs = [];
                  bool hasReachedMax = false;

                  if (state is DesignsLoaded) {
                    designs = state.designs;
                    hasReachedMax = state.hasReachedMax;
                  } else if (state is DesignsSearchLoaded) {
                    designs = state.searchResults;
                    hasReachedMax = true;
                  } else if (state is DesignsSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (designs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_paint_outlined,
                              size: 64.sp,
                              color: const Color(0xFFCCCCDD)),
                          SizedBox(height: 16.h),
                          Text(
                            'لا توجد تصاميم متاحة',
                            style: TextStyle(
                              fontSize: 18.sp,
                              color: const Color(0xFFAAAABB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _searchController.clear();
                      await context
                          .read<DesignsCubit>()
                          .fetchDesigns(isRefresh: true);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: designs.length + (hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= designs.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final design = designs[index];
                        return DesignCard(
                          design: design,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: _cubit,
                                child: EditDesignScreen(design: design),
                              ),
                            ),
                          ),
                          onDelete: () => _showDeleteConfirm(context, design.id),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DesignDetailsScreen(design: design),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Text('حذف التصميم',
            style: TextStyle(
                fontSize: 18.sp, fontWeight: FontWeight.w800)),
        content: Text(
          'هل أنت متأكد من مسح هذا التصميم بجميع صوره؟',
          style: TextStyle(fontSize: 15.sp, color: const Color(0xFF555566)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: TextStyle(
                    fontSize: 14.sp, color: const Color(0xFF888899))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r)),
            ),
            onPressed: () {
              _cubit.removeDesign(id);
              Navigator.pop(ctx);
            },
            child: Text('حذف', style: TextStyle(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
}
