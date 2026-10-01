import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/repositories/lead_repository.dart';

/// كارت إحصائيات التواصل والفيدباك للشهر الحالي
/// يعرض: إجمالي عملاء الشهر، تم كتابة تعليق (فيدباك)، بدون تعليق، المتبقي، مع زر تحديث خاص بهذه القيم فقط
class MonthlyLeadsFeedbackCard extends StatefulWidget {
  final String role;
  final String userId;
  final String? employeeId;
  final String? employeeName;

  const MonthlyLeadsFeedbackCard({
    super.key,
    required this.role,
    required this.userId,
    this.employeeId,
    this.employeeName,
  });

  @override
  State<MonthlyLeadsFeedbackCard> createState() => _MonthlyLeadsFeedbackCardState();
}

class _MonthlyLeadsFeedbackCardState extends State<MonthlyLeadsFeedbackCard> {
  final _leadRepository = di.sl<LeadRepository>();

  bool _isLoading = true;
  int _total = 0;
  int _withFeedback = 0;
  int _withoutFeedback = 0;
  int _remaining = 0;

  static const _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  String get _currentMonthName {
    final now = DateTime.now();
    return '${_monthsAr[now.month - 1]} ${now.year}';
  }

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void didUpdateWidget(covariant MonthlyLeadsFeedbackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.employeeId != widget.employeeId ||
        oldWidget.userId != widget.userId ||
        oldWidget.role != widget.role) {
      _fetchStats();
    }
  }

  Future<void> _fetchStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final stats = await _leadRepository.getMonthlyFeedbackStats(
        role: widget.role,
        userId: widget.userId,
        employeeId: widget.employeeId,
      );

      if (mounted) {
        setState(() {
          _total = stats['total'] ?? 0;
          _withFeedback = stats['with_feedback'] ?? 0;
          _withoutFeedback = stats['without_feedback'] ?? 0;
          _remaining = stats['remaining'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double completionRate = _total > 0 ? (_withFeedback / _total) * 100 : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: العنوان + زر التحديث الخاص ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // العنوان
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.mark_chat_unread_rounded,
                        color: AppColors.brandPrimary,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'متابعة عملاء الشهر الحالي',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  _currentMonthName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandPrimary,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            widget.employeeName != null
                                ? 'إحصائيات المتابعة والفيدباك للموظف: ${widget.employeeName}'
                                : 'متابعة العملاء الذين تم تسجيل فيدباك لهم مقارنة بالعملاء المتبقين',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: const Color(0xFF6B7280),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // زر التحديث الخاص بهذه القيم فقط
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoading ? null : _fetchStats,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoading
                            ? SizedBox(
                                width: 16.sp,
                                height: 16.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.brandPrimary,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 18.sp,
                                color: AppColors.brandPrimary,
                              ),
                        SizedBox(width: 6.w),
                        Text(
                          'تحديث الأرقام',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // ─── كروت المؤشرات الأربعة ───
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 650;
              if (isNarrow) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            title: 'عملاء هذا الشهر',
                            value: '$_total',
                            subtitle: 'إجمالي المضافين',
                            icon: Icons.groups_rounded,
                            color: AppColors.brandPrimary,
                            bgColor: const Color(0xFFEFF6FF),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildStatTile(
                            title: 'تم كتابة فيدباك',
                            value: '$_withFeedback',
                            subtitle: 'تم تسجيل تعليق',
                            icon: Icons.mark_chat_read_rounded,
                            color: const Color(0xFF10B981),
                            bgColor: const Color(0xFFECFDF5),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            title: 'بدون تعليق',
                            value: '$_withoutFeedback',
                            subtitle: 'لم يسجل فيدباك',
                            icon: Icons.mark_chat_unread_rounded,
                            color: const Color(0xFFF59E0B),
                            bgColor: const Color(0xFFFFFBEB),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _buildStatTile(
                            title: 'المتبقي للمتابعة',
                            value: '$_remaining',
                            subtitle: 'مطلوب التواصل',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEF2F2),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                      title: 'عملاء هذا الشهر',
                      value: '$_total',
                      subtitle: 'إجمالي عملاء الشهر',
                      icon: Icons.groups_rounded,
                      color: AppColors.brandPrimary,
                      bgColor: const Color(0xFFEFF6FF),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatTile(
                      title: 'تم كتابة فيدباك',
                      value: '$_withFeedback',
                      subtitle: 'تم تسجيل تعليق لهم',
                      icon: Icons.mark_chat_read_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFECFDF5),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatTile(
                      title: 'بدون تعليق حتى الآن',
                      value: '$_withoutFeedback',
                      subtitle: 'لم يتم كتابة تعليق بعد',
                      icon: Icons.mark_chat_unread_rounded,
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFFFBEB),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildStatTile(
                      title: 'المتبقي للمتابعة',
                      value: '$_remaining',
                      subtitle: 'مطلوب التواصل معهم',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
                    ),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 16.h),

          // ─── شريط نسبة إنجاز التواصل ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'نسبة التواصل وإنجاز الفيدباك',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF374151),
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '${completionRate.toStringAsFixed(1)}% (${_withFeedback} من ${_total})',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: completionRate >= 50
                                  ? const Color(0xFF10B981)
                                  : (completionRate > 0
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444)),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.r),
                        child: LinearProgressIndicator(
                          value: _total > 0 ? (_withFeedback / _total).clamp(0.0, 1.0) : 0.0,
                          minHeight: 8.h,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completionRate >= 80
                                ? const Color(0xFF10B981)
                                : (completionRate >= 40
                                    ? AppColors.brandPrimary
                                    : const Color(0xFFF59E0B)),
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
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B5563),
                  fontFamily: 'Cairo',
                ),
              ),
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          _isLoading
              ? SizedBox(
                  height: 28.sp,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 18.sp,
                      height: 18.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontFamily: 'Cairo',
                    height: 1.1,
                  ),
                ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: const Color(0xFF6B7280),
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
