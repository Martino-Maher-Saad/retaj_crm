import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/property_cache_manager.dart';
import '../../../data/models/property_model.dart';

/// كارت عقار — Neon-Minimalist Wide Card
/// يدعم Hover Scale + Neon Border لتجربة ويب احترافية
class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final String currentUserId;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.currentUserId,
    required this.role,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
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

    final bool isRent =
        widget.property.listingTypeAr.toLowerCase() == 'إيجار';
    final String priceSuffix =
        isRent ? " / ${widget.property.rentalFrequency ?? 'M'}" : "";

    final bool isMine = widget.property.createdBy == widget.currentUserId;
    final bool isManager = widget.role == 'manager';
    final bool shouldMask = widget.role == 'sales' && !isMine;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        transform: _isHovering
            ? (Matrix4.identity()..scale(1.005))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _isHovering
                ? AppColors.brandPrimary.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
            width: _isHovering ? 1.5 : 1,
          ),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Column(
              children: [
                // ─── Banner تحذير للمبيعات ───
                if (shouldMask)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "هذا العقار يخص زميل مبيعات آخر",
                        style: AppTextStyles.tableCellSub.copyWith(
                          color: AppColors.brandAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.all(14.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── الصورة ───
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
                              width: 290.w,
                              height: 195.h,
                              memCacheWidth: 400,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.bgMain,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.bgMain,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: _buildStatusBadge(),
                          ),
                        ],
                      ),
                      SizedBox(width: 16.w),

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
                                      horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    "${widget.property.listingTypeAr} — ${widget.property.propertyTypeAr}",
                                    style: AppTextStyles.tableCellSub.copyWith(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  "#${widget.property.id.length > 4 ? widget.property.id.substring(widget.property.id.length - 4) : widget.property.id}",
                                  style: AppTextStyles.tableCellSub,
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              "${widget.property.price?.toStringAsFixed(0) ?? '0'} EGP$priceSuffix",
                              style: AppTextStyles.blue20Medium.copyWith(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14.sp, color: AppColors.brandAccent),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    "${widget.property.cityAr} — ${widget.property.regionAr}",
                                    style: AppTextStyles.tableCellSub.copyWith(
                                      fontSize: 13.sp,
                                      color: AppColors.textPrimary,
                                    ),
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

                      // ─── أزرار التحكم ───
                      if (isMine || isManager) ...[
                        SizedBox(width: 10.w),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _actionButton(
                              Icons.edit_note_rounded,
                              AppColors.info,
                              widget.onEdit,
                            ),
                            SizedBox(height: 10.h),
                            _actionButton(
                              Icons.delete_outline_rounded,
                              AppColors.brandAccent,
                              widget.onDelete,
                            ),
                          ],
                        ),
                      ],
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

  Widget _actionButton(IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: color, size: 22.sp),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final bool available = widget.property.status;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFF2D6A4F).withValues(alpha: 0.88)
            : AppColors.brandAccent.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        available ? "نشط" : "مغلق",
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeaturesRow() {
    return Row(
      children: [
        _featureChip(Icons.king_bed_outlined, "${widget.property.bedrooms ?? 0}"),
        SizedBox(width: 8.w),
        _featureChip(Icons.bathtub_outlined, "${widget.property.bathrooms ?? 0}"),
        SizedBox(width: 8.w),
        _featureChip(Icons.straighten_rounded,
            "${widget.property.builtArea ?? 0}م²"),
      ],
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: AppTextStyles.tableCellSub.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}