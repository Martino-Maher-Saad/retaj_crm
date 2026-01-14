import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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
    // استخدام الـ Thumbnail لتقليل استهلاك البيانات
    final String thumbnailUrl = property.images.isNotEmpty
        ? property.getThumbnailUrl(property.images.first)
        : "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
              // 1. الصورة مع Badge الحالة
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: 140.w,
                      height: 110.h,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.greyLight),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: _buildStatusBadge(),
                  ),
                ],
              ),
              SizedBox(width: 16.w),

              // 2. تفاصيل العقار (الوسط)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "ID: #${property.id.substring(0, 5)}",
                          style: AppTextStyles.tableCellSub.copyWith(fontSize: 11.sp),
                        ),
                        Text(
                          property.type, // Sale / Rent
                          style: AppTextStyles.blue16Bold.copyWith(fontSize: 12.sp, color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "${property.price.toStringAsFixed(0)} EGP",
                      style: AppTextStyles.blue20Medium.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlueDark,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14.sp, color: AppColors.greyDark),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            "${property.city} - ${property.locationAr}",
                            style: AppTextStyles.tableCellSub.copyWith(fontSize: 12.sp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildFeaturesRow(),
                  ],
                ),
              ),

              // 3. أزرار التحكم
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_note, color: AppColors.primaryBlue, size: 24.sp),
                    onPressed: onEdit,
                    tooltip: "Edit",
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 24.sp),
                    onPressed: onDelete,
                    tooltip: "Delete",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: property.isAvailable ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        property.isAvailable ? "Available" : "Closed",
        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFeaturesRow() {
    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: [
        _featureIcon(Icons.king_bed_outlined, "${property.rooms}"),
        _featureIcon(Icons.bathtub_outlined, "${property.baths}"),
        _featureIcon(Icons.square_foot_outlined, "${property.area}m²"),
        _featureIcon(Icons.layers_outlined, "F:${property.floor}"),
      ],
    );
  }

  Widget _featureIcon(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: AppColors.greyDark),
        SizedBox(width: 4.w),
        Text(label, style: AppTextStyles.tableCellSub.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }
}