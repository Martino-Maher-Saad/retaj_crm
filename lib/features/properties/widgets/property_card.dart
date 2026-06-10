import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/property_cache_manager.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/whatsapp_share_helper.dart';
import '../../../data/models/property_model.dart';
import 'property_share_sheet.dart';

class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final String currentUserId;
  final String role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onShareInternal;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;

  const PropertyCard({
    super.key,
    required this.property,
    required this.currentUserId,
    required this.role,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onRestore,
    this.onShareInternal,
    required this.onTap,
    this.onPinToggle,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final String? firstImageUrl = widget.property.images.isNotEmpty
        ? widget.property.images.first.thumbnail
        : null;
    final String displayUrl = firstImageUrl ??
        "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";

    final bool isMine = widget.property.createdBy == widget.currentUserId;
    final bool isManagerOrAdmin = widget.role == 'manager' || widget.role == 'admin';
    final bool shouldMask = widget.role == 'sales' && !isMine;

    // تنسيق التاريخ
    final String formattedDate = widget.property.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm', 'en').format(widget.property.createdAt!)
        : 'غير محدد';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.01))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: _isHovering
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
            width: _isHovering ? 2.0 : 1.5,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(22.r),
            child: Column(
              children: [
                // ─── Banner تحذير للمبيعات ───
                if (shouldMask)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22.r),
                        topRight: Radius.circular(22.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "هذا العقار يخص زميل مبيعات آخر",
                        style: AppTextStyles.tableCellSub.copyWith(
                          color: AppColors.brandAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── الصورة ───
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: CachedNetworkImage(
                              cacheManager: PropertyCacheManager.instance,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              useOldImageOnUrlChange: true,
                              imageUrl: displayUrl,
                              width: 370.w,
                              height: 250.h,
                              memCacheWidth: 500,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.bgMain,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.bgMain,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textDisabled,
                                  size: 40.sp,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12.h,
                            right: 12.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildStatusBadge(),
                                if (widget.property.approvalStatusName != null) ...[
                                  SizedBox(height: 5.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      widget.property.approvalStatusName!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.property.isPinned)
                            Positioned(
                              top: 12.h,
                              left: 12.w,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: Icon(Icons.push_pin_rounded, color: AppColors.brandPrimary, size: 20.sp),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 20.w),

                      // ─── البيانات الأساسية ───
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    "${widget.property.listingTypeAr} — ${widget.property.propertyTypeAr}",
                                    style: AppTextStyles.tableCellSub.copyWith(
                                      fontSize: 18.sp,
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  "#${widget.property.propertyCode ?? '---'}",
                                  style: AppTextStyles.tableCellSub.copyWith(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              "${widget.property.price.toCurrency()} ج.م",
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 34.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 20.sp, color: AppColors.brandAccent),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    "${widget.property.governorateAr} — ${widget.property.cityAr}",
                                    style: AppTextStyles.tableCellSub.copyWith(
                                      fontSize: 20.sp,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 20.sp, color: AppColors.textSecondary),
                                SizedBox(width: 6.w),
                                Text(
                                  formattedDate,
                                  style: AppTextStyles.tableCellSub.copyWith(
                                    fontSize: 18.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),

                            if (isManagerOrAdmin || shouldMask) ...[
                              SizedBox(height: 12.h),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 20.sp, color: AppColors.info),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "بواسطة: ${widget.property.createdByName ?? '---'}",
                                    style: AppTextStyles.tableCellSub.copyWith(
                                      fontSize: 17.sp,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ─── أزرار التحكم ───
                      SizedBox(width: 14.w),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _actionButton(
                                FontAwesomeIcons.whatsapp,
                                const Color(0xFF25D366),
                                "مشاركة",
                                () => showPropertyShareSheet(context, widget.property, canShareInternal: isMine || isManagerOrAdmin),
                              ),
                              if (widget.onPinToggle != null) ...[
                                SizedBox(height: 14.h),
                                _actionButton(
                                  widget.property.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                  widget.property.isPinned ? AppColors.brandPrimary : Colors.grey,
                                  "تثبيت العقار",
                                  widget.onPinToggle!,
                                ),
                              ],
                              SizedBox(height: 14.h),
                              _actionButton(
                                Icons.download_rounded,
                                AppColors.success,
                                "تحميل الصور",
                                () {
                                  WhatsappShareHelper.downloadImages(context, widget.property);
                                },
                              ),
                              SizedBox(height: 14.h),
                              _actionButton(
                                Icons.copy_all_rounded,
                                Colors.blueAccent,
                                "نسخ التفاصيل",
                                () {
                                  WhatsappShareHelper.copyToClipboard(context, widget.property);
                                },
                              ),
                            ],
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (widget.onEdit != null) ...[
                                _actionButton(
                                  Icons.edit_note_rounded,
                                  AppColors.info,
                                  "تعديل العقار",
                                  widget.onEdit!,
                                ),
                                SizedBox(height: 14.h),
                              ],
                              if (widget.onShareInternal != null) ...[
                                _actionButton(
                                  Icons.ios_share_rounded,
                                  AppColors.brandPrimary,
                                  "مشاركة مع زميل",
                                  widget.onShareInternal!,
                                ),
                                SizedBox(height: 14.h),
                              ],
                              if (widget.onArchive != null) ...[
                                _actionButton(
                                  Icons.archive_outlined,
                                  Colors.orange,
                                  "نقل للأرشيف",
                                  widget.onArchive!,
                                ),
                                SizedBox(height: 14.h),
                              ],
                              if (widget.onRestore != null) ...[
                                _actionButton(
                                  Icons.restore_page_outlined,
                                  Colors.green,
                                  "استعادة العقار",
                                  widget.onRestore!,
                                ),
                                SizedBox(height: 14.h),
                              ],
                              if (widget.onDelete != null) ...[
                                _actionButton(
                                  Icons.delete_outline_rounded,
                                  AppColors.brandAccent,
                                  "حذف نهائي",
                                  widget.onDelete!,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, String tooltipMsg, VoidCallback onPressed) {
    return Tooltip(
      message: tooltipMsg,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      textStyle: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
      preferBelow: false,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: color, size: 28.sp),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool available = widget.property.status;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.88)
            : AppColors.brandAccent.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        available ? "نشط" : "مغلق",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
