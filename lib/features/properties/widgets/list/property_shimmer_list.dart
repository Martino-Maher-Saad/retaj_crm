import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// قائمة تحميل وهمية (Skeleton Loading) تظهر أثناء جلب بيانات العقارات
/// تعطي المستخدم إحساساً بأن المحتوى على وشك الظهور بدلاً من شاشة بيضاء
class PropertyShimmerList extends StatelessWidget {
  const PropertyShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      // 5 عناصر وهمية كافية لملء الشاشة
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        // تدرج من رمادي فاتح لأبيض يعطي تأثير اللمعان
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: EdgeInsets.only(bottom: 15.h),
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
