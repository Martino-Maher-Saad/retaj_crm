import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/designs_cubit.dart';
import '../widgets/design_card.dart';
import '../widgets/design_inline_form.dart';
import '../../../data/models/profile_model.dart';

class DesignsScreen extends StatefulWidget {
  final ProfileModel user;

  const DesignsScreen({super.key, required this.user});

  @override
  State<DesignsScreen> createState() => _DesignsScreenState();
}

class _DesignsScreenState extends State<DesignsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final _dataManager = di.sl<StaticDataManager>();

  String? _selectedRoomType;
  String? _selectedStyle;
  String? _selectedEmployeeId;
  bool _isAddingNew = false; // صلاحية الإضافة المضمنةج للإضافة

  @override
  void initState() {
    super.initState();
    _loadDesigns();
    _scrollController.addListener(_onScroll);
  }

  void _loadDesigns({bool refresh = false}) {
    context.read<DesignsCubit>().fetchDesigns(
      refresh: refresh,
      roomTypeId: _selectedRoomType != null ? _dataManager.getIdByName('design_room_types', _selectedRoomType!) : null,
      styleId: _selectedStyle != null ? _dataManager.getIdByName('design_styles', _selectedStyle!) : null,
      addedByProfileId: _selectedEmployeeId,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadDesigns();
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    context.read<DesignsCubit>().searchDesigns(
      query,
      roomTypeId: _selectedRoomType != null ? _dataManager.getIdByName('design_room_types', _selectedRoomType!) : null,
      styleId: _selectedStyle != null ? _dataManager.getIdByName('design_styles', _selectedStyle!) : null,
      addedByProfileId: _selectedEmployeeId,
    );
  }

  void _showFiltersModal() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24.h, left: 24.w, right: 24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('فلاتر متقدمة', style: AppTextStyles.h2, textAlign: TextAlign.center),
                    SizedBox(height: 24.h),
                    DropdownMenu<String?>(
                      initialSelection: _selectedRoomType,
                      expandedInsets: EdgeInsets.zero,
                      enableSearch: true,
                      enableFilter: true,
                      menuHeight: 200,
                      label: const Text('نوع الغرفة'),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: null, label: 'الكل'),
                        ..._dataManager.getOptions('design_room_types').map((e) => DropdownMenuEntry(value: e, label: e)),
                      ],
                      onSelected: (val) => setModalState(() => _selectedRoomType = val),
                    ),
                    SizedBox(height: 16.h),
                    DropdownMenu<String?>(
                      initialSelection: _selectedStyle,
                      expandedInsets: EdgeInsets.zero,
                      enableSearch: true,
                      enableFilter: true,
                      menuHeight: 200,
                      label: const Text('الستايل'),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: null, label: 'الكل'),
                        ..._dataManager.getOptions('design_styles').map((e) => DropdownMenuEntry(value: e, label: e)),
                      ],
                      onSelected: (val) => setModalState(() => _selectedStyle = val),
                    ),
                    SizedBox(height: 16.h),
                    DropdownMenu<String?>(
                      initialSelection: _selectedEmployeeId,
                      expandedInsets: EdgeInsets.zero,
                      enableSearch: true,
                      enableFilter: true,
                      menuHeight: 200,
                      label: const Text('الموظف'),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: null, label: 'الكل'),
                        ..._dataManager.employees.map((e) => DropdownMenuEntry(value: e.id, label: '${e.firstName} ${e.lastName}')),
                      ],
                      onSelected: (val) => setModalState(() => _selectedEmployeeId = val),
                    ),
                  SizedBox(height: 32.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Update the main UI
                            Navigator.pop(context);
                            _loadDesigns(refresh: true);
                          },
                          child: const Text('تطبيق الفلاتر'),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedRoomType = null;
                              _selectedStyle = null;
                              _selectedEmployeeId = null;
                            });
                            Navigator.pop(context);
                            _loadDesigns(refresh: true);
                          },
                          child: const Text('إلغاء الفلاتر'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ));
          },
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // صلاحية الإضافة والتعديل متاحة لأي موظف مسجل
    final canEdit = true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Text('معرض التشطيبات', style: AppTextStyles.h3),
            SizedBox(width: 32.w),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث (مثال: غرفة نوم كلاسيك)...',
                        prefixIcon: const Icon(Icons.auto_awesome, color: Colors.amber),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: AppColors.brandPrimary),
                          onPressed: _performSearch,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton.icon(
                    onPressed: _showFiltersModal,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('فلاتر متقدمة'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (canEdit && !_isAddingNew)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _isAddingNew = true),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('إضافة تشطيب', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<DesignsCubit, DesignsState>(
              builder: (context, state) {
                if (state is DesignsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is DesignsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 16.h),
                        Text(state.message, style: AppTextStyles.bodyMain),
                        TextButton(
                          onPressed: () => _loadDesigns(refresh: true),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DesignsLoading && context.read<DesignsCubit>().state is! DesignsLoaded) {
                  return ListView.builder(
                    cacheExtent: 3000,
                    padding: EdgeInsets.all(16.w),
                    itemCount: 3,
                    itemBuilder: (_, __) => Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Card(child: SizedBox(height: 100.h)),
                    ),
                  );
                }

                final loadedState = state as DesignsLoaded;
                final designs = loadedState.designs;

                return ListView.builder(
                  cacheExtent: 3000,
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.w),
                  itemCount: designs.length + (_isAddingNew ? 1 : 0) + (loadedState.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    
                    // الكارت المدمج للإضافة يظهر في البداية
                    if (_isAddingNew && index == 0) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: DesignInlineForm(
                          onCancel: () => setState(() => _isAddingNew = false),
                          onSuccess: (newDesign) {
                            setState(() => _isAddingNew = false);
                            context.read<DesignsCubit>().addDesignLocally(newDesign);
                          },
                        ),
                      );
                    }

                    final dataIndex = _isAddingNew ? index - 1 : index;

                    if (dataIndex >= designs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: DesignCard(
                        design: designs[dataIndex],
                        canEdit: canEdit,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
