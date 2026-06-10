import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/lead_model.dart';
import '../../properties/cubit/properties_cubit.dart';
import '../../properties/cubit/properties_state.dart';
import '../../properties/widgets/property_card.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
import '../../../core/di/injection_container.dart' as di;

class SmartMatchScreen extends StatefulWidget {
  final LeadModel lead;

  const SmartMatchScreen({super.key, required this.lead});

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen> {
  late PropertiesCubit _cubit;
  final dataManager = di.sl<StaticDataManager>();
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _cubit = di.sl<PropertiesCubit>();
    _triggerSearch();
  }

  void _triggerSearch() {
    final lead = widget.lead;

    // استخراج IDs للفلاتر إذا كانت موجودة وغير فارغة
    String? propertyTypeId;
    if (lead.propertyType != null && lead.propertyType!.isNotEmpty) {
      propertyTypeId = dataManager.getIdByName('property_type', lead.propertyType!);
    }

    String? listingTypeId;
    if (lead.listingType != null && lead.listingType!.isNotEmpty) {
      listingTypeId = dataManager.getIdByName('listing_type', lead.listingType!);
    }

    int? governorateId;
    if (lead.governorate != null && lead.governorate!.isNotEmpty) {
      try {
        governorateId = dataManager.governorates.firstWhere((g) => g.name == lead.governorate).id;
      } catch (_) {}
    }

    int? cityId;
    if (governorateId != null && lead.city != null && lead.city!.isNotEmpty) {
      try {
        cityId = dataManager.getCitiesByGovId(governorateId).firstWhere((c) => c.name == lead.city).id;
      } catch (_) {}
    }

    _cubit.smartSearch(
      lead.descLeadNeed ?? '',
      propertyTypeId: propertyTypeId,
      listingTypeId: listingTypeId,
      governorateId: governorateId,
      cityId: cityId,
      minPrice: lead.budgetFrom,
      maxPrice: lead.budgetTo,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.bgMain,
        appBar: AppBar(
          title: Text('نتائج البحث الذكي 🪄', style: AppTextStyles.h2),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.brandPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<PropertiesCubit, PropertiesState>(
          builder: (context, state) {
            if (state is PropertiesLoading) {
              return _buildSkeleton();
            } else if (state is PropertiesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(state.message, style: TextStyle(fontSize: 16.sp, color: Colors.red)),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _triggerSearch,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            } else if (state is PropertiesSuccess) {
              if (state.searchedProperties.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 80.sp, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text("لم يتم العثور على عقارات مطابقة لوصف العميل",
                          style: TextStyle(fontSize: 18.sp, color: Colors.grey[700])),
                    ],
                  ),
                );
              }

              final allResults = state.searchedProperties;
              final displayCount = _showAll ? allResults.length : (allResults.length > 3 ? 3 : allResults.length);

              return ListView.separated(
                padding: EdgeInsets.all(20.w),
                itemCount: displayCount + (_showAll == false && allResults.length > 3 ? 1 : 0),
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  if (index == displayCount && !_showAll) {
                    return TextButton(
                      onPressed: () => setState(() => _showAll = true),
                      child: Text("عرض المزيد (${allResults.length - 3})", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    );
                  }

                  final prop = allResults[index];
                  final profileState = context.read<ProfileCubit>().state;
                  final userId = profileState is ProfileLoaded ? profileState.profile.id : '';
                  final role = profileState is ProfileLoaded ? profileState.profile.role : '';

                  return Column(
                    children: [
                      PropertyCard(
                        property: prop,
                        currentUserId: userId,
                        role: role,
                        onEdit: () {},
                        onDelete: () {},
                        onTap: () {
                          // TODO: Navigate to Property details
                        },
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Internal Share action
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text("مشاركة العقار مع العميل"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandPrimary,
                            side: const BorderSide(color: AppColors.brandPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: EdgeInsets.all(20.w),
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(height: 16.h),
        itemBuilder: (_, __) {
          return Container(
            height: 140.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          );
        },
      ),
    );
  }
}
