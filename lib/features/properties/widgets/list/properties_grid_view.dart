import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/property_model.dart';
import 'package:intl/intl.dart';

class PropertiesGridView extends StatelessWidget {
  final List<PropertyModel> properties;
  final Function(PropertyModel) onTap;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const PropertiesGridView({
    super.key,
    required this.properties,
    required this.onTap,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16.w),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300.w,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.w,
            ),
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return _buildGridCard(property);
            },
          ),
        ),
        if (isLoadingMore)
          Padding(
            padding: EdgeInsets.all(16.h),
            child: const CircularProgressIndicator(),
          )
        else if (hasMore)
          Padding(
            padding: EdgeInsets.all(16.h),
            child: TextButton(
              onPressed: onLoadMore,
              child: const Text('تحميل المزيد من العقارات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildGridCard(PropertyModel property) {
    final image = property.images.isNotEmpty ? property.images.first.imageUrl : null;
    
    return InkWell(
      onTap: () => onTap(property),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image != null && image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                  if (property.listingTypeAr.isNotEmpty)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          property.listingTypeAr,
                          style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (property.isPinned)
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.push_pin, color: Colors.white, size: 14.sp),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      property.titleAr,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14.sp, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            property.cityAr,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      NumberFormat.currency(symbol: 'ج.م ', decimalDigits: 0).format(property.price),
                      style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(Icons.home_work, color: Colors.grey.shade300, size: 40.sp),
      ),
    );
  }
}
