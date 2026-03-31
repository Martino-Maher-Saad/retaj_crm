import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/property_model.dart';

/// بطاقة المعلومات الرئيسية للعقار — تظهر مباشرة أسفل معرض الصور
/// تحتوي على: gradient header أزرق + نوع العقار badge + السعر الضخم + العنوان
class PropertyMainInfoCard extends StatelessWidget {
  final PropertyModel property;

  const PropertyMainInfoCard({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final bool isRent = property.listingTypeAr?.toLowerCase() == 'rent';
    // لو العقار نشط = أخضر، لو مغلق = رمادي
    final bool isActive = property.status;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Gradient — نوع العقار + حالة النشر ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.75),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ─── badge نوع العقار ───
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Text(
                    "${property.listingTypeAr} · ${property.propertyTypeAr}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // ─── badge حالة النشر (نشط / مغلق) ───
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.visibility : Icons.visibility_off,
                        size: 12.sp,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isActive ? "نشط" : "مغلق",
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.grey,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Body المحتوى: السعر والعنوان ───
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // السعر بخط ضخم بارز
                Text(
                  "${property.price?.toStringAsFixed(0) ?? '---'} EGP",
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                  ),
                ),

                // دورية الإيجار تحت السعر مباشرة
                if (isRent && property.rentalFrequency != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.repeat, size: 14.sp, color: Colors.orange),
                      SizedBox(width: 4.w),
                      Text(
                        "دورية الدفع: ${property.rentalFrequency}",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 12.h),

                // خط فاصل
                Divider(color: Colors.grey.shade100, height: 1),

                SizedBox(height: 12.h),

                // عنوان العقار
                Text(
                  property.titleAr ?? '',
                  style: AppTextStyles.blue16Bold.copyWith(
                    color: Colors.black87,
                    fontSize: 15.sp,
                  ),
                ),

                SizedBox(height: 8.h),

                // ID مرجعي في الأسفل
                Row(
                  children: [
                    Icon(Icons.tag, size: 13.sp, color: Colors.grey),
                    SizedBox(width: 4.w),
                    Text(
                      "ID: ${property.id.substring(0, 8)}",
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
