import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/image_download_helper.dart';
import '../../../data/models/design_model.dart';
import '../../properties/screens/property_full_screen_image.dart';
import '../cubit/designs_cubit.dart';
import 'design_inline_form.dart';

class DesignCard extends StatefulWidget {
  final DesignModel design;
  final bool canEdit;

  const DesignCard({Key? key, required this.design, this.canEdit = false})
    : super(key: key);

  @override
  State<DesignCard> createState() => _DesignCardState();
}

class _DesignCardState extends State<DesignCard> {
  bool _isEditing = false;
  bool _isExpanded = false;

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا التشطيب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DesignsCubit>().deleteDesign(widget.design.id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _openGallery(List<DesignImageModel> images, int index) {
    if (images.isEmpty) return;
    final imageUrls = images.map((e) => e.imageUrl!).toList();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(40),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: PropertyFullScreenImage(imageUrls: imageUrls, initialIndex: index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return DesignInlineForm(
        existingDesign: widget.design,
        onCancel: () => setState(() => _isEditing = false),
        onSuccess: (updatedDesign) {
          setState(() => _isEditing = false);
          context.read<DesignsCubit>().updateDesignLocally(updatedDesign);
        },
      );
    }

    final images = widget.design.images ?? [];
    final coverUrl = images.isNotEmpty
        ? (images
              .firstWhere((i) => i.isThumbnail, orElse: () => images.first)
              .imageUrl)
        : null;

    final bool needsExpansion =
        widget.design.descAr.length > 80 || widget.design.links.isNotEmpty;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العمود الأول: الصور
          Padding(
            padding: EdgeInsets.all(12.w),
            child: SizedBox(
              width: 250.w,
              height: 250.w,
              child: InkWell(
                onTap: () => _openGallery(images, 0),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12.r)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (coverUrl != null)
                      CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      )
                    else
                      const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),

                    if (images.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'تنزيل كل الصور',
                            onPressed: () async {
                              final urls = images.map((i) => i.imageUrl!).toList();
                              await ImageDownloadHelper.downloadImages(context, urls, 'design');
                            },
                          ),
                        ),
                      ),

                    if (images.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${images.length - 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          ),

          // العمود الثاني: التفاصيل
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. الوصف بعرض ثابت
                            SizedBox(
                              width: 550.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'وصف التشطيب:',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (widget.design.descAr.isNotEmpty) ...[
                                      SizedBox(width: 24.w),
                                      InkWell(
                                        onTap: () async {
                                          await Clipboard.setData(ClipboardData(text: widget.design.descAr));
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الوصف')));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Icon(Icons.copy, size: 16.sp, color: AppColors.brandPrimary),
                                            SizedBox(width: 6.w),
                                            Text(
                                              'نسخ الكل',
                                              style: TextStyle(
                                                color: AppColors.brandPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (needsExpansion) ...[
                                      SizedBox(width: 24.w),
                                      InkWell(
                                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                                        child: Text(
                                          _isExpanded ? 'عرض أقل' : 'عرض المزيد',
                                          style: TextStyle(
                                            color: AppColors.brandPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  widget.design.descAr,
                                  style: AppTextStyles.h3.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: _isExpanded ? null : 2,
                                  overflow: _isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(width: 32.w),
                          VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
                          SizedBox(width: 32.w),
                          
                          // 2. الاستايل ونوع الغرفة والموظف والتاريخ
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.meeting_room, color: AppColors.brandPrimary, size: 16.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(child: Text('نوع الغرفة: ${widget.design.roomType ?? "غير محدد"}', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Icon(Icons.style, color: AppColors.brandPrimary, size: 16.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(child: Text('الستايل: ${widget.design.style ?? "غير محدد"}', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Icon(Icons.person, color: AppColors.brandPrimary, size: 16.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(child: Text('بواسطة: ${widget.design.profile?['first_name'] ?? ''} ${widget.design.profile?['last_name'] ?? ''}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: AppColors.brandPrimary, size: 16.sp),
                                    SizedBox(width: 8.w),
                                    Expanded(child: Text('${widget.design.createdAt.year}-${widget.design.createdAt.month.toString().padLeft(2, '0')}-${widget.design.createdAt.day.toString().padLeft(2, '0')} - ${widget.design.createdAt.hour == 0 ? 12 : (widget.design.createdAt.hour > 12 ? widget.design.createdAt.hour - 12 : widget.design.createdAt.hour).toString().padLeft(2, '0')}:${widget.design.createdAt.minute.toString().padLeft(2, '0')} ${widget.design.createdAt.hour >= 12 ? 'م' : 'ص'}', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 3. الروابط
                      if (widget.design.links.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        const Divider(),
                        SizedBox(height: 12.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الروابط:',
                              style: AppTextStyles.bodyMain.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: widget.design.links.map(
                                      (link) => ActionChip(
                                        avatar: Icon(Icons.link, size: 16, color: AppColors.brandPrimary),
                                        label: Text(
                                          link.title.isNotEmpty ? link.title : 'رابط',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                                        ),
                                        backgroundColor: AppColors.brandPrimary.withOpacity(0.1),
                                        side: BorderSide.none,
                                        onPressed: () => launchUrl(Uri.parse(link.url)),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (widget.canEdit)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 0, 16.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      tooltip: 'تعديل',
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      tooltip: 'حذف',
                      onPressed: _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
