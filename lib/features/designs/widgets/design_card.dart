import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/design_model.dart';

class DesignCard extends StatefulWidget {
  final DesignModel design;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const DesignCard({
    super.key,
    required this.design,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<DesignCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final String? firstImageUrl = widget.design.images?.isNotEmpty == true
        ? widget.design.images!.first.imageUrl
        : null;
    final String displayUrl = firstImageUrl ??
        "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        transform: _isHovering ? (Matrix4.identity()..scale(1.01)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
          border: _isHovering
              ? Border.all(color: AppColors.brandPrimary, width: 2)
              : Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.r),
                  bottomLeft: Radius.circular(15.r),
                ),
                child: SizedBox(
                  width: 140.w,
                  height: 120.h,
                  child: CachedNetworkImage(
                    imageUrl: displayUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade100,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(Icons.broken_image, color: Colors.grey.shade400, size: 30.sp),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.design.descAr ?? "بدون وصف",
                              style: AppTextStyles.h3.copyWith(fontSize: 16.sp),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          _buildBadge(Icons.meeting_room, widget.design.roomType ?? "غير محدد", Colors.purple),
                          SizedBox(width: 8.w),
                          _buildBadge(Icons.palette, widget.design.style ?? "غير محدد", Colors.teal),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            widget.design.profile?.firstName != null
                                ? "${widget.design.profile!.firstName} ${widget.design.profile!.lastName}"
                                : "مجهول",
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Padding(
                padding: EdgeInsets.only(top: 12.h, left: 12.w),
                child: Column(
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
              ),
            ],
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

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
