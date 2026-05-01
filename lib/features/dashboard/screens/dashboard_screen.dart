import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    final monthStr = '${months[now.month - 1]} ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(32.w, 32.h, 32.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // التاريخ الحالي
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFEAEAF0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18.sp, color: AppColors.brandPrimary),
                      SizedBox(width: 8.w),
                      Text(
                        monthStr,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF333344),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // ─── العنوان الكبير ───
            Text(
              'لوحة القيادة الرئيسية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A2E),
                height: 1.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'مرحباً بك مجدداً، إليك نظرة عامة على أداء محفظتك اليوم.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFFAAAABB),
              ),
            ),

            SizedBox(height: 36.h),

            // ─── 4 بطاقات الإحصائيات ───
            Row(
              children: [
                Expanded(child: _StatCard(
                  title: 'إجمالي العملاء المحتملين',
                  value: '1,284',
                  trend: '+12%',
                  trendUp: true,
                  icon: Icons.people_outline_rounded,
                  iconColor: AppColors.brandPrimary,
                  iconBg: AppColors.brandPrimary.withValues(alpha: 0.1),
                )),
                SizedBox(width: 16.w),
                Expanded(child: _StatCard(
                  title: 'إجمالي المبيعات المغلقة',
                  value: '342',
                  trend: '+8.5%',
                  trendUp: true,
                  icon: Icons.handshake_outlined,
                  iconColor: const Color(0xFF10B981),
                  iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
                )),
                SizedBox(width: 16.w),
                Expanded(child: _StatCard(
                  title: 'العقارات النشطة',
                  value: '89',
                  trend: '0%',
                  trendUp: null,
                  icon: Icons.home_work_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  iconBg: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                )),
                SizedBox(width: 16.w),
                Expanded(child: _StatCard(
                  title: 'الإيرادات (الشهر الحالي)',
                  value: '\$4.2M',
                  trend: '+24%',
                  trendUp: true,
                  icon: Icons.attach_money_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                )),
              ],
            ),

            SizedBox(height: 24.h),

            // ─── مخطط الاتجاهات ───
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFEAEAF0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle أسبوعي / شهري
                      Row(
                        children: [
                          _ToggleChip(label: 'أسبوعي', isActive: true),
                          SizedBox(width: 8.w),
                          _ToggleChip(label: 'شهري', isActive: false),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'اتجاهات المبيعات',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            'مقارنة الربع الثالث بالربع الرابع',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFFAAAABB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  // رسم بياني مبسط
                  SizedBox(
                    height: 200.h,
                    child: CustomPaint(
                      painter: _LineChartPainter(),
                      size: Size.infinite,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // محاور الوقت
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['يناير', 'مارس', 'مايو', 'يوليو', 'سبتمبر', 'نوفمبر']
                        .map((m) => Text(m,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFFBBBBCC),
                            )))
                        .toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // ─── الأنشطة الأخيرة ───
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFEAEAF0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back_ios_new_rounded,
                                size: 13.sp, color: AppColors.brandPrimary),
                            SizedBox(width: 4.w),
                            Text('عرض الكل',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      Text(
                        'الأنشطة الأخيرة',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  // رأس الجدول
                  _TableHeader(),
                  const Divider(color: Color(0xFFF0F0F6)),
                  // صفوف البيانات
                  _ActivityRow(
                    clientName: 'أحمد محمود',
                    property: 'فيلا بالم جروف',
                    activity: 'جولة مشاهدة',
                    date: 'اليوم، 10:30ص',
                    status: 'مكتمل',
                    statusColor: const Color(0xFF10B981),
                  ),
                  _ActivityRow(
                    clientName: 'سارة الكواري',
                    property: 'شقة مارينا فيو',
                    activity: 'توقيع عقد',
                    date: 'أمس، 02:15م',
                    status: 'قيد الإجراء',
                    statusColor: AppColors.brandPrimary,
                  ),
                  _ActivityRow(
                    clientName: 'عمر الحسن',
                    property: 'برج لوميلا، طبق 42',
                    activity: 'موافقة إدارية',
                    date: '12 أكتوبر، 09:00ص',
                    status: 'معلق',
                    statusColor: const Color(0xFF888899),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── بطاقة إحصائية ───
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool? trendUp;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    final Color trendColor = trendUp == true
        ? const Color(0xFF10B981)
        : trendUp == false
            ? AppColors.brandAccent
            : const Color(0xFF888899);

    final IconData trendIcon = trendUp == true
        ? Icons.trending_up_rounded
        : trendUp == false
            ? Icons.trending_down_rounded
            : Icons.remove_rounded;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEAEAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Trend badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(trendIcon, size: 14.sp, color: trendColor),
                  ],
                ),
              ),
              // Icon
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFFAAAABB),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toggle Chip ───
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _ToggleChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isActive ? AppColors.brandPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : const Color(0xFF888899),
        ),
      ),
    );
  }
}

// ─── Table Header ───
class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Color(0xFFAAAAAA),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('الحالة', textAlign: TextAlign.center, style: style)),
          Expanded(flex: 2, child: Text('التاريخ', textAlign: TextAlign.center, style: style)),
          Expanded(flex: 2, child: Text('النشاط', textAlign: TextAlign.center, style: style)),
          Expanded(flex: 3, child: Text('العقار / العميل', textAlign: TextAlign.right, style: style)),
        ],
      ),
    );
  }
}

// ─── Activity Row ───
class _ActivityRow extends StatelessWidget {
  final String clientName;
  final String property;
  final String activity;
  final String date;
  final String status;
  final Color statusColor;

  const _ActivityRow({
    required this.clientName,
    required this.property,
    required this.activity,
    required this.date,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          // الحالة
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r, height: 6.r,
                      decoration: BoxDecoration(
                        color: statusColor, shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(status,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        )),
                  ],
                ),
              ),
            ),
          ),
          // التاريخ
          Expanded(
            flex: 2,
            child: Text(date,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF777788))),
          ),
          // النشاط
          Expanded(
            flex: 2,
            child: Text(activity,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF333344))),
          ),
          // العقار / العميل
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(property,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        )),
                    Text(clientName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFAAAAAA),
                        )),
                  ],
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.person_rounded,
                      size: 20.sp, color: AppColors.brandPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Line Chart Painter ───
class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [0.8, 0.6, 0.75, 0.5, 0.65, 0.4, 0.55, 0.3, 0.45, 0.2, 0.35, 0.15];
    final w = size.width;
    final h = size.height;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * w;
      final y = h - (points[i] * h * 0.85) - h * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        final prevX = ((i - 1) / (points.length - 1)) * w;
        final prevY = h - (points[i - 1] * h * 0.85) - h * 0.05;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.close();

    // Fill gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.brandPrimary.withValues(alpha: 0.25),
        AppColors.brandPrimary.withValues(alpha: 0.0),
      ],
    );
    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.brandPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Dots at key points
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = AppColors.brandPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 3; i < points.length; i += 4) {
      final x = (i / (points.length - 1)) * w;
      final y = h - (points[i] * h * 0.85) - h * 0.05;
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => false;
}
