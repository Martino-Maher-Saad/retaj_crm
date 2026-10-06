import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:trina_grid/trina_grid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/models/lead_model.dart';
import '../../../../data/models/profile_model.dart';
import '../../../../data/repositories/lead_repository.dart';
import '../../cubit/leads_cubit.dart';
import '../../cubit/leads_state.dart';

class LeadsTableView extends StatefulWidget {
  final List<LeadModel> leads;
  final bool isBulkSelectMode;
  final Set<String> selectedIds;
  final Function(String, bool?) onSelect;
  final VoidCallback? onSelectAll;
  final ScrollController scrollController;
  final bool isLoadingMore;
  final String? blinkItemId;
  final String userRole;
  final ProfileModel? currentUser;
  final bool isFullScreen;
  final Widget? customToolbarFilters;

  const LeadsTableView({
    super.key,
    required this.leads,
    required this.isBulkSelectMode,
    required this.selectedIds,
    required this.onSelect,
    this.onSelectAll,
    required this.scrollController,
    this.isLoadingMore = false,
    this.blinkItemId,
    required this.userRole,
    this.currentUser,
    this.isFullScreen = false,
    this.customToolbarFilters,
  });

  @override
  State<LeadsTableView> createState() => LeadsTableViewState();
}

class LeadsTableViewState extends State<LeadsTableView> {
  TrinaGridStateManager? _stateManager;

  // Lookup maps
  final Map<int, String> _cityNameById = {};
  final Map<String, int> _cityIdByName = {};

  final Map<String, String> _employeeNameById = {};
  final Map<String, String> _employeeIdByName = {};

  final Map<String, Map<String, String>> _optionNameById = {};
  final Map<String, Map<String, String>> _optionIdByName = {};

  List<String> _cityNames = [];
  List<String> _employeeNames = [];
  List<String> _propertyTypeNames = [];
  List<String> _listingTypeNames = [];
  List<String> _platformNames = [];
  List<String> _leadStatusNames = [];

  // فلاتر الأعمدة التراكمية (Excel Compound Column Filters)
  final Map<String, Set<String>> _activeColumnFilters = {};

  late List<TrinaColumn> _columns;
  bool _isInitDone = false;

  bool get _isManagerOrAdmin {
    final r = widget.userRole.toLowerCase();
    return r == 'manager' || r == 'admin' || r == 'ceo';
  }

  @override
  void initState() {
    super.initState();
    _initLookupData();
    _initColumns();
    _isInitDone = true;
  }

  @override
  void didUpdateWidget(covariant LeadsTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_stateManager != null && _isInitDone) {
      _syncGridRows();
    }
  }

  void _initLookupData() {
    final dataManager = di.sl<StaticDataManager>();

    // المدن
    for (var c in dataManager.allCities) {
      _cityNameById[c.id] = c.name;
      _cityIdByName[c.name] = c.id;
    }
    _cityNames = dataManager.allCities
        .where((c) => c.isActive)
        .map((c) => c.name)
        .toList();

    // الموظفون
    for (var e in dataManager.employees) {
      final fullName = '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim();
      _employeeNameById[e.id] = fullName;
      _employeeIdByName[fullName] = e.id;
    }
    _employeeNames = dataManager.employees
        .where((e) => e.isActive)
        .map((e) => '${e.firstName ?? ''} ${e.lastName ?? ''}'.trim())
        .toList();

    // القوائم المنفصلة
    final categories = [
      'property_type',
      'listing_type',
      'platform',
      'lead_status'
    ];
    for (var cat in categories) {
      _optionNameById[cat] = {};
      _optionIdByName[cat] = {};
      for (var o in dataManager.getOptionModels(cat)) {
        _optionNameById[cat]![o.id] = o.nameAr;
        _optionIdByName[cat]![o.nameAr] = o.id;
      }
    }

    _propertyTypeNames = dataManager
        .getOptionModels('property_type')
        .where((o) => o.isActive)
        .map((o) => o.nameAr)
        .toList();
    _listingTypeNames = dataManager
        .getOptionModels('listing_type')
        .where((o) => o.isActive)
        .map((o) => o.nameAr)
        .toList();
    _platformNames = dataManager
        .getOptionModels('platform')
        .where((o) => o.isActive)
        .map((o) => o.nameAr)
        .toList();
    _leadStatusNames = dataManager
        .getOptionModels('lead_status')
        .where((o) => o.isActive)
        .map((o) => o.nameAr)
        .toList();
  }

  TrinaColumn _buildColumn({
    required String title,
    required String field,
    required double width,
    TrinaColumnType? type,
    bool enableEditingMode = true,
    TrinaColumnRenderer? renderer,
    TrinaColumnFrozen frozen = TrinaColumnFrozen.none,
    bool enableRowChecked = false,
    bool enableSorting = true,
    bool enableFilter = true,
    bool isRtl = true,
  }) {
    final isFiltered = _activeColumnFilters.containsKey(field);
    return TrinaColumn(
      title: title,
      field: field,
      type: type ?? TrinaColumnType.text(),
      width: width,
      minWidth: 80,
      frozen: frozen,
      enableEditingMode: enableEditingMode,
      enableAutoEditing: true,
      enableRowChecked: enableRowChecked,
      enableSorting: enableSorting,
      titleTextAlign: TrinaColumnTextAlign.center,
      textAlign: isRtl ? TrinaColumnTextAlign.right : TrinaColumnTextAlign.left,
      editCellRenderer: enableEditingMode
          ? (defaultEditCellWidget, cell, controller, focusNode, handleSelected) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.brandPrimary,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textTheme: Theme.of(context).textTheme.copyWith(
                      bodyMedium: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      bodyLarge: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    inputDecorationTheme: const InputDecorationTheme(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  child: defaultEditCellWidget,
                ),
              );
            }
          : null,
      titleSpan: enableFilter
          ? WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6.r),
                  onTap: () => _openColumnFilterDialog(field, title),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isFiltered ? Colors.orange.shade100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.r),
                      border: isFiltered
                          ? Border.all(color: Colors.orange.shade400, width: 1.2)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 17.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isFiltered
                                ? Colors.orange.shade900
                                : AppColors.brandPrimary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          isFiltered
                              ? Icons.filter_alt_rounded
                              : Icons.filter_alt_outlined,
                          size: 18.sp,
                          color: isFiltered
                              ? Colors.orange.shade900
                              : AppColors.brandPrimary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      renderer: renderer,
    );
  }

  void _initColumns() {
    _columns = [
      // 1. الترقيم و Checkbox وإجراءات الصف الجديد المسودة
      _buildColumn(
        title: '#',
        field: 'no',
        width: 105,
        frozen: TrinaColumnFrozen.start,
        enableEditingMode: false,
        enableSorting: false,
        enableRowChecked: true,
        enableFilter: false,
        renderer: (ctx) {
          final id = ctx.row.cells['id']?.value?.toString() ?? '';
          final isDraft = id.startsWith('new_draft_');

          if (isDraft) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _saveDraftLead(id, ctx.row),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Tooltip(
                    message: 'حفظ العميل (اضغط هنا)',
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 16.sp),
                    ),
                  ),
                ),
                SizedBox(width: 5.w),
                InkWell(
                  onTap: () => _removeDraftRow(id, ctx.row),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Tooltip(
                    message: 'إلغاء الصف',
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: Colors.red.shade800, size: 16.sp),
                    ),
                  ),
                ),
              ],
            );
          }

          final val = (ctx.cell.value ?? '').toString();
          return InkWell(
            onTap: () {
              final id = ctx.row.cells['id']?.value?.toString() ?? '';
              if (id.isNotEmpty && !id.startsWith('new_draft_')) {
                final isChecked = widget.selectedIds.contains(id);
                widget.onSelect(id, !isChecked);
              }
            },
            child: Container(
              alignment: Alignment.center,
              child: Text(
                val,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),

      // 2. تاريخ الإضافة (للقراءة للموظف، قابل للتعديل للمدير)
      _buildColumn(
        title: 'تاريخ الإضافة',
        field: 'createdAt',
        width: 165,
        isRtl: false,
        enableEditingMode: _isManagerOrAdmin,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Text(
              val,
              style: TextStyle(
                fontSize: 17.5.sp,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.ltr,
            ),
          );
        },
      ),

      // 3. اسم العميل (RTL)
      _buildColumn(
        title: 'اسم العميل',
        field: 'clientName',
        width: 240,
        isRtl: true,
        enableEditingMode: true,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              val.isEmpty ? 'اكتب اسم العميل...' : val,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.bold,
                color: val.isEmpty ? Colors.grey.shade400 : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),

      // 4. رقم الهاتف (للقراءة فقط للموظف في المسجلين، قابل للتعديل للمدير وفي الصف الجديد)
      _buildColumn(
        title: 'رقم الهاتف',
        field: 'phone',
        width: 220,
        isRtl: false,
        enableEditingMode: true,
        renderer: (ctx) {
          final phone = (ctx.cell.value ?? '').toString();
          final id = ctx.row.cells['id']?.value?.toString() ?? '';
          final isDraft = id.startsWith('new_draft_');

          if (isDraft) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.edit_note_rounded, size: 20.sp, color: const Color(0xFF16A34A)),
                  Text(
                    phone.isEmpty ? 'اكتب رقم الهاتف...' : phone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: phone.isEmpty ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: Colors.grey.shade600,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'نسخ الرقم',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ رقم الهاتف 📋'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8.w),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 16,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'مراسلة عبر واتساب',
                      onPressed: () => _launchWhatsApp(phone),
                    ),
                  ],
                ),
                Text(
                  phone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: _isManagerOrAdmin
                        ? AppColors.brandPrimary
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // 5. المنصة (قائمة منسدلة مع بحث)
      _buildColumn(
        title: 'المنصة',
        field: 'platform',
        width: 175,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          return _buildSelectCell(
            val: val,
            onTap: () => _showSearchableChoicePicker(
              title: 'المنصة',
              field: 'platform',
              leadId: leadId,
              currentValue: val,
              options: _platformNames,
              row: ctx.row,
            ),
          );
        },
      ),

      // 6. حالة العميل (قائمة منسدلة مع بحث)
      _buildColumn(
        title: 'حالة العميل',
        field: 'leadStatus',
        width: 195,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          return _buildSelectCell(
            val: val,
            isStatus: true,
            onTap: () => _showSearchableChoicePicker(
              title: 'حالة العميل',
              field: 'leadStatus',
              leadId: leadId,
              currentValue: val,
              options: _leadStatusNames,
              row: ctx.row,
            ),
          );
        },
      ),

      // 7. المدينة (قائمة منسدلة مع بحث)
      _buildColumn(
        title: 'المدينة',
        field: 'city',
        width: 175,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          return _buildSelectCell(
            val: val,
            onTap: () => _showSearchableChoicePicker(
              title: 'المدينة',
              field: 'city',
              leadId: leadId,
              currentValue: val,
              options: _cityNames,
              row: ctx.row,
            ),
          );
        },
      ),

      // 8. كود العقار (Upper-case + تدقيق الاسطمبة)
      _buildColumn(
        title: 'كود العقار',
        field: 'propertyCode',
        width: 180,
        isRtl: false,
        enableEditingMode: true,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString().trim();
          final isValid = _isPropertyCodeValid(val);

          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            decoration: BoxDecoration(
              border: isValid
                  ? null
                  : Border.all(color: Colors.red.shade600, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    val.isEmpty ? '—' : val,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.black87 : Colors.red,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isValid)
                  Tooltip(
                    message: 'صيغة الكود غير صحيحة، مثال: PROP-101',
                    child: Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 18.sp),
                  ),
              ],
            ),
          );
        },
      ),

      // 9. نوع العقار (قائمة منسدلة مع بحث)
      _buildColumn(
        title: 'نوع العقار',
        field: 'propertyType',
        width: 180,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          return _buildSelectCell(
            val: val,
            onTap: () => _showSearchableChoicePicker(
              title: 'نوع العقار',
              field: 'propertyType',
              leadId: leadId,
              currentValue: val,
              options: _propertyTypeNames,
              row: ctx.row,
            ),
          );
        },
      ),

      // 10. نوع الإعلان (قائمة منسدلة مع بحث)
      _buildColumn(
        title: 'نوع الإعلان',
        field: 'listingType',
        width: 180,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          return _buildSelectCell(
            val: val,
            onTap: () => _showSearchableChoicePicker(
              title: 'نوع الإعلان',
              field: 'listingType',
              leadId: leadId,
              currentValue: val,
              options: _listingTypeNames,
              row: ctx.row,
            ),
          );
        },
      ),

      // 11. الميزانية من
      _buildColumn(
        title: 'الميزانية (من)',
        field: 'budgetFrom',
        width: 145,
        isRtl: false,
        enableEditingMode: true,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          return _buildNumberCell(val);
        },
      ),

      // 12. الميزانية إلى
      _buildColumn(
        title: 'الميزانية (إلى)',
        field: 'budgetTo',
        width: 145,
        isRtl: false,
        enableEditingMode: true,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          return _buildNumberCell(val);
        },
      ),

      // 13. وصف الاحتياج (متعدد الأسطر RTL + خط كبير وواضح جداً)
      _buildColumn(
        title: 'وصف الاحتياج',
        field: 'descLeadNeed',
        width: 380,
        isRtl: true,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          return InkWell(
            onTap: () => _openTextEditorDialog(
              title: 'وصف الاحتياج',
              leadId: leadId,
              field: 'descLeadNeed',
              currentValue: val,
              row: ctx.row,
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              child: Text(
                val.isEmpty ? 'انقر لكتابة تفاصيل الاحتياج...' : val,
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: val.isEmpty ? Colors.grey.shade400 : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),

      // 14. آخر تعليق + تاريخ التعليق (قائمة اختيارات سريعة + تعليق حر)
      _buildColumn(
        title: 'آخر تعليق',
        field: 'lastComment',
        width: 370,
        enableEditingMode: false,
        renderer: (ctx) {
          final comment = (ctx.cell.value ?? '').toString();
          final dateStr = (ctx.row.cells['lastCommentDate']?.value ?? '')
              .toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';

          return InkWell(
            onTap: () => _openFollowUpCommentDialog(
              leadId: leadId,
              currentValue: comment,
              row: ctx.row,
            ),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 20.sp, color: AppColors.brandPrimary),
                      Expanded(
                        child: Text(
                          comment.isEmpty ? 'انقر لاختيار أو كتابة تعليق...' : comment,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.6,
                            color: comment.isEmpty ? Colors.grey.shade400 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dateStr.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      dateStr,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),

      // 15. المسؤول (مقفل للموظف، قابل للنقل والتعديل للمدير مع بحث)
      _buildColumn(
        title: 'المسؤول',
        field: 'assignedTo',
        width: 200,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          final leadId = ctx.row.cells['id']?.value?.toString() ?? '';
          if (_isManagerOrAdmin) {
            return _buildSelectCell(
              val: val.isEmpty ? 'غير محدد' : val,
              onTap: () => _showSearchableChoicePicker(
                title: 'الموظف المسؤول',
                field: 'assignedTo',
                leadId: leadId,
                currentValue: val,
                options: _employeeNames,
                row: ctx.row,
              ),
            );
          }
          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              val.isEmpty ? 'غير محدد' : val,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),

      // 16. المنشئ (للقراءة فقط للجميع)
      _buildColumn(
        title: 'المنشئ',
        field: 'createdBy',
        width: 175,
        enableEditingMode: false,
        renderer: (ctx) {
          final val = (ctx.cell.value ?? '').toString();
          return Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              val.isEmpty ? '—' : val,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 17.sp,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    ];
  }

  bool _isPropertyCodeValid(String val) {
    if (val.isEmpty) return true; // اختياري
    return RegExp(r'^[A-Z]+-[0-9]+$').hasMatch(val);
  }

  // نافذة اختيار منسدلة مع بحث سريع
  Future<void> _showSearchableChoicePicker({
    required String title,
    required String field,
    required String leadId,
    required String currentValue,
    required List<String> options,
    TrinaRow? row,
  }) async {
    final searchCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = options
                .where((o) => o.toLowerCase().contains(query))
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r)),
              titlePadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
              title: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: AppColors.brandPrimary, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text('اختر $title',
                      style: TextStyle(
                          fontSize: 19.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 440.w,
                height: 460.h,
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    TextField(
                      controller: searchCtrl,
                      textDirection: TextDirection.rtl,
                      autofocus: true,
                      style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'بحث في الخيارات...',
                        hintStyle: TextStyle(fontSize: 15.5.sp, color: Colors.grey.shade400),
                        prefixIcon: const Icon(Icons.search, size: 22),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      onChanged: (_) => setDlgState(() {}),
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'لا توجد خيارات مطابقة',
                                style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = filtered[idx];
                                final isCurrent = item == currentValue;
                                return ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                  dense: false,
                                  title: Text(
                                    item,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 17.5.sp,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? AppColors.brandPrimary
                                          : Colors.black87,
                                    ),
                                  ),
                                  trailing: isCurrent
                                      ? Icon(Icons.check_circle_rounded,
                                          color: AppColors.brandPrimary,
                                          size: 24.sp)
                                      : null,
                                  onTap: () => Navigator.pop(ctx, item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('إلغاء', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != currentValue) {
      if (row != null && row.cells.containsKey(field)) {
        row.cells[field]?.value = result;
      }
      if (leadId.startsWith('new_draft_')) {
        return;
      }
      await _applyFieldValueUpdate(
        leadId: leadId,
        field: field,
        newValue: result,
        oldValue: currentValue,
        row: row,
      );
    }
  }

  // نافذة تعديل مريح للنصوص الطويلة الحرة
  Future<void> _openTextEditorDialog({
    required String title,
    required String leadId,
    required String field,
    required String currentValue,
    TrinaRow? row,
  }) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        titlePadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded,
                color: AppColors.brandPrimary, size: 28.sp),
            SizedBox(width: 8.w),
            Text('تعديل: $title',
                style: TextStyle(fontSize: 21.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 600.w,
          child: TextField(
            controller: controller,
            maxLines: 7,
            minLines: 4,
            textDirection: TextDirection.rtl,
            autofocus: true,
            style: TextStyle(fontSize: 20.sp, height: 1.75, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'اكتب هنا بحرية...',
              hintStyle: TextStyle(fontSize: 17.5.sp, color: Colors.grey.shade400),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r)),
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('حفظ', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      if (row != null && row.cells.containsKey(field)) {
        row.cells[field]?.value = result;
      }
      if (leadId.startsWith('new_draft_')) {
        return;
      }
      await _applyFieldValueUpdate(
        leadId: leadId,
        field: field,
        newValue: result,
        oldValue: currentValue,
        row: row,
      );
    }
  }

  // ─── نافذة اختيار آخر تعليق (خيارات سريعة + تعليق حر) ───
  Future<void> _openFollowUpCommentDialog({
    required String leadId,
    required String currentValue,
    TrinaRow? row,
  }) async {
    final commentCtrl = TextEditingController(text: currentValue);
    String? selectedPreset;

    final presetOptions = [
      'لم يتم التواصل',
      'تم التواصل',
      'مهتم',
      'غير مهتم',
      'لم يرد',
      'VIP',
      'بروكر',
      'تم التعاقد',
      'طلب تفاصيل إضافية وعرض أسعار',
      'تفكير وسيعاود الاتصال',
      'ميزانية غير مناسبة',
      'طلب عقار بديل',
      'أخرى (كتابة تعليق حر)',
    ];

    if (presetOptions.contains(currentValue)) {
      selectedPreset = currentValue;
    } else if (currentValue.isNotEmpty) {
      selectedPreset = 'أخرى (كتابة تعليق حر)';
    }

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          titlePadding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 8.h),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          title: Row(
            children: [
              Icon(Icons.comment_bank_rounded, color: AppColors.brandPrimary, size: 26.sp),
              SizedBox(width: 8.w),
              Text(
                'آخر تعليق / متابعة العميل 💬',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 580.w,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر من الخيارات السريعة أو اختر "أخرى" لكتابة تعليق حر:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 10.h,
                    children: presetOptions.map((opt) {
                      final isSelected = selectedPreset == opt;
                      final isOther = opt.contains('أخرى');
                      return ChoiceChip(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        label: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 15.5.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isOther ? Colors.deepOrange.shade800 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: isOther ? Colors.deepOrange : AppColors.brandPrimary,
                        backgroundColor: isOther ? Colors.deepOrange.shade50 : const Color(0xFFF1F5F9),
                        onSelected: (selected) {
                          setDlgState(() {
                            selectedPreset = selected ? opt : null;
                            if (isOther) {
                              commentCtrl.clear();
                            } else {
                              commentCtrl.text = opt;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'نص التعليق / الملاحظة:',
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 4,
                    minLines: 2,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontSize: 19.5.sp, fontWeight: FontWeight.w600, height: 1.75),
                    decoration: InputDecoration(
                      hintText: 'اكتب نص المتابعة أو التعليق هنا...',
                      hintStyle: TextStyle(fontSize: 17.sp, color: Colors.grey.shade400),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                      contentPadding: EdgeInsets.all(16.w),
                    ),
                    onChanged: (text) {
                      if (selectedPreset != 'أخرى (كتابة تعليق حر)' && !presetOptions.contains(text)) {
                        setDlgState(() {
                          selectedPreset = 'أخرى (كتابة تعليق حر)';
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: TextStyle(fontSize: 16.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () => Navigator.pop(ctx, commentCtrl.text.trim()),
              child: Text('حفظ التعليق', style: TextStyle(fontSize: 16.5.sp, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != currentValue) {
      if (row != null && row.cells.containsKey('lastComment')) {
        row.cells['lastComment']?.value = result;
        row.cells['lastCommentDate']?.value = DateFormat('MM/dd hh:mm a').format(DateTime.now());
      }
      if (leadId.startsWith('new_draft_')) {
        return;
      }
      await _applyFieldValueUpdate(
        leadId: leadId,
        field: 'lastComment',
        newValue: result,
        oldValue: currentValue,
        row: row,
      );
    }
  }

  Widget _buildSelectCell({
    required String val,
    required VoidCallback onTap,
    bool isStatus = false,
  }) {
    final isNotContacted = isStatus && val.contains('لم يتم');
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: isStatus
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isNotContacted
                              ? const Color(0xFFFFF1F2)
                              : AppColors.brandPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          val.isEmpty ? '—' : val,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 19.sp,
                            fontWeight: FontWeight.bold,
                            color: isNotContacted
                                ? const Color(0xFFE11D48)
                                : AppColors.brandPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : Text(
                      val.isEmpty ? '—' : val,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: val.isEmpty ? Colors.grey : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Icon(Icons.arrow_drop_down,
                size: 24.sp, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCell(String val) {
    String display = '—';
    if (val.isNotEmpty) {
      final numVal = num.tryParse(val.replaceAll(',', ''));
      if (numVal != null) {
        display = NumberFormat.decimalPattern('en').format(numVal);
      }
    }
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Text(
        display,
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontSize: 20.5.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // تصفية العملاء المعروضين وفق فلاتر الأعمدة التراكمية
  List<LeadModel> get _displayedLeads {
    if (_activeColumnFilters.isEmpty) return widget.leads;

    return widget.leads.where((lead) {
      for (final entry in _activeColumnFilters.entries) {
        final field = entry.key;
        final selectedSet = entry.value;
        if (selectedSet.isEmpty) continue;

        final val = _getLeadFieldValue(lead, field);
        if (!selectedSet.contains(val)) return false;
      }
      return true;
    }).toList();
  }

  String _getLeadFieldValue(LeadModel lead, String field) {
    switch (field) {
      case 'platform':
        return _optionNameById['platform']?[lead.platformId] ?? lead.platform ?? '';
      case 'leadStatus':
        return _optionNameById['lead_status']?[lead.statusId] ?? lead.leadStatus ?? '';
      case 'city':
        return _cityNameById[lead.cityId] ?? lead.city ?? '';
      case 'propertyType':
        return _optionNameById['property_type']?[lead.propertyTypeId] ?? lead.propertyType ?? '';
      case 'listingType':
        return _optionNameById['listing_type']?[lead.listingTypeId] ?? lead.listingType ?? '';
      case 'propertyCode':
        return (lead.propertyCode ?? '').toUpperCase();
      case 'assignedTo':
        return _employeeNameById[lead.assignedTo] ?? lead.assignedToName ?? '';
      case 'createdBy':
        return lead.createdByName ?? '';
      case 'clientName':
        return lead.clientName;
      case 'phone':
        return lead.phones.isNotEmpty ? lead.phones.first.phoneNumber : '';
      case 'createdAt':
        return lead.createdAt != null
            ? DateFormat('yyyy-MM-dd').format(lead.createdAt!)
            : '';
      case 'lastComment':
        return lead.lastComment ?? '';
      default:
        return '';
    }
  }

  TrinaRow _createTrinaRow(LeadModel lead, int index) {
    String dateStr = '';
    if (lead.createdAt != null) {
      dateStr = _isManagerOrAdmin
          ? DateFormat('yyyy-MM-dd HH:mm').format(lead.createdAt!)
          : DateFormat('MM/dd').format(lead.createdAt!);
    }

    String lastCommentDateStr = '';
    if (lead.lastCommentDate != null) {
      lastCommentDateStr = DateFormat('MM/dd hh:mm a').format(lead.lastCommentDate!);
    }

    final phoneStr = lead.phones.isNotEmpty ? lead.phones.first.phoneNumber : '';

    return TrinaRow(
      checked: widget.selectedIds.contains(lead.id),
      cells: {
        'id': TrinaCell(value: lead.id),
        'no': TrinaCell(value: '${index + 1}'),
        'createdAt': TrinaCell(value: dateStr),
        'clientName': TrinaCell(value: lead.clientName),
        'phone': TrinaCell(value: phoneStr),
        'platform': TrinaCell(
          value: _optionNameById['platform']?[lead.platformId] ?? lead.platform ?? '',
        ),
        'leadStatus': TrinaCell(
          value: _optionNameById['lead_status']?[lead.statusId] ?? lead.leadStatus ?? '',
        ),
        'city': TrinaCell(
          value: _cityNameById[lead.cityId] ?? lead.city ?? '',
        ),
        'propertyCode': TrinaCell(
          value: (lead.propertyCode ?? '').toUpperCase(),
        ),
        'propertyType': TrinaCell(
          value: _optionNameById['property_type']?[lead.propertyTypeId] ?? lead.propertyType ?? '',
        ),
        'listingType': TrinaCell(
          value: _optionNameById['listing_type']?[lead.listingTypeId] ?? lead.listingType ?? '',
        ),
        'budgetFrom': TrinaCell(
          value: lead.budgetFrom != null ? '${lead.budgetFrom}' : '',
        ),
        'budgetTo': TrinaCell(
          value: lead.budgetTo != null ? '${lead.budgetTo}' : '',
        ),
        'descLeadNeed': TrinaCell(value: lead.descLeadNeed ?? ''),
        'lastComment': TrinaCell(value: lead.lastComment ?? ''),
        'lastCommentDate': TrinaCell(value: lastCommentDateStr),
        'assignedTo': TrinaCell(
          value: _employeeNameById[lead.assignedTo] ?? lead.assignedToName ?? '',
        ),
        'createdBy': TrinaCell(value: lead.createdByName ?? ''),
      },
    );
  }

  void _syncGridRows() {
    if (_stateManager == null) return;
    
    // الحفاظ على أي صفوف مسودة جديدة لم تُحفظ بعد
    final draftRows = _stateManager!.rows.where((r) {
      final id = r.cells['id']?.value?.toString() ?? '';
      return id.startsWith('new_draft_');
    }).toList();

    final isAscending = context.read<LeadCubit>().isSortAscending;

    final newRows = _displayedLeads
        .asMap()
        .entries
        .map((e) => _createTrinaRow(e.value, e.key))
        .toList();

    _stateManager!.removeAllRows(notify: false);

    if (draftRows.isNotEmpty) {
      if (!isAscending) {
        _stateManager!.appendRows([...draftRows, ...newRows]);
      } else {
        _stateManager!.appendRows([...newRows, ...draftRows]);
      }
    } else {
      _stateManager!.appendRows(newRows);
    }
  }

  // ─── عند تعديل خلية في الجدول ───
  Future<void> _handleCellChange(TrinaGridOnChangedEvent event) async {
    final leadId = event.row.cells['id']?.value?.toString();
    if (leadId == null) return;

    final field = event.column.field;
    final newValue = event.value?.toString().trim() ?? '';
    final oldValue = event.oldValue?.toString().trim() ?? '';

    if (newValue == oldValue) return;

    // إذا كان صف مسودة جديد لم يُحفظ بعد في قاعدة البيانات
    if (leadId.startsWith('new_draft_')) {
      if (field == 'propertyCode') {
        event.row.cells['propertyCode']?.value = newValue.toUpperCase();
      } else {
        event.row.cells[field]?.value = newValue;
      }
      return;
    }

    await _applyFieldValueUpdate(
      leadId: leadId,
      field: field,
      newValue: newValue,
      oldValue: oldValue,
      row: event.row,
    );
  }

  Future<void> _applyFieldValueUpdate({
    required String leadId,
    required String field,
    required String newValue,
    required String oldValue,
    TrinaRow? row,
  }) async {
    if (leadId.startsWith('new_draft_')) {
      return;
    }
    final cubit = context.read<LeadCubit>();
    final currentLead = widget.leads.firstWhere(
      (l) => l.id == leadId,
      orElse: () => widget.leads.first,
    );

    try {
      if (field == 'clientName') {
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: newValue.isEmpty ? 'بدون اسم' : newValue,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: currentLead.platformId,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'propertyCode') {
        final upper = newValue.toUpperCase();
        if (upper.isNotEmpty && !_isPropertyCodeValid(upper)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ صيغة كود العقار غير صحيحة، مثال: PROP-101'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        row?.cells['propertyCode']?.value = upper;
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: currentLead.platformId,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: upper.isEmpty ? null : upper,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'city') {
        final cityId = _cityIdByName[newValue];
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: cityId,
          city: newValue,
          platformId: currentLead.platformId,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'platform') {
        final platId = _optionIdByName['platform']?[newValue];
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: platId,
          platform: newValue,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'propertyType') {
        final pTypeId = _optionIdByName['property_type']?[newValue];
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: currentLead.platformId,
          propertyTypeId: pTypeId,
          propertyType: newValue,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'listingType') {
        final lTypeId = _optionIdByName['listing_type']?[newValue];
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: currentLead.platformId,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: lTypeId,
          listingType: newValue,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'leadStatus') {
        final sId = _optionIdByName['lead_status']?[newValue];
        if (sId != null) {
          await cubit.updateLeadStatus(leadId, sId);
        }
      } else if (field == 'lastComment') {
        // عند اختيار تعليق من القائمة
        final sId = _optionIdByName['lead_status']?[newValue] ??
            AppConstants.leadStatusContacted;
        await cubit.addNote(
          leadId,
          newValue,
          quickCommentId: sId,
          newStatusId: sId,
        );
        row?.cells['lastCommentDate']?.value =
            DateFormat('MM/dd hh:mm a').format(DateTime.now());
      } else if (field == 'descLeadNeed') {
        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: currentLead.platformId,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: newValue,
          budgetFrom: currentLead.budgetFrom,
          budgetTo: currentLead.budgetTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'budgetFrom' || field == 'budgetTo') {
        final bFrom = field == 'budgetFrom'
            ? num.tryParse(newValue.replaceAll(',', ''))
            : currentLead.budgetFrom;
        final bTo = field == 'budgetTo'
            ? num.tryParse(newValue.replaceAll(',', ''))
            : currentLead.budgetTo;

        final updatedLead = LeadModel(
          id: currentLead.id,
          clientName: currentLead.clientName,
          phones: currentLead.phones,
          createdBy: currentLead.createdBy,
          assignedTo: currentLead.assignedTo,
          createdAt: currentLead.createdAt,
          cityId: currentLead.cityId,
          platformId: currentLead.platformId,
          propertyTypeId: currentLead.propertyTypeId,
          listingTypeId: currentLead.listingTypeId,
          statusId: currentLead.statusId,
          propertyCode: currentLead.propertyCode,
          descLeadNeed: currentLead.descLeadNeed,
          budgetFrom: bFrom,
          budgetTo: bTo,
          lastComment: currentLead.lastComment,
        );
        await cubit.updateFullLead(updatedLead, currentLead.phones);
      } else if (field == 'assignedTo' && _isManagerOrAdmin) {
        final newEmpId = _employeeIdByName[newValue];
        if (newEmpId != null) {
          await cubit.updateLeadStatusAndEmployee(
            leadId,
            currentLead.statusId ?? AppConstants.leadStatusContacted,
            newEmpId,
          );
        }
      } else if (field == 'phone') {
        if (!_isManagerOrAdmin && !leadId.startsWith('new_draft_')) {
          row?.cells['phone']?.value = oldValue;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ ليس لديك صلاحية تعديل رقم الهاتف للعملاء المسجلين'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (newValue.isNotEmpty) {
          final updatedLead = LeadModel(
            id: currentLead.id,
            clientName: currentLead.clientName,
            phones: [LeadPhoneModel(phoneNumber: newValue, isPrimary: true)],
            createdBy: currentLead.createdBy,
            assignedTo: currentLead.assignedTo,
            createdAt: currentLead.createdAt,
            cityId: currentLead.cityId,
            platformId: currentLead.platformId,
            propertyTypeId: currentLead.propertyTypeId,
            listingTypeId: currentLead.listingTypeId,
            statusId: currentLead.statusId,
            propertyCode: currentLead.propertyCode,
            descLeadNeed: currentLead.descLeadNeed,
            budgetFrom: currentLead.budgetFrom,
            budgetTo: currentLead.budgetTo,
            lastComment: currentLead.lastComment,
          );
          await cubit.updateFullLead(updatedLead, [
            LeadPhoneModel(phoneNumber: newValue, isPrimary: true)
          ]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء التحديث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── نافذة فلترة القيم المختلفة لكل عمود (Distinct Filter Dialog) ───
  void _openColumnFilterDialog(String field, String title) {
    // 1. حساب القيم الفريدة وتكراراتها من القائمة الإجمالية
    final Map<String, int> valueCounts = {};
    for (final l in widget.leads) {
      final val = _getLeadFieldValue(l, field);
      final displayVal = val.isEmpty ? '(فارغ / غير محدد)' : val;
      valueCounts[displayVal] = (valueCounts[displayVal] ?? 0) + 1;
    }

    final distinctValues = valueCounts.keys.toList()..sort();
    final currentlySelected = Set<String>.from(
      _activeColumnFilters[field] ?? distinctValues.map((v) => v == '(فارغ / غير محدد)' ? '' : v),
    );

    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filteredOptions = distinctValues
                .where((v) => v.toLowerCase().contains(query))
                .toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              titlePadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt_rounded,
                          color: AppColors.brandPrimary, size: 22.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'فلترة: $title',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'القيم الفريدة: ${distinctValues.length}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380.w,
                height: 380.h,
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    TextField(
                      controller: searchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'بحث في القيم...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              currentlySelected.clear();
                              currentlySelected.addAll(distinctValues
                                  .map((v) => v == '(فارغ / غير محدد)' ? '' : v));
                            });
                          },
                          child: const Text('تحديد الكل'),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              currentlySelected.clear();
                            });
                          },
                          child: const Text('إلغاء التحديد'),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredOptions.length,
                        itemBuilder: (context, i) {
                          final opt = filteredOptions[i];
                          final rawVal =
                              opt == '(فارغ / غير محدد)' ? '' : opt;
                          final isChecked =
                              currentlySelected.contains(rawVal);
                          final count = valueCounts[opt] ?? 0;

                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    opt,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: isChecked
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  currentlySelected.add(rawVal);
                                } else {
                                  currentlySelected.remove(rawVal);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (_activeColumnFilters.containsKey(field))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _activeColumnFilters.remove(field);
                        _initColumns();
                        _syncGridRows();
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('إلغاء فلتر هذا العمود',
                        style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إغلاق'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (currentlySelected.length == distinctValues.length) {
                        _activeColumnFilters.remove(field);
                      } else {
                        _activeColumnFilters[field] = currentlySelected;
                      }
                      _initColumns();
                      _syncGridRows();
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text('تطبيق الفلتر (${currentlySelected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── التعبئة الجماعية للخلايا المحددة (Bulk Fill) ───
  void _bulkFillSelectedCells() {
    if (_stateManager == null) return;
    final selectedPositions = _stateManager!.currentSelectingPositionList;
    if (selectedPositions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'يرجى تحديد خلايا في الجدول أولاً (بالسحب بالماوس أو Shift + الأسهم)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Set<String> fields = selectedPositions
        .map((p) => p.field)
        .whereType<String>()
        .toSet();

    if (fields.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'لتعبئة الخلايا دفعة واحدة، يرجى تحديد خلايا في عمود واحد فقط'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final field = fields.first;
    if (field == 'no' || field == 'createdAt' || field == 'createdBy') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن التعبئة الجماعية لهذا العمود'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (field == 'phone' && !_isManagerOrAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعديل رقم الهاتف متاح للمدير فقط'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (field == 'assignedTo' && !_isManagerOrAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعديل الموظف المسؤول متاح للمدير فقط'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<String>? options;
    if (field == 'platform') options = _platformNames;
    if (field == 'leadStatus') options = _leadStatusNames;
    if (field == 'city') options = _cityNames;
    if (field == 'propertyType') options = _propertyTypeNames;
    if (field == 'listingType') options = _listingTypeNames;
    if (field == 'assignedTo') options = _employeeNames;

    if (options != null) {
      String? chosen;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تعبئة ${selectedPositions.length} خلايا محددة'),
          content: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'اختر القيمة الموحدة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            items: options!.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (v) => chosen = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final selectedVal = chosen;
                if (selectedVal != null) {
                  Navigator.pop(ctx);
                  for (final pos in selectedPositions) {
                    final row = _stateManager!.getRowByIdx(pos.rowIdx);
                    if (row != null && row.cells.containsKey(field)) {
                      final leadId = row.cells['id']?.value?.toString();
                      if (leadId == null) continue;
                      final oldVal = row.cells[field]?.value?.toString().trim() ?? '';
                      row.cells[field]?.value = selectedVal;
                      await _applyFieldValueUpdate(
                        leadId: leadId,
                        field: field,
                        newValue: selectedVal,
                        oldValue: oldVal,
                        row: row,
                      );
                    }
                  }
                  _stateManager!.notifyListeners();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت تعبئة ${selectedPositions.length} خلية بنجاح ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('تطبيق وتعبئة'),
            ),
          ],
        ),
      );
    } else {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('تعبئة ${selectedPositions.length} خلايا محددة'),
          content: TextField(
            controller: controller,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: 'القيمة النصية الموحدة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final txt = controller.text.trim();
                Navigator.pop(ctx);
                for (final pos in selectedPositions) {
                  final row = _stateManager!.getRowByIdx(pos.rowIdx);
                  if (row != null && row.cells.containsKey(field)) {
                    final leadId = row.cells['id']?.value?.toString();
                    if (leadId == null) continue;
                    final oldVal = row.cells[field]?.value?.toString().trim() ?? '';
                    row.cells[field]?.value = txt;
                    await _applyFieldValueUpdate(
                      leadId: leadId,
                      field: field,
                      newValue: txt,
                      oldValue: oldVal,
                      row: row,
                    );
                  }
                }
                _stateManager!.notifyListeners();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت تعبئة ${selectedPositions.length} خلية بنجاح ✅'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('تطبيق وتعبئة'),
            ),
          ],
        ),
      );
    }
  }

  // ─── إضافة صف جديد مباشرة داخل جدول الإكسيل (Inline Row Insertion) ───
  void addNewInlineRow() {
    if (_stateManager == null) return;

    final draftId = 'new_draft_${DateTime.now().millisecondsSinceEpoch}';
    final dateStr = _isManagerOrAdmin
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())
        : DateFormat('MM/dd').format(DateTime.now());

    final defaultStatus = _leadStatusNames.isNotEmpty
        ? (_leadStatusNames.contains('لم يتم التواصل')
            ? 'لم يتم التواصل'
            : _leadStatusNames.first)
        : '';
    final defaultPlatform = _platformNames.isNotEmpty ? _platformNames.first : '';
    final defaultCity = _cityNames.isNotEmpty ? _cityNames.first : '';
    final defaultPropType = _propertyTypeNames.isNotEmpty ? _propertyTypeNames.first : '';
    final defaultListType = _listingTypeNames.isNotEmpty ? _listingTypeNames.first : '';
    final defaultAssigned = _isManagerOrAdmin
        ? (_employeeNames.isNotEmpty ? _employeeNames.first : '')
        : (widget.currentUser?.fullName ?? '');

    final draftRow = TrinaRow(
      cells: {
        'id': TrinaCell(value: draftId),
        'no': TrinaCell(value: '*'),
        'createdAt': TrinaCell(value: dateStr),
        'clientName': TrinaCell(value: ''),
        'phone': TrinaCell(value: ''),
        'platform': TrinaCell(value: defaultPlatform),
        'leadStatus': TrinaCell(value: defaultStatus),
        'city': TrinaCell(value: defaultCity),
        'propertyCode': TrinaCell(value: ''),
        'propertyType': TrinaCell(value: defaultPropType),
        'listingType': TrinaCell(value: defaultListType),
        'budgetFrom': TrinaCell(value: ''),
        'budgetTo': TrinaCell(value: ''),
        'descLeadNeed': TrinaCell(value: ''),
        'lastComment': TrinaCell(value: ''),
        'lastCommentDate': TrinaCell(value: ''),
        'assignedTo': TrinaCell(value: defaultAssigned),
        'createdBy': TrinaCell(value: widget.currentUser?.fullName ?? ''),
      },
    );

    // يظهر الصف الجديد دائماً فوق خالص في الأول ليسهل ملؤه مباشرة
    _stateManager!.insertRows(0, [draftRow]);
    _stateManager!.moveScrollByRow(TrinaMoveDirection.up, 0);
    final cell = draftRow.cells['clientName'];
    if (cell != null) {
      _stateManager!.setCurrentCell(cell, 0);
      _stateManager!.setEditing(true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ تم فتح صف جديد في أول الجدول! املأ البيانات ثم اضغط علامة الصح الخضراء لحفظ العميل'),
        backgroundColor: Color(0xFF16A34A),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _saveDraftLead(String draftId, TrinaRow row) async {
    final name = row.cells['clientName']?.value?.toString().trim() ?? '';
    final phone = row.cells['phone']?.value?.toString().trim() ?? '';
    final propCode = row.cells['propertyCode']?.value?.toString().trim().toUpperCase() ?? '';

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ يرجى إدخال رقم الهاتف أولاً لحفظ العميل'),
          backgroundColor: Colors.red,
        ),
      );
      final cell = row.cells['phone'];
      final rowIdx = _stateManager?.rows.indexOf(row);
      if (cell != null && rowIdx != null && rowIdx >= 0) {
        _stateManager?.setCurrentCell(cell, rowIdx);
      }
      return;
    }

    if (propCode.isNotEmpty && !_isPropertyCodeValid(propCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ صيغة كود العقار غير صحيحة، مثال: PROP-101'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final platformVal = row.cells['platform']?.value?.toString() ?? '';
    final statusVal = row.cells['leadStatus']?.value?.toString() ?? '';
    final cityVal = row.cells['city']?.value?.toString() ?? '';
    final propTypeVal = row.cells['propertyType']?.value?.toString() ?? '';
    final listTypeVal = row.cells['listingType']?.value?.toString() ?? '';
    final budgetFromVal = row.cells['budgetFrom']?.value?.toString() ?? '';
    final budgetToVal = row.cells['budgetTo']?.value?.toString() ?? '';
    final descNeed = row.cells['descLeadNeed']?.value?.toString().trim() ?? '';
    final comment = row.cells['lastComment']?.value?.toString().trim() ?? '';
    final assignedVal = row.cells['assignedTo']?.value?.toString() ?? '';

    final assignedId = _isManagerOrAdmin
        ? (_employeeIdByName[assignedVal] ?? widget.currentUser?.id ?? '')
        : (widget.currentUser?.id ?? '');

    final newLead = LeadModel(
      clientName: name.isEmpty ? 'بدون اسم' : name,
      phones: [LeadPhoneModel(phoneNumber: phone, isPrimary: true)],
      createdBy: widget.currentUser?.id ?? '',
      assignedTo: assignedId,
      createdAt: DateTime.now().toLocal(),
      cityId: _cityIdByName[cityVal],
      platformId: _optionIdByName['platform']?[platformVal],
      propertyTypeId: _optionIdByName['property_type']?[propTypeVal],
      listingTypeId: _optionIdByName['listing_type']?[listTypeVal],
      statusId: _optionIdByName['lead_status']?[statusVal],
      propertyCode: propCode.isEmpty ? null : propCode,
      descLeadNeed: descNeed.isEmpty ? null : descNeed,
      budgetFrom: num.tryParse(budgetFromVal.replaceAll(',', '')),
      budgetTo: num.tryParse(budgetToVal.replaceAll(',', '')),
      lastComment: comment.isEmpty ? null : comment,
    );

    final cubit = context.read<LeadCubit>();
    final isAscending = cubit.isSortAscending;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await cubit.addLead(
        newLead,
        [LeadPhoneModel(phoneNumber: phone, isPrimary: true)],
        newNote: comment.isEmpty ? null : comment,
      );
      _stateManager?.removeRows([row]);
      if (mounted) {
        final successMsg = isAscending
            ? 'تم إضافة العميل بنجاح، وتمت إضافته في آخر صف'
            : 'تم إضافة العميل بنجاح';
        messenger.showSnackBar(
          SnackBar(
            content: Text(successMsg),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        if (isAscending && _stateManager != null && _stateManager!.rows.isNotEmpty) {
          final lastIdx = _stateManager!.rows.length - 1;
          _stateManager!.moveScrollByRow(TrinaMoveDirection.down, lastIdx);
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء إضافة العميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeDraftRow(String draftId, TrinaRow row) {
    _stateManager?.removeRows([row]);
  }

  void _showBulkReassignDialog(LeadCubit cubit) {
    final state = cubit.state;
    if (state is! LeadLoaded || state.employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات موظفين متاحة للنقل')),
      );
      return;
    }

    String? selectedEmployeeId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.brandPrimary, size: 24.sp),
              SizedBox(width: 8.w),
              const Text('نقل العملاء المحددين', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر الموظف لنقل (${widget.selectedIds.length}) عميل إليه:'),
              SizedBox(height: 14.h),
              DropdownButtonFormField<String>(
                initialValue: selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: 'الموظف المستلم',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                items: state.employees.map((e) {
                  final name = (e.firstName != null && e.firstName!.isNotEmpty)
                      ? '${e.firstName} ${e.lastName ?? ''}'.trim()
                      : e.email;
                  return DropdownMenuItem(value: e.id, child: Text(name));
                }).toList(),
                onChanged: (val) => setDlgState(() => selectedEmployeeId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedEmployeeId == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _performBulkReassign(cubit, selectedEmployeeId!);
                    },
              child: const Text('تأكيد النقل'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performBulkReassign(LeadCubit cubit, String employeeId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = di.sl<LeadRepository>();
      final dataManager = di.sl<StaticDataManager>();
      final notContactedStatusId =
          dataManager.getIdByName('lead_status', 'لم يتم التواصل معه') ??
          dataManager.getIdByName('lead_status', 'لم يتم التواصل') ??
          '460be748-7685-49ef-abcf-c4dd49511ab7';

      for (final id in widget.selectedIds) {
        await repository.updateLeadStatusAndEmployee(
          id,
          notContactedStatusId,
          employeeId,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نقل العملاء بنجاح 🎉'), backgroundColor: Colors.green),
        );
        for (final id in List<String>.from(widget.selectedIds)) {
          widget.onSelect(id, false);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل النقل: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBulkDeleteConfirmationDialog(LeadCubit cubit) {
    if (widget.selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('تأكيد حذف العملاء', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف (${widget.selectedIds.length}) عميل نهائياً؟\nهذا الإجراء سيقوم بحذف العملاء وكافة أرقامهم وملاحظاتهم نهائياً ولا يمكن التراجع عنه.',
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performBulkDelete(cubit);
            },
            child: const Text('نعم، حذف نهائي'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete(LeadCubit cubit) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = widget.selectedIds.length;
      await cubit.bulkDeleteLeads(widget.selectedIds.toList());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف $count عميل بنجاح'), backgroundColor: Colors.red.shade700),
        );
        for (final id in List<String>.from(widget.selectedIds)) {
          widget.onSelect(id, false);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (formattedPhone.startsWith('01')) {
      formattedPhone = '+2$formattedPhone';
    } else if (formattedPhone.startsWith('1')) {
      formattedPhone = '+20$formattedPhone';
    }
    final url = Uri.parse('https://web.whatsapp.com/send?phone=$formattedPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, webOnlyWindowName: 'whatsapp_web');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح واتساب ويب')),
        );
      }
    }
  }

  void _openFullScreen(BuildContext context) {
    final cubit = context.read<LeadCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: LeadsTableFullScreenPage(
            userRole: widget.userRole,
            currentUser: widget.currentUser,
          ),
        ),
      ),
    );
  }

  void unfocusGrid() {
    FocusScope.of(context).unfocus();
    if (_stateManager != null) {
      if (_stateManager!.isEditing) {
        _stateManager!.setEditing(false);
      }
      _stateManager!.setKeepFocus(false);
      _stateManager!.clearCurrentCell();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = widget.leads.length;
    final displayed = _displayedLeads;
    final displayedCount = displayed.length;
    final isFiltered = _activeColumnFilters.isNotEmpty && displayedCount != totalCount;

    return Container(
      margin: widget.isFullScreen
          ? EdgeInsets.all(8.w)
          : EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ─── شريط أدوات الإكسيل المتقدم (Excel Toolbar) ───
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: unfocusGrid,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: Colors.black87, width: 1.4)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // الجانب الأيمن: عداد العملاء وفلاتر الأعمدة
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: isFiltered
                                      ? Colors.orange.shade50
                                      : AppColors.brandPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: isFiltered
                                        ? Colors.orange.shade300
                                        : AppColors.brandPrimary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFiltered ? Icons.filter_alt_rounded : Icons.people_alt_rounded,
                                      size: 16.sp,
                                      color: isFiltered ? Colors.orange.shade800 : AppColors.brandPrimary,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      isFiltered
                                          ? 'المعروض: $displayedCount عميل (من أصل $totalCount)'
                                          : 'إجمالي العملاء: $totalCount عميل',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isFiltered ? Colors.orange.shade900 : AppColors.brandPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isFiltered) ...[
                                SizedBox(width: 8.w),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _activeColumnFilters.clear();
                                      _initColumns();
                                      _syncGridRows();
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close_rounded, size: 14.sp, color: Colors.red),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'إلغاء فلاتر الأعمدة',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.red.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          SizedBox(width: 16.w),

                          // الجانب الأيسر: الإجراءات وأزرار التحكم
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isManagerOrAdmin && widget.selectedIds.isNotEmpty) ...[
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                                  label: Text(
                                    'نقل (${widget.selectedIds.length})',
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  ),
                                  onPressed: () => _showBulkReassignDialog(context.read<LeadCubit>()),
                                ),
                                SizedBox(width: 6.w),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
                                  label: Text(
                                    'حذف (${widget.selectedIds.length})',
                                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                  ),
                                  onPressed: () => _showBulkDeleteConfirmationDialog(context.read<LeadCubit>()),
                                ),
                                SizedBox(width: 8.w),
                              ],

                              if (widget.customToolbarFilters != null) ...[
                                widget.customToolbarFilters!,
                                SizedBox(width: 10.w),
                              ],

                              // زر تعبئة الخلايا المحددة
                              OutlinedButton.icon(
                                icon: const Icon(Icons.format_color_fill_rounded, size: 18),
                                label: Text(
                                  'تعبئة الخلايا المحددة',
                                  style: TextStyle(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.brandPrimary,
                                  side: const BorderSide(color: AppColors.brandPrimary, width: 1.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                                ),
                                onPressed: _bulkFillSelectedCells,
                              ),

                              SizedBox(width: 8.w),

                              // زر إضافة عميل جديد (فتح صف جديد مباشرة في الجدول)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_rounded, size: 22),
                                label: Text(
                                  'صف جديد / إضافة عميل',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                                ),
                                onPressed: addNewInlineRow,
                              ),

                              if (!widget.isFullScreen) ...[
                                SizedBox(width: 8.w),
                                // زر فتح في صفحة كاملة منفصلة
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded, size: 19),
                                  color: AppColors.brandPrimary,
                                  tooltip: 'فتح في صفحة كاملة منفصلة ↗️',
                                  onPressed: () => _openFullScreen(context),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── جدول الإكسيل TrinaGrid (مع سكرول أفقي وعمودي) ───
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TrinaGrid(
                columns: _columns,
                rows: displayed
                    .asMap()
                    .entries
                    .map((e) => _createTrinaRow(e.value, e.key))
                    .toList(),
                onLoaded: (TrinaGridOnLoadedEvent event) {
                  _stateManager = event.stateManager;
                  _stateManager!.setAutoEditing(true);
                },
                onChanged: _handleCellChange,
                onRowChecked: (event) {
                  if (event.isAll) {
                    if (event.isChecked == true) {
                      widget.onSelectAll?.call();
                    } else {
                      for (final id in List<String>.from(widget.selectedIds)) {
                        widget.onSelect(id, false);
                      }
                    }
                  } else if (event.isRow && event.row != null) {
                    final id = event.row!.cells['id']?.value?.toString() ?? '';
                    if (id.isNotEmpty && !id.startsWith('new_draft_')) {
                      widget.onSelect(id, event.isChecked);
                    }
                  }
                },
                rowColorCallback: (rowColorContext) {
                  final id = rowColorContext.row.cells['id']?.value?.toString() ?? '';
                  if (id.startsWith('new_draft_')) {
                    return const Color(0xFFF0FDF4); // تمييز الصف المسودة بلون أخضر هادئ
                  }
                  return Colors.white;
                },
                configuration: TrinaGridConfiguration(
                  style: TrinaGridStyleConfig(
                    gridBorderColor: Colors.black87,
                    gridBorderWidth: 1.5,
                    borderColor: Colors.black87,
                    cellVerticalBorderWidth: 1.4,
                    cellHorizontalBorderWidth: 1.4,
                    inactivatedBorderColor: Colors.black87,
                    rowHeight: 74,
                    columnHeight: 60,
                    defaultCellPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    activatedColor: AppColors.brandPrimary.withValues(alpha: 0.08),
                    activatedBorderColor: AppColors.brandPrimary,
                    cellTextStyle: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    columnTextStyle: TextStyle(
                      fontSize: 18.5.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  selectingMode: TrinaGridSelectingMode.cell,
                  enableMoveHorizontalInEditing: true,
                ),
              ),
            ),
          ),
    ],
  ),
);
  }
}

// ─── شاشة العرض الكامل لجدول الإكسيل مع تابات الحالات والشهور ───
class LeadsTableFullScreenPage extends StatefulWidget {
  final ProfileModel? currentUser;
  final String userRole;

  const LeadsTableFullScreenPage({
    super.key,
    this.currentUser,
    required this.userRole,
  });

  @override
  State<LeadsTableFullScreenPage> createState() =>
      _LeadsTableFullScreenPageState();
}

class _LeadsTableFullScreenPageState extends State<LeadsTableFullScreenPage> {
  final GlobalKey<LeadsTableViewState> _tableKey = GlobalKey<LeadsTableViewState>();
  DateTime _selectedMonth = DateTime.now();
  bool _isAllMonths = false;
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedLeadIds = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatMonthYear(DateTime d) {
    const arabicMonths = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${arabicMonths[d.month - 1]} ${d.year}';
  }

  void _changeMonth(DateTime newMonth) {
    setState(() {
      _selectedMonth = DateTime(newMonth.year, newMonth.month, 1);
      _isAllMonths = false;
    });
    _refreshLeads();
  }

  void _setAllMonths() {
    setState(() {
      _isAllMonths = true;
    });
    _refreshLeads();
  }

  void _refreshLeads() {
    final cubit = context.read<LeadCubit>();
    DateTime? fromDate;
    DateTime? toDate;
    if (!_isAllMonths) {
      fromDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      toDate = DateTime(
          _selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);
    }
    cubit.getAllLeads(
      role: widget.userRole,
      userId: widget.currentUser?.id ?? '',
      fromDate: fromDate,
      toDate: toDate,
      isRefresh: true,
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth = !_isAllMonths &&
        _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    final monthLabel = _isAllMonths
        ? 'كل الشهور'
        : _formatMonthYear(_selectedMonth);

    return Container(
      height: 42.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: !_isAllMonths ? AppColors.brandPrimary : Colors.grey.shade400,
          width: !_isAllMonths ? 1.5 : 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, size: 22.sp, color: Colors.grey.shade700),
            tooltip: 'الشهر السابق',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30.w, minHeight: 30.h),
            onPressed: () {
              final base = _isAllMonths ? DateTime.now() : _selectedMonth;
              _changeMonth(DateTime(base.year, base.month - 1, 1));
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'تغيير الشهر',
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            onSelected: (val) {
              if (val == 'ALL') {
                _setAllMonths();
              } else {
                final parts = val.split('-');
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                _changeMonth(DateTime(year, month, 1));
              }
            },
            itemBuilder: (ctx) {
              final items = <PopupMenuEntry<String>>[];
              items.add(
                PopupMenuItem<String>(
                  value: 'ALL',
                  child: Row(
                    children: [
                      Icon(Icons.all_inclusive_rounded, size: 19.sp, color: _isAllMonths ? AppColors.brandPrimary : Colors.grey),
                      SizedBox(width: 8.w),
                      Text('جميع الشهور', style: TextStyle(fontSize: 14.sp, fontWeight: _isAllMonths ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                ),
              );
              items.add(const PopupMenuDivider());
              for (int i = 0; i < 12; i++) {
                final d = DateTime(now.year, now.month - i, 1);
                final isThis = !_isAllMonths && _selectedMonth.year == d.year && _selectedMonth.month == d.month;
                items.add(
                  PopupMenuItem<String>(
                    value: '${d.year}-${d.month}',
                    child: Text(_formatMonthYear(d) + (i == 0 ? ' (الحالي)' : ''), style: TextStyle(fontSize: 14.sp, fontWeight: isThis ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }
              return items;
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18.sp, color: !_isAllMonths ? AppColors.brandPrimary : Colors.grey.shade700),
                  SizedBox(width: 5.w),
                  Text(monthLabel, style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold, color: !_isAllMonths ? AppColors.brandPrimary : Colors.black87)),
                  if (isCurrentMonth) ...[
                    SizedBox(width: 5.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                      decoration: BoxDecoration(color: AppColors.brandPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4.r)),
                      child: Text('الحالي', style: TextStyle(fontSize: 10.5.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                    ),
                  ],
                  Icon(Icons.arrow_drop_down, size: 18.sp, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, size: 22.sp, color: Colors.grey.shade700),
            tooltip: 'الشهر التالي',
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 30.w, minHeight: 30.h),
            onPressed: () {
              final base = _isAllMonths ? DateTime.now() : _selectedMonth;
              _changeMonth(DateTime(base.year, base.month + 1, 1));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterBar(String currentFilter, LeadCubit cubit) {
    final filters = [
      {'key': 'الكل', 'label': 'الكل', 'icon': Icons.apps_rounded},
      {'key': 'لم يتم التواصل', 'label': 'لم يتم التواصل', 'icon': Icons.mark_chat_unread_rounded},
      {'key': 'تم التواصل', 'label': 'تم التواصل', 'icon': Icons.check_circle_outline_rounded},
      {'key': 'مهتم', 'label': 'مهتم', 'icon': Icons.thumb_up_alt_rounded},
      {'key': 'غير مهتم', 'label': 'غير مهتم', 'icon': Icons.cancel_outlined},
      {'key': 'لم يرد', 'label': 'لم يرد', 'icon': Icons.phone_missed_rounded},
      {'key': 'VIP', 'label': 'VIP', 'icon': Icons.star_rounded},
      {'key': 'بروكر', 'label': 'بروكر', 'icon': Icons.handshake_outlined},
      {'key': 'تم التعاقد', 'label': 'تم التعاقد', 'icon': Icons.verified_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((f) {
          final isSelected = currentFilter == f['key'];
          final isHighlight = f['key'] == 'لم يتم التواصل';

          return Padding(
            padding: EdgeInsets.only(left: 5.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: () => cubit.applyQuickFilter(f['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isHighlight ? const Color(0xFFE11D48) : AppColors.brandPrimary)
                      : (isHighlight ? const Color(0xFFFFF1F2) : Colors.white),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? (isHighlight ? const Color(0xFFE11D48) : AppColors.brandPrimary)
                        : (isHighlight ? const Color(0xFFFECDD3) : Colors.grey.shade400),
                    width: isSelected ? 1.5 : 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16.sp,
                      color: isSelected
                          ? Colors.white
                          : (isHighlight ? const Color(0xFFE11D48) : Colors.grey.shade700),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      f['label'] as String,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isHighlight ? const Color(0xFFE11D48) : Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool get _isManagerOrAdmin {
    final r = widget.userRole.toLowerCase();
    return r == 'manager' || r == 'admin' || r == 'ceo';
  }

  void _showBulkReassignDialog(LeadCubit cubit) {
    final state = cubit.state;
    if (state is! LeadLoaded || state.employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد بيانات موظفين متاحة للنقل')),
      );
      return;
    }

    String? selectedEmployeeId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(
            children: [
              Icon(Icons.swap_horiz, color: AppColors.brandPrimary, size: 24.sp),
              SizedBox(width: 8.w),
              const Text('نقل العملاء المحددين', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر الموظف لنقل (${_selectedLeadIds.length}) عميل إليه:'),
              SizedBox(height: 14.h),
              DropdownButtonFormField<String>(
                initialValue: selectedEmployeeId,
                decoration: InputDecoration(
                  labelText: 'الموظف المستلم',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                items: state.employees.map((e) {
                  final name = (e.firstName != null && e.firstName!.isNotEmpty)
                      ? '${e.firstName} ${e.lastName ?? ''}'.trim()
                      : e.email;
                  return DropdownMenuItem(value: e.id, child: Text(name));
                }).toList(),
                onChanged: (val) => setDlgState(() => selectedEmployeeId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: selectedEmployeeId == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _performBulkReassign(cubit, selectedEmployeeId!);
                    },
              child: const Text('تأكيد النقل'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performBulkReassign(LeadCubit cubit, String employeeId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repository = di.sl<LeadRepository>();
      final dataManager = di.sl<StaticDataManager>();
      final notContactedStatusId =
          dataManager.getIdByName('lead_status', 'لم يتم التواصل معه') ??
          dataManager.getIdByName('lead_status', 'لم يتم التواصل') ??
          '460be748-7685-49ef-abcf-c4dd49511ab7';

      for (final id in _selectedLeadIds) {
        await repository.updateLeadStatusAndEmployee(
          id,
          notContactedStatusId,
          employeeId,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نقل العملاء بنجاح 🎉'), backgroundColor: Colors.green),
        );
        setState(() {
          _selectedLeadIds.clear();
        });
        _refreshLeads();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل النقل: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBulkDeleteConfirmationDialog(LeadCubit cubit) {
    if (_selectedLeadIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red.shade700, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('تأكيد حذف العملاء', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف (${_selectedLeadIds.length}) عميل نهائياً؟\nهذا الإجراء سيقوم بحذف العملاء وكافة أرقامهم وملاحظاتهم نهائياً ولا يمكن التراجع عنه.',
          style: TextStyle(fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performBulkDelete(cubit);
            },
            child: const Text('نعم، حذف نهائي'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkDelete(LeadCubit cubit) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = _selectedLeadIds.length;
      await cubit.bulkDeleteLeads(_selectedLeadIds.toList());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف $count عميل بنجاح'), backgroundColor: Colors.red.shade700),
        );
        setState(() {
          _selectedLeadIds.clear();
        });
        _refreshLeads();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LeadCubit>();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('جدول العملاء (عرض كامل) 📊'),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        actions: [
          if (_isManagerOrAdmin && _selectedLeadIds.isNotEmpty) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 18),
              label: Text(
                'نقل (${_selectedLeadIds.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () => _showBulkReassignDialog(cubit),
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18),
              label: Text(
                'حذف (${_selectedLeadIds.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              onPressed: () => _showBulkDeleteConfirmationDialog(cubit),
            ),
            SizedBox(width: 8.w),
            TextButton(
              onPressed: () => setState(() => _selectedLeadIds.clear()),
              child: const Text('إلغاء التحديد', style: TextStyle(color: Colors.grey)),
            ),
            SizedBox(width: 8.w),
          ],
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: _refreshLeads,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _tableKey.currentState?.unfocusGrid();
          FocusScope.of(context).unfocus();
        },
        child: BlocBuilder<LeadCubit, LeadState>(
          builder: (context, state) {
            final String currentFilter = (state is LeadLoaded) ? state.currentFilter : 'الكل';
            final leads = (state is LeadLoaded) ? state.filteredLeads : <LeadModel>[];

            return LeadsTableView(
              key: _tableKey,
              leads: leads,
              isBulkSelectMode: true,
              selectedIds: _selectedLeadIds,
              onSelect: (id, sel) {
                setState(() {
                  if (sel == true) {
                    _selectedLeadIds.add(id);
                  } else {
                    _selectedLeadIds.remove(id);
                  }
                });
              },
              onSelectAll: () {
                final allIds = leads
                    .map((l) => l.id ?? '')
                    .where((id) => id.isNotEmpty)
                    .toList();
                final allSelected = allIds.isNotEmpty &&
                    allIds.every((id) => _selectedLeadIds.contains(id));
                setState(() {
                  if (allSelected) {
                    _selectedLeadIds.removeAll(allIds);
                  } else {
                    _selectedLeadIds.addAll(allIds);
                  }
                });
              },
              scrollController: _scrollController,
              userRole: widget.userRole,
              currentUser: widget.currentUser,
              isFullScreen: true,
              customToolbarFilters: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMonthSelector(),
                  SizedBox(width: 8.w),
                  Container(height: 28.h, width: 1.2.w, color: Colors.grey.shade400),
                  SizedBox(width: 8.w),
                  _buildQuickFilterBar(currentFilter, cubit),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

