import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/lead_model.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/property_image_model.dart';
import '../../../core/utils/number_formatter.dart';
import '../../properties/cubit/properties_cubit.dart';
import '../../properties/cubit/properties_state.dart';
import '../../../core/di/injection_container.dart' as di;

class SmartMatchScreen extends StatefulWidget {
  final LeadModel lead;
  final ProfileModel currentUser;

  const SmartMatchScreen({
    super.key,
    required this.lead,
    required this.currentUser,
  });

  @override
  State<SmartMatchScreen> createState() => _SmartMatchScreenState();
}

class _SmartMatchScreenState extends State<SmartMatchScreen> {
  late PropertiesCubit _cubit;
  final dataManager = di.sl<StaticDataManager>();
  int _visibleCount = 3;

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

    num? minPrice = lead.budgetFrom;
    num? maxPrice = lead.budgetTo;
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      final temp = minPrice;
      minPrice = maxPrice;
      maxPrice = temp;
    }

    print("=================================================");
    print("🔍 تشغيل مطابقة العقارات للعميل:");
    print("نص طلب العميل: ${lead.descLeadNeed}");
    print("مُعرّف نوع العقار: $propertyTypeId (${lead.propertyType})");
    print("مُعرّف نوع الإعلان: $listingTypeId (${lead.listingType})");
    print("مُعرّف المحافظة: $governorateId (${lead.governorate})");
    print("مُعرّف المدينة: $cityId (${lead.city})");
    print("الميزانية من (المصححة): $minPrice إلى: $maxPrice");
    print("=================================================");

    _cubit.smartSearch(
      lead.descLeadNeed ?? '',
      propertyTypeId: propertyTypeId,
      listingTypeId: listingTypeId,
      governorateId: governorateId,
      cityId: cityId,
      minPrice: minPrice,
      maxPrice: maxPrice,
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
              final displayCount = _visibleCount > allResults.length ? allResults.length : _visibleCount;

              return ListView.separated(
                padding: EdgeInsets.all(20.w),
                itemCount: displayCount + 1, // آخر عنصر هو أزرار المزيد / عرض أقل
                separatorBuilder: (context, index) => SizedBox(height: 16.h),
                itemBuilder: (context, index) {
                  if (index == displayCount) {
                    final hasMoreInCache = allResults.length > _visibleCount;
                    final hasMoreInServer = state.hasMoreSmartSearch;
                    final showMoreButton = hasMoreInCache || hasMoreInServer;
                    final showLessButton = _visibleCount > 3;

                    if (!showMoreButton && !showLessButton) return const SizedBox.shrink();

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showMoreButton)
                            TextButton.icon(
                              onPressed: () async {
                                if (hasMoreInCache) {
                                  setState(() {
                                    _visibleCount += 3;
                                  });
                                } else {
                                  await _cubit.loadMoreSmartSearch();
                                  setState(() {
                                    _visibleCount += 3;
                                  });
                                }
                              },
                              icon: const Icon(Icons.expand_more),
                              label: Text("المزيد", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                            ),
                          if (showMoreButton && showLessButton) SizedBox(width: 24.w),
                          if (showLessButton)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _visibleCount = 3;
                                });
                              },
                              icon: const Icon(Icons.expand_less, color: Colors.red),
                              label: Text("عرض أقل", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.red)),
                            ),
                        ],
                      ),
                    );
                  }

                  final prop = allResults[index];
                  final userId = widget.currentUser.id;
                  final role = widget.currentUser.role;

                  return MatchedPropertyCard(
                    property: prop,
                    currentUserId: userId,
                    role: role,
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

class MatchedPropertyCard extends StatefulWidget {
  final PropertyModel property;
  final String currentUserId;
  final String role;

  const MatchedPropertyCard({
    super.key,
    required this.property,
    required this.currentUserId,
    required this.role,
  });

  @override
  State<MatchedPropertyCard> createState() => _MatchedPropertyCardState();
}

class _MatchedPropertyCardState extends State<MatchedPropertyCard> {
  bool _isDescExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isSales = widget.role == 'sales';
    final bool isOwnProperty = widget.property.createdBy == widget.currentUserId;
    final bool canSeeOwnerPhone = !isSales || isOwnProperty;

    final String? firstImageUrl = widget.property.images.isNotEmpty
        ? widget.property.images.first.thumbnail
        : null;
    final String displayUrl = firstImageUrl ??
        "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.borderSubtle, width: 2),
        ),
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── الجزء الأيمن: باقي التفاصيل والأسعار والأزرار (60% من المساحة) ───
              Expanded(
                flex: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // السعر وكود العقار والمسؤول وبيانات المالك
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // اليمين: الكود والمسؤول
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: SelectableText(
                                widget.property.propertyCode ?? 'بدون كود',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Text(
                              "المسؤول: ${widget.property.createdByName ?? 'غير محدد'}",
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        // اليسار: السعر وبيانات المالك تحته مباشرة
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${widget.property.price.toCurrency()} ج.م',
                              style: TextStyle(
                                fontSize: 34.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            // بيانات المالك
                            if (canSeeOwnerPhone) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone_iphone_outlined, size: 22.sp, color: Colors.green.shade700),
                                  SizedBox(width: 6.w),
                                  SelectableText(
                                    widget.property.ownerPhone ?? 'غير متوفر',
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.property.ownerName != null) ...[
                                SizedBox(height: 4.h),
                                Text(
                                  "الاسم: ${widget.property.ownerName}",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ] else ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline, size: 22.sp, color: AppColors.brandAccent),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "المالك: محجوب (لزميل آخر)",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.brandAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // التصنيفات (Chips)
                    Wrap(
                      spacing: 12.w,
                      runSpacing: 10.h,
                      children: [
                        _buildInfoChip(Icons.home_outlined, widget.property.propertyTypeAr, Colors.blue),
                        _buildInfoChip(Icons.campaign_outlined, widget.property.listingTypeAr, Colors.orange),
                        _buildInfoChip(Icons.location_on_outlined, widget.property.cityAr, Colors.red),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    const Divider(color: AppColors.borderSubtle, thickness: 1.5),
                    SizedBox(height: 16.h),

                    // وصف العقار
                    Text(
                      "وصف العقار:",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      widget.property.descAr,
                      maxLines: _isDescExpanded ? null : 3,
                      overflow: _isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (widget.property.descAr.length > 80) ...[
                      SizedBox(height: 8.h),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isDescExpanded = !_isDescExpanded;
                            });
                          },
                          icon: Icon(
                            _isDescExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 24.sp,
                            color: AppColors.brandPrimary,
                          ),
                          label: Text(
                            _isDescExpanded ? "عرض أقل" : "المزيد...",
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 24.w), // مسافة بين العمودين

              // ─── الجزء الأيسر: الصورة المصغرة وزر المشاركة (40% من المساحة) ───
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصورة المصغرة (تم تكبير الارتفاع إلى 320.h)
                    GestureDetector(
                      onTap: () {
                        if (widget.property.images.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => ImageGalleryDialog(images: widget.property.images),
                          );
                        }
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              displayUrl,
                              width: double.infinity,
                              height: 320.h,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 320.h,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.broken_image, size: 40)),
                              ),
                            ),
                          ),
                          if (widget.property.images.isNotEmpty)
                            Positioned(
                              bottom: 12.h,
                              left: 12.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.photo_library_outlined, color: Colors.white, size: 16.sp),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "${widget.property.images.length} صور",
                                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageGalleryDialog extends StatefulWidget {
  final List<PropertyImageModel> images;

  const ImageGalleryDialog({super.key, required this.images});

  @override
  State<ImageGalleryDialog> createState() => _ImageGalleryDialogState();
}

class _ImageGalleryDialogState extends State<ImageGalleryDialog> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const AlertDialog(
        content: Text("لا توجد صور لهذا العقار"),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(10.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imgUrl = widget.images[index].imageUrl;
                return InteractiveViewer(
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 60, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            // زر السهم الأيسر (السابق)
            if (_currentIndex > 0)
              Positioned(
                left: 24.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 44),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            // زر السهم الأيمن (التالي)
            if (_currentIndex < widget.images.length - 1)
              Positioned(
                right: 24.w,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 44),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              ),
            // زر الإغلاق
            Positioned(
              top: 20.h,
              right: 20.w,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // العداد
            Positioned(
              bottom: 20.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "${_currentIndex + 1} / ${widget.images.length}",
                  style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
