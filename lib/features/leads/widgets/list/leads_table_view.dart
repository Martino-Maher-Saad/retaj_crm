import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/lead_model.dart';

class LeadsTableView extends StatelessWidget {
  final List<LeadModel> leads;
  final bool isBulkSelectMode;
  final Set<String> selectedIds;
  final Function(String, bool?) onSelect;

  final ScrollController scrollController;
  final bool isLoadingMore;
  final String? blinkItemId;

  const LeadsTableView({
    super.key,
    required this.leads,
    required this.isBulkSelectMode,
    required this.selectedIds,
    required this.onSelect,
    required this.scrollController,
    this.isLoadingMore = false,
    this.blinkItemId,
  });

  @override
  Widget build(BuildContext context) {
    final double computedWidth = (isBulkSelectMode ? 50.w : 0) + 1380.w;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double finalWidth = computedWidth < screenWidth ? screenWidth : computedWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: finalWidth,
        child: Column(
          children: [
            // Header Row
            Container(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                children: [
                  if (isBulkSelectMode) SizedBox(width: 50.w), // Checkbox placeholder
                  _buildHeaderCell('تاريخ الإضافة', 120.w),
                  _buildHeaderCell('رقم العميل', 120.w),
                  _buildHeaderCell('اسم العميل', 150.w),
                  _buildHeaderCell('رقم الهاتف', 130.w),
                  _buildHeaderCell('المنصة', 100.w),
                  _buildHeaderCell('حالة العميل', 120.w),
                  _buildHeaderCell('نوع الإعلان', 100.w),
                  _buildHeaderCell('نوع العقار', 100.w),
                  _buildHeaderCell('المدينة', 100.w),
                  _buildHeaderCell('الميزانية (من)', 100.w),
                  _buildHeaderCell('الميزانية (إلى)', 100.w),
                  _buildHeaderCell('المنشئ', 120.w),
                  _buildHeaderCell('المسؤول', 120.w),
                ],
              ),
            ),
            // Data Rows (Lazy loaded via ListView.builder)
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: leads.length + (isLoadingMore ? 1 : 0),
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  if (index >= leads.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  
                  final lead = leads[index];
                  final isSelected = selectedIds.contains(lead.id);
                  final isBlinking = lead.id == blinkItemId;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isBlinking 
                          ? Colors.green.withValues(alpha: 0.15) 
                          : (index.isEven ? Colors.white : Colors.grey.shade50),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isBulkSelectMode ? () => onSelect(lead.id!, !isSelected) : null,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              if (isBulkSelectMode)
                                SizedBox(
                                  width: 50.w,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (val) => onSelect(lead.id!, val),
                                    activeColor: AppColors.brandPrimary,
                                  ),
                                ),
                              _buildDataCell(lead.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm', 'ar').format(lead.createdAt!) : '', 120.w),
                              _buildDataCell(lead.propertyCode ?? '', 120.w),
                              _buildDataCell(lead.clientName, 150.w),
                              _buildDataCell(lead.phones.isNotEmpty ? lead.phones.firstWhere((p) => p.isPrimary, orElse: () => lead.phones.first).phoneNumber : '', 130.w),
                              _buildDataCell(lead.platform ?? '', 100.w),
                              _buildDataCell(lead.leadStatus ?? '', 120.w),
                              _buildDataCell(lead.listingType ?? '', 100.w),
                              _buildDataCell(lead.propertyType ?? '', 100.w),
                              _buildDataCell(lead.city ?? '', 100.w),
                              _buildDataCell(lead.budgetFrom?.toString() ?? '', 100.w),
                              _buildDataCell(lead.budgetTo?.toString() ?? '', 100.w),
                              _buildDataCell(lead.createdByName ?? '', 120.w),
                              _buildDataCell(lead.assignedToName ?? '', 120.w),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: AppColors.brandPrimary),
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp, color: Colors.black87),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
