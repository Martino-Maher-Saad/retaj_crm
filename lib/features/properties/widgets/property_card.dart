import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/property_cache_manager.dart';
import '../../../data/models/property_model.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. استخراج رابط الصورة من الكائن PropertyImageModel
    final String? firstImageUrl = (property.images != null && property.images!.isNotEmpty)
        ? property.images!.first.imageUrl // نصل هنا لحقل الـ imageUrl داخل الموديل
        : null;

// 2. استخدام الرابط الافتراضي
    final String displayUrl = firstImageUrl ?? "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";
    // 2. تحديد الدورية السعرية (إيجار/بيع)
    bool isRent = property.listingTypeEn?.toLowerCase() == 'rent';
    String priceSuffix = isRent ? " / ${property.rentalFrequency ?? 'M'}" : "";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- القسم الأيسر: الصورة والتاجات ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: CachedNetworkImage(
                      cacheManager: PropertyCacheManager.instance,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      useOldImageOnUrlChange: true,
                      imageUrl: displayUrl,
                      width: 135.w,
                      height: 115.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 6.h,
                    right: 6.w, // يمين لأننا في سياق عربي
                    child: _buildStatusBadge(),
                  ),
                ],
              ),
              SizedBox(width: 14.w),

              // --- القسم الأوسط: البيانات الأساسية ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${property.listingTypeAr} - ${property.unitTypeAr}",
                          style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                        Text(
                          "ID: #${property.id.length > 4 ? property.id.substring(property.id.length - 4) : property.id}",
                          style: AppTextStyles.tableCellSub.copyWith(fontSize: 9.sp),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${property.price?.toStringAsFixed(0) ?? '0'} EGP$priceSuffix",
                      style: AppTextStyles.blue20Medium.copyWith(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlueDark,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14.sp, color: Colors.redAccent),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            "${property.cityAr} - ${property.regionAr}",
                            style: AppTextStyles.tableCellSub.copyWith(fontSize: 12.sp, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    _buildFeaturesRow(),
                  ],
                ),
              ),

              // --- القسم الأيمن: أزرار التحكم ---
              SizedBox(width: 8.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _actionButton(Icons.edit_note_rounded, AppColors.primaryBlue, onEdit),
                  SizedBox(height: 12.h),
                  _actionButton(Icons.delete_outline_rounded, Colors.redAccent, onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets المساعدة ---

  Widget _actionButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Icon(icon, color: color, size: 24.sp),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool available = property.status; // الحقل الجديد status (bool)
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: available ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Text(
        available ? "نشط" : "مغلق",
        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFeaturesRow() {
    return Row(
      children: [
        _featureIcon(Icons.king_bed_outlined, "${property.bedrooms ?? 0}"),
        SizedBox(width: 12.w),
        _featureIcon(Icons.bathtub_outlined, "${property.bathrooms ?? 0}"),
        SizedBox(width: 12.w),
        _featureIcon(Icons.straighten_rounded, "${property.builtArea ?? 0}م²"),
      ],
    );
  }

  Widget _featureIcon(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.primaryBlueDark),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 11.sp, color: AppColors.primaryBlueDark, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}