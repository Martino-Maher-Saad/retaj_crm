import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/property_model.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/utils/number_formatter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PropertiesTableView extends StatefulWidget {
  final List<PropertyModel> properties;
  final String role;
  final Function(PropertyModel) onTap;
  final Function(PropertyModel)? onEdit;
  final Function(PropertyModel)? onDelete;
  final Function(PropertyModel)? onArchive;
  final Function(PropertyModel)? onShareInternal;
  final Function(PropertyModel)? onPinToggle;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;

  const PropertiesTableView({
    super.key,
    required this.properties,
    required this.role,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onShareInternal,
    this.onPinToggle,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  State<PropertiesTableView> createState() => _PropertiesTableViewState();
}

class _PropertiesTableViewState extends State<PropertiesTableView> {
  bool get _isManager => AppRole.fromString(widget.role).isAtLeast(AppRole.manager);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        widget.onLoadMore?.call();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 32.w),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.bgMain),
              dataRowMinHeight: 85.h,
              dataRowMaxHeight: 85.h,
              dividerThickness: 1,
              horizontalMargin: 24.w,
              columnSpacing: 32.w,
              showCheckboxColumn: false,
              columns: [
                _buildHeaderColumn('كود العقار'),
                _buildHeaderColumn('عنوان العقار'),
                _buildHeaderColumn('المدينة'),
                _buildHeaderColumn('نوع العقار'),
                _buildHeaderColumn('نوع الإعلان'),
                _buildHeaderColumn('السعر'),
                if (_isManager) _buildHeaderColumn('الموظف المسند إليه'),
                _buildHeaderColumn('إجراءات'),
              ],
              rows: widget.properties.map((property) {
                return DataRow(
                  onSelectChanged: (_) => widget.onTap(property),
                  color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.hovered)) return AppColors.brandPrimary.withValues(alpha: 0.05);
                    return Colors.white;
                  }),
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (property.isPinned) ...[
                            Icon(Icons.push_pin_rounded, color: Colors.amber, size: 20.sp),
                            SizedBox(width: 4.w),
                          ],
                          Text(property.propertyCode ?? '-', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp, color: AppColors.brandPrimary)),
                        ],
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200.w,
                        child: Text(
                          property.titleAr,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(property.cityAr, style: TextStyle(color: Colors.grey.shade700, fontSize: 15.sp))),
                    DataCell(Text(property.propertyTypeAr, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500, fontSize: 14.sp))),
                    DataCell(_buildBadge(property.listingTypeAr, isDark: true)),
                    DataCell(Text(NumberFormat.currency(symbol: 'ج.م ', decimalDigits: 0).format(property.price), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 15.sp))),
                    if (_isManager) DataCell(Text(property.createdByName ?? '-', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 14.sp))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionBtn(Icons.edit, Colors.blue, () => widget.onEdit?.call(property)),
                          SizedBox(width: 4.w),
                          _buildActionBtn(Icons.share, Colors.green, () => widget.onShareInternal?.call(property)),
                          SizedBox(width: 4.w),
                          _buildActionBtn(Icons.push_pin_outlined, Colors.amber, () => widget.onPinToggle?.call(property)),
                          SizedBox(width: 4.w),
                          _buildActionBtn(Icons.archive, Colors.orange, () => widget.onArchive?.call(property)),
                          SizedBox(width: 4.w),
                          _buildActionBtn(Icons.delete, Colors.red, () => widget.onDelete?.call(property)),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList()
                ..addAll(
                  widget.isLoadingMore
                      ? [
                          DataRow(
                            cells: List.generate(
                              _isManager ? 8 : 7,
                              (index) => DataCell(
                                Skeletonizer(
                                  enabled: true,
                                  child: Container(
                                    width: double.infinity,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ),
          if (widget.hasMore && !widget.isLoadingMore)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: TextButton(
                onPressed: widget.onLoadMore,
                child: const Text('تحميل المزيد من العقارات', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Icon(icon, color: color, size: 20.sp),
      ),
    );
  }

  DataColumn _buildHeaderColumn(String title) {
    return DataColumn(
      label: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14.sp,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildBadge(String? text, {bool isDark = false, bool isBrand = false}) {
    if (text == null || text.isEmpty) return const Text('-');
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade800;
    
    if (isBrand) {
      bgColor = AppColors.brandPrimary.withValues(alpha: 0.1);
      textColor = AppColors.brandPrimary;
    } else if (isDark) {
      bgColor = Colors.grey.shade800;
      textColor = Colors.white;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12.sp),
      ),
    );
  }
}
