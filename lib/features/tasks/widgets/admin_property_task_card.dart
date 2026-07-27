import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/property_cache_manager.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../cubit/property_tasks_cubit.dart';
import '../../properties/screens/property_details_screen.dart';
import '../../properties/screens/property_full_screen_image.dart';

class AdminPropertyTaskCard extends StatefulWidget {
  final PropertyModel property;
  final String role;
  final String currentUserId;

  const AdminPropertyTaskCard({super.key, required this.property, required this.role, required this.currentUserId});

  @override
  State<AdminPropertyTaskCard> createState() => _AdminPropertyTaskCardState();
}

class _AdminPropertyTaskCardState extends State<AdminPropertyTaskCard> {
  final dataManager = di.sl<StaticDataManager>();
  final Set<String> _selectedPlatforms = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _isDescExpanded = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitAction(String statusName) async {
    setState(() => _isSubmitting = true);
    final statusId = statusName == 'تمت الموافقة'
        ? '74076467-124a-4142-b821-6096d9fa3f4c'
        : '7345796d-1fd8-462d-b240-7eec15c87e6f';
    
    final platformIds = statusName == 'تمت الموافقة'
        ? _selectedPlatforms
            .map((name) => dataManager.getIdByName('advertising_platform', name))
            .where((id) => id != null)
            .cast<String>()
            .toList()
        : <String>[];

    try {
      await context.read<PropertyTasksCubit>().approveProperty(
        propertyId: widget.property.id,
        approvalStatusId: statusId,
        platformIds: platformIds,
        managerNotes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "غير متوفر";
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  void _openGallery() {
    if (widget.property.images.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            width: 0.9.sw,
            height: 0.7.sh,
            child: PropertyFullScreenImage(
              imageUrls: widget.property.images.map((img) => img.original).toList(),
              initialIndex: 0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? firstImageUrl = widget.property.images.isNotEmpty ? widget.property.images.first.thumbnail : null;
    final String displayUrl = firstImageUrl ?? "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";
    final allPlatforms = dataManager.getOptions('advertising_platform');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: IntrinsicHeight(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Column 1: Image ───
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    height: 160.h,
                    child: GestureDetector(
                      onTap: _openGallery,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              cacheManager: PropertyCacheManager.instance,
                              imageUrl: displayUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.bgMain,
                                child: const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.bgMain,
                                child: Icon(Icons.broken_image_outlined, color: AppColors.textDisabled, size: 40.sp),
                              ),
                            ),
                          ),
                          if (widget.property.images.isNotEmpty)
                            Positioned(
                              bottom: 6.h, right: 6.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4.r)),
                                child: Row(
                                  children: [
                                    Icon(Icons.photo_library_outlined, color: Colors.white, size: 14.sp),
                                    SizedBox(width: 4.w),
                                    Text("${widget.property.images.length}", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
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
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
              ),
              
              // ─── Column 2: Info ───
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildDetailRow("أضيف بواسطة", widget.property.createdByName ?? "غير معروف", icon: Icons.person)),
                          Expanded(flex: 2, child: _buildDetailRow("كود العقار", widget.property.propertyCode ?? "غير متوفر")),
                          Expanded(flex: 2, child: _buildDetailRow("السعر", "${widget.property.price.toCurrency()} ج.م", isHighlighted: true)),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDetailRow("المدينة", widget.property.cityAr)),
                          Expanded(child: _buildDetailRow("نوع العقار", widget.property.propertyTypeAr)),
                          Expanded(child: _buildDetailRow("نوع الإعلان", widget.property.listingTypeAr)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
              ),
              
              // ─── Column 3: Desc + Platforms + Notes ───
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("وصف العقار", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                                SizedBox(width: 8.w),
                                if (widget.property.descAr.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: widget.property.descAr));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الوصف بنجاح', style: TextStyle(fontFamily: 'Tajawal'))));
                                    },
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Padding(
                                      padding: EdgeInsets.all(4.r),
                                      child: Icon(Icons.copy_rounded, size: 20.sp, color: AppColors.brandPrimary),
                                    ),
                                  ),
                              ],
                            ),
                            if (widget.property.descAr.length > 80)
                              InkWell(
                                onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  child: Text(_isDescExpanded ? "عرض أقل" : "قراءة المزيد", style: TextStyle(color: AppColors.brandPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: SizedBox(
                          width: double.infinity,
                          child: SelectableText(
                            widget.property.descAr.isNotEmpty ? widget.property.descAr : "لا يوجد وصف",
                            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.5),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: _isDescExpanded ? null : 2,
                          ),
                        ),
                      ),
                      Divider(height: 16.h, color: AppColors.borderSubtle),
                      Text("المنصات المقترحة:", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          ...allPlatforms.map((name) {
                            final isSelected = _selectedPlatforms.contains(name);
                            IconData iconData;
                            if (name.contains('فيس')) iconData = Icons.facebook;
                            else if (name.contains('انستا')) iconData = Icons.camera_alt_outlined;
                            else if (name.contains('تيك')) iconData = Icons.music_note;
                            else if (name.contains('موقع')) iconData = Icons.language;
                            else iconData = Icons.campaign_rounded;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) _selectedPlatforms.remove(name);
                                  else _selectedPlatforms.add(name);
                                });
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: isSelected ? AppColors.brandPrimary : Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(iconData, size: 20.sp, color: isSelected ? AppColors.brandPrimary : Colors.grey.shade600),
                                    SizedBox(width: 4.w),
                                    Text(name, style: TextStyle(fontSize: 16.sp, color: isSelected ? AppColors.brandPrimary : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          }),
                          InkWell(
                            onTap: () => _showAddNoteDialog(context),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: _notesController.text.isNotEmpty ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: _notesController.text.isNotEmpty ? AppColors.brandPrimary : Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_note, size: 20.sp, color: _notesController.text.isNotEmpty ? AppColors.brandPrimary : Colors.grey.shade600),
                                  SizedBox(width: 4.w),
                                  Text("إضافة ملاحظة", style: TextStyle(fontSize: 16.sp, color: _notesController.text.isNotEmpty ? AppColors.brandPrimary : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
              ),

              // ─── Column 4: Approve / Reject Actions ───
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDetailRow("تاريخ الإضافة", _formatDate(widget.property.createdAt), icon: Icons.calendar_today_outlined),
                  SizedBox(height: 24.h),
                  if (_isSubmitting)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _selectedPlatforms.isEmpty ? null : () => _submitAction('تمت الموافقة'),
                      icon: Icon(Icons.check_circle_outline, color: Colors.white, size: 24.sp),
                      label: Text("موافقة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    OutlinedButton.icon(
                      onPressed: () => _submitAction('مرفوض'),
                      icon: Icon(Icons.cancel_outlined, color: Colors.red, size: 24.sp),
                      label: Text("رفض", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon, bool isHighlighted = false, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16.sp, color: Colors.grey[500]), SizedBox(width: 4.w)],
            Text(label, style: TextStyle(fontSize: 16.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
            color: isHighlighted ? AppColors.brandPrimary : Colors.black87,
            fontFamily: isPhone ? 'Arial' : null,
          ),
        ),
      ],
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: Text("إضافة ملاحظة للموظف", style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 20.sp)),
            content: SizedBox(
              width: 400.w,
              child: TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "اكتب ملاحظتك هنا...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("إلغاء", style: TextStyle(fontSize: 16.sp, color: Colors.grey[700])),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text("حفظ الملاحظة", style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
