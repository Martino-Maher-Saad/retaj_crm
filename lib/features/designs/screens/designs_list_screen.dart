import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../cubit/designs_cubit.dart';
import '../cubit/designs_state.dart';
import 'add_design_screen.dart';
import 'design_details_screen.dart';
import 'edit_design_screen.dart';
import '../widgets/design_card.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/design_repository.dart';
import '../../../data/services/design_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/ai_service.dart';

class DesignsListScreen extends StatefulWidget {
  const DesignsListScreen({super.key});

  @override
  State<DesignsListScreen> createState() => _DesignsListScreenState();
}

class _DesignsListScreenState extends State<DesignsListScreen> {
  late DesignsCubit _cubit;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = DesignsCubit(
      DesignRepository(
        DesignService(),
        StorageService(Supabase.instance.client),
        AiService(),
      ),
    );
    _scrollController.addListener(_onScroll);
    _cubit.fetchDesigns(isRefresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("قائمة التصميمات", style: AppTextStyles.blue16Bold),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SizedBox(
              width: 300.w,
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearch,
                decoration: InputDecoration(
                  hintText: 'بحث ذكي عن تصميم...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.brandPrimary),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: _cubit,
                child: const AddDesignScreen(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.brandPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: BlocBuilder<DesignsCubit, DesignsState>(
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
            hasReachedMax = true; // Search view implies not paginated
          } else if (state is DesignsSearching) {
             return const Center(child: CircularProgressIndicator());
          }

          if (designs.isEmpty) {
            return Center(
              child: Text(
                "لا توجد تصميمات متاحة",
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _searchController.clear();
              await context.read<DesignsCubit>().fetchDesigns(isRefresh: true);
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              itemCount: designs.length + (hasReachedMax ? 0 : 1),
              itemBuilder: (context, index) {
                if (index >= designs.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final design = designs[index];
                return DesignCard(
                  design: design,
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: _cubit,
                          child: EditDesignScreen(design: design),
                        ),
                      ),
                    );
                  },
                  onDelete: () {
                    _showDeleteConfirm(context, design.id);
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DesignDetailsScreen(design: design),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("حذف التصميم"),
        content: const Text("هل أنت متأكد من مسح هذا التصميم بجميع صوره؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              _cubit.removeDesign(id);
              Navigator.pop(ctx);
            },
            child: const Text("تأكيد", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

