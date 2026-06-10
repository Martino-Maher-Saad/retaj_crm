import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/widgets/retaj_shared_fields.dart';
import '../cubit/property_tasks_cubit.dart';
import '../../properties/screens/property_details_screen.dart';
import '../../properties/cubit/properties_cubit.dart';

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

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.property.createdAt != null
        ? DateFormat('yyyy/MM/dd hh:mm a').format(widget.property.createdAt!)
        : 'غير محدد';
        
    final allPlatforms = dataManager.getOptions('advertising_platform');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الصف الأول: نوع العقار + نوع الإعلان ───
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${widget.property.propertyTypeAr} — ${widget.property.listingTypeAr}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: AppColors.brandPrimary),
                  ),
                ),
                Text(
                  widget.property.propertyCode != null ? "#${widget.property.propertyCode}" : '—',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            // Grid of info
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Wrap(
                spacing: 12.w,
                runSpacing: 16.h,
                children: [
                  _infoCol(
                    Icons.payments_outlined,
                    'السعر',
                    "${widget.property.price.toCurrency()} ج",
                    valueColor: const Color(0xFF10B981),
                  ),
                  _infoCol(
                    Icons.location_on_outlined,
                    'الموقع',
                    "${widget.property.governorateAr}",
                  ),
                  if (widget.property.createdByName != null)
                    _infoCol(
                      Icons.person_outline_rounded,
                      'المُضيف',
                      widget.property.createdByName!,
                    ),
                  _infoCol(
                    Icons.calendar_today_outlined,
                    'التاريخ',
                    dateStr.split(' – ').first,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "تفاصيل العقار:",
                    style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    widget.property.descAr,
                    style: TextStyle(fontSize: 24.sp, height: 1.5, color: Colors.black87),
                    maxLines: _isDescExpanded ? null : 3,
                    overflow: _isDescExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                  if (widget.property.descAr.length > 120 || widget.property.descAr.split('\n').length > 3)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            _isDescExpanded ? 'إخفاء التفاصيل' : 'اقرأ المزيد',
                            style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 24.sp),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => di.sl<PropertiesCubit>(),
                        child: PropertyDetailsScreen(property: widget.property, role: widget.role, currentUserId: widget.currentUserId),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                icon: Icon(Icons.info_outline, color: Colors.white, size: 24.sp),
                label: Text(
                  'عرض التفاصيل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            RetajTextField(
              controller: _notesController,
              label: 'ملاحظات المدير (تظهر للموظف)',
              prefixIcon: Icons.note_alt_outlined,
              maxLines: null,
              minLines: 2,
            ),
            SizedBox(height: 16.h),
            Text("اختر المنصات التي سينشر عليها الإعلان (في حالة الموافقة):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.black87)),
            SizedBox(height: 5.h),
            Wrap(
              spacing: 10.w,
              children: allPlatforms.map((name) {
                final isSelected = _selectedPlatforms.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  selectedColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                  checkmarkColor: AppColors.brandPrimary,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedPlatforms.add(name);
                      } else {
                        _selectedPlatforms.remove(name);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _selectedPlatforms.isEmpty
                        ? null
                        : () => _submitAction('تمت الموافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: _isSubmitting
                        ? SizedBox(height: 20.h, width: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("موافقة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => _submitAction('مرفوض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: Text("رفض", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _infoCol(IconData icon, String label, String value, {
    Color? valueColor,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 100.w) / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: AppColors.brandPrimary.withValues(alpha: 0.7)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[700], fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
