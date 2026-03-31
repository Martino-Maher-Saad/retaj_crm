import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

/// مؤشر تقدم العميل في pipeline المبيعات
/// يعرض شريط أفقي يوضح مرحلة العميل الحالية من: جديد → تواصل → تفاوض → عقد
/// يُستخدم في lead_details_screen مباشرة أسفل LeadHeaderCard
class LeadPipelineIndicator extends StatelessWidget {
  final String currentStatus;

  const LeadPipelineIndicator({super.key, required this.currentStatus});

  // ترتيب المراحل في الـ pipeline
  static const List<_PipelineStep> _steps = [
    _PipelineStep(label: "جديد",         icon: Icons.fiber_new_rounded),
    _PipelineStep(label: "تم التواصل",   icon: Icons.phone_in_talk_outlined),
    _PipelineStep(label: "تفاوض",        icon: Icons.handshake_outlined),
    _PipelineStep(label: "تم التعاقد",   icon: Icons.task_alt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    // لو مستبعد نُظهر حالة خاصة منفصلة
    if (currentStatus == 'مستبعد') return _buildExcludedState();

    // البحث عن index المرحلة الحالية
    final int currentIndex = _steps.indexWhere((s) => s.label == currentStatus);
    final int resolvedIndex = currentIndex == -1 ? 0 : currentIndex;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── عنوان الـ section ───
          Row(
            children: [
              Icon(Icons.timeline, size: 16.sp, color: AppColors.brandPrimary),
              SizedBox(width: 6.w),
              Text(
                "مسار العميل",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ─── الـ steps المرتبة أفقياً ───
          Row(
            children: _steps.asMap().entries.map((entry) {
              final int index = entry.key;
              final _PipelineStep step = entry.value;
              final bool isDone = index <= resolvedIndex;
              final bool isCurrent = index == resolvedIndex;

              return Expanded(
                child: Row(
                  children: [
                    // الـ step نفسه
                    Expanded(
                      child: Column(
                        children: [
                          // دائرة الـ step مع icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? AppColors.brandPrimary
                                  : Colors.grey.shade100,
                              border: isCurrent
                                  ? Border.all(
                                      color: AppColors.brandPrimary,
                                      width: 2.5,
                                    )
                                  : null,
                              boxShadow: isCurrent
                                  ? [BoxShadow(color: AppColors.brandPrimary.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                step.icon,
                                size: 16.sp,
                                color: isDone ? Colors.white : Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          // تسمية الـ step
                          Text(
                            step.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9.5.sp,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent
                                  ? AppColors.brandPrimary
                                  : isDone
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // خط اتصال بين الـ steps (إلا الأخير)
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2.h,
                          margin: EdgeInsets.only(bottom: 22.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: index < resolvedIndex
                                  ? [AppColors.brandPrimary, AppColors.brandPrimary]
                                  : [Colors.grey.shade200, Colors.grey.shade200],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// حالة خاصة للعملاء المستبعدين — تظهر badge أحمر واضح
  Widget _buildExcludedState() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.brandAccent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.brandAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.brandAccent, size: 20.sp),
          SizedBox(width: 10.w),
          Text(
            "هذا العميل مستبعد حالياً من الـ pipeline",
            style: TextStyle(
              color: AppColors.brandAccent,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Step واحد في الـ pipeline
class _PipelineStep {
  final String label;
  final IconData icon;
  const _PipelineStep({required this.label, required this.icon});
}
