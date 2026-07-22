import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/repositories/dropdown_repository.dart';
import '../../../../data/services/dropdown_service.dart';
import '../../../../core/di/injection_container.dart' as di;

// ─── Helper: تحويل is_active لـ bool بأمان ───
bool _parseBool(dynamic val) {
  if (val == null) return true;
  if (val is bool) return val;
  if (val is int) return val != 0;
  return true;
}

class DropdownManagementScreen extends StatefulWidget {
  const DropdownManagementScreen({super.key});

  @override
  State<DropdownManagementScreen> createState() => _DropdownManagementScreenState();
}

class _CategoryConfig {
  final String label;
  final IconData icon;
  final String tableName;
  final bool isLocation;
  final Color color;
  const _CategoryConfig({required this.label, required this.icon, required this.tableName, this.isLocation = false, required this.color});
}

class _DropdownManagementScreenState extends State<DropdownManagementScreen> {
  final _repository = di.sl<DropdownRepository>();
  final _dataManager = di.sl<StaticDataManager>();

  static const Map<String, _CategoryConfig> _cats = {
    'lead_statuses':          _CategoryConfig(label: 'حالات العملاء',      icon: Icons.flag_outlined,          tableName: 'lead_statuses',          color: Color(0xFF2E3192)),
    'lead_platforms':         _CategoryConfig(label: 'منصات العملاء',       icon: Icons.campaign_outlined,      tableName: 'lead_platforms',         color: Color(0xFF7C3AED)),
    'communication_channels': _CategoryConfig(label: 'قنوات التواصل',       icon: Icons.contact_phone_outlined, tableName: 'communication_channels', color: Color(0xFF0F766E)),
    'property_types':         _CategoryConfig(label: 'أنواع العقارات',      icon: Icons.home_outlined,          tableName: 'property_types',         color: Color(0xFFB45309)),
    'listing_types':          _CategoryConfig(label: 'أنواع الإعلانات',     icon: Icons.list_alt_outlined,      tableName: 'listing_types',          color: Color(0xFF0369A1)),
    'property_sources':       _CategoryConfig(label: 'مصادر العقارات',      icon: Icons.source_outlined,        tableName: 'property_sources',       color: Color(0xFF065F46)),
    'advertising_platforms':  _CategoryConfig(label: 'منصات الإعلان',       icon: Icons.ads_click_outlined,     tableName: 'advertising_platforms',  color: Color(0xFFB91C1C)),
    'lead_exclusion_reasons': _CategoryConfig(label: 'أسباب الاستبعاد',      icon: Icons.block_outlined,         tableName: 'lead_exclusion_reasons', color: Color(0xFFDC2626)),
    'property_approval_statuses': _CategoryConfig(label: 'حالات الموافقة',     icon: Icons.verified_user_outlined, tableName: 'property_approval_statuses', color: Color(0xFF047857)),
    'stage_types':            _CategoryConfig(label: 'أنواع المراحل (Stage)', icon: Icons.linear_scale,           tableName: 'stage_types',            color: Color(0xFF4338CA)),
    'task_statuses':          _CategoryConfig(label: 'حالات المهام',       icon: Icons.task_alt_outlined,      tableName: 'task_statuses',          color: Color(0xFF059669)),
    'meeting_types':          _CategoryConfig(label: 'أنواع الاجتماعات',   icon: Icons.handshake_outlined,     tableName: 'meeting_types',          color: Color(0xFFD97706)),
    'meeting_purposes':       _CategoryConfig(label: 'أغراض الاجتماعات',  icon: Icons.lightbulb_outline,      tableName: 'meeting_purposes',       color: Color(0xFFEA580C)),
    'activity_types':         _CategoryConfig(label: 'أنواع الأنشطة',      icon: Icons.local_activity_outlined,tableName: 'activity_types',         color: Color(0xFF4F46E5)),
    'lead_rates':             _CategoryConfig(label: 'تقييمات العملاء',      icon: Icons.star_rate_outlined,     tableName: 'lead_rates',             color: Color(0xFFF59E0B)),
    'locations':              _CategoryConfig(label: 'المدن والمناطق',    icon: Icons.location_on_outlined,   tableName: 'cities',       isLocation: true, color: Color(0xFF374151)),
  };

  String _selectedKey = 'lead_statuses';
  bool _isLoading = true;

  // كل البيانات محمّلة مرة واحدة في الذاكرة
  final Map<String, List<LookupOptionModel>> _cache = {};

  final _addCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  _CategoryConfig get _cur => _cats[_selectedKey]!;
  List<LookupOptionModel> get _items => _cache[_selectedKey] ?? [];

  // ─── تحميل كل الجداول دفعة واحدة ───
  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final futures = <Future>[];
      final keys = <String>[];
      for (final e in _cats.entries) {
        keys.add(e.key);
        futures.add(_repository.fetchAllForAdmin(e.value.tableName, isLocation: e.value.isLocation));
      }
      final results = await Future.wait(futures);
      for (int i = 0; i < keys.length; i++) {
        _cache[keys[i]] = results[i] as List<LookupOptionModel>;
      }
    } catch (e) {
      _showErr('فشل التحميل: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _reloadCurrent() async {
    try {
      _cache[_selectedKey] = await _repository.fetchAllForAdmin(_cur.tableName, isLocation: _cur.isLocation);
      setState(() {});
    } catch (e) {
      _showErr('خطأ في التحديث');
    }
  }

  Future<void> _showItemForm({String? table, LookupOptionModel? item, bool isLoc = false}) async {
    final t = table ?? _cur.tableName;
    final isEdit = item != null;
    final ctrl = TextEditingController(text: item?.nameAr ?? '');
    
    String? selectedStageTypeId = item?.extra?['stage_type_id'];
    String? delayValueStr = item?.extra?['delay_value']?.toString();
    String? selectedDelayUnit = item?.extra?['delay_unit'] ?? 'days';
    String? selectedBehavior = item?.extra?['behavior'];
    bool isDefault = item?.extra?['is_default'] == true;
    
    final stageTypes = _dataManager.getOptionModels('stage_types');

    final res = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'تعديل القيمة' : 'إضافة قيمة جديدة', style: AppTextStyles.h3),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'الاسم'),
                    ),
                    if (t == 'lead_statuses') ...[
                      SizedBox(height: 16.h),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'مرحلة العميل (Stage Type)', border: OutlineInputBorder()),
                        value: selectedStageTypeId,
                        items: stageTypes.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nameAr))).toList(),
                        onChanged: (v) => setDialogState(() => selectedStageTypeId = v),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: delayValueStr,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'مدة التأخير (رقم)', border: OutlineInputBorder()),
                              onChanged: (v) => delayValueStr = v,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'وحدة الزمن', border: OutlineInputBorder()),
                              value: selectedDelayUnit,
                              items: const [
                                DropdownMenuItem(value: 'minutes', child: Text('دقائق')),
                                DropdownMenuItem(value: 'hours', child: Text('ساعات')),
                                DropdownMenuItem(value: 'days', child: Text('أيام')),
                              ],
                              onChanged: (v) => setDialogState(() => selectedDelayUnit = v),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      CheckboxListTile(
                        title: const Text('تعيين كحالة افتراضية (Default)'),
                        subtitle: const Text('يتم تعيين هذه الحالة تلقائياً للعملاء الجدد', style: TextStyle(fontSize: 12)),
                        value: isDefault,
                        onChanged: (v) => setDialogState(() => isDefault = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    if (t == 'stage_types') ...[
                      SizedBox(height: 16.h),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'نوع السلوك (Behavior)', border: OutlineInputBorder()),
                        value: selectedBehavior,
                        items: const [
                          DropdownMenuItem(value: 'following', child: Text('متابعة')),
                          DropdownMenuItem(value: 'meeting', child: Text('اجتماع')),
                          DropdownMenuItem(value: 'exclusion', child: Text('استبعاد')),
                          DropdownMenuItem(value: 'done_deal', child: Text('تعاقد')),
                          DropdownMenuItem(value: 'fresh', child: Text('جديد')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedBehavior = v),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, {
                      'name': ctrl.text.trim(),
                      if (t == 'lead_statuses') 'extra': {
                        'stage_type_id': selectedStageTypeId,
                        'delay_value': int.tryParse(delayValueStr ?? ''),
                        'delay_unit': selectedDelayUnit,
                        'is_default': isDefault,
                      },
                      if (t == 'stage_types') 'extra': {
                        'behavior': selectedBehavior,
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                  child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );

    if (res == null) return;
    final newName = res['name'] as String;
    final extraData = res['extra'] as Map<String, dynamic>?;

    setState(() => _isLoading = true);
    try {
      if (isEdit) {
        await _repository.updateOption(t, item!.id, newName, isLocation: isLoc, extraData: extraData);
      } else {
        await _repository.addOption(t, newName, isLocation: isLoc, extraData: extraData);
      }
      
      if (!isEdit && !isLoc) _addCtrl.clear();
      
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk(isEdit ? 'تم التعديل ✅' : 'تمت الإضافة ✅');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addItem() => _showItemForm(isLoc: _cur.isLocation);
  Future<void> _edit(String table, LookupOptionModel item, {bool isLoc = false}) => _showItemForm(table: table, item: item, isLoc: isLoc);

  Future<void> _toggle(String table, LookupOptionModel item) async {
    final deactivate = item.isActive;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deactivate ? 'تعطيل "${item.nameAr}"' : 'تفعيل "${item.nameAr}"', style: AppTextStyles.h3),
        content: Text(
          deactivate
              ? 'هتختفي من القوائم المنسدلة.\nالبيانات القديمة المرتبطة بيها مش هتتأثر.'
              : 'هتظهر في القوائم تاني.',
          style: const TextStyle(height: 1.7),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: deactivate ? Colors.red : AppColors.success),
            child: Text(deactivate ? 'تعطيل' : 'تفعيل', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isLoading = true);
    try {
      if (deactivate) {
        await _repository.deactivateOption(table, item.id);
      } else {
        await _repository.activateOption(table, item.id);
      }
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk(deactivate ? 'تم تعطيل "${item.nameAr}"' : 'تم تفعيل "${item.nameAr}"');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showOk(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.success, duration: const Duration(seconds: 2)));
  void _showErr(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : Row(children: [_buildSidebar(), Expanded(child: _buildContent())]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250.w,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFEAEAF0), width: 1.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 12.h),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('إدارة القوائم', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
            SizedBox(height: 4.h),
            Text('أضف، عدّل، أو عطّل أي قيمة', style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
          ]),
        ),
        const Divider(),
        SizedBox(height: 8.h),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            children: _cats.entries.map((e) {
              final sel = _selectedKey == e.key;
              return GestureDetector(
                onTap: () => setState(() { _selectedKey = e.key; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(bottom: 4.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                  decoration: BoxDecoration(
                    color: sel ? e.value.color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    border: sel ? Border.all(color: e.value.color.withValues(alpha: 0.35)) : null,
                  ),
                  child: Row(children: [
                    Icon(e.value.icon, size: 22.sp, color: sel ? e.value.color : Colors.grey[500]),
                    SizedBox(width: 12.w),
                    Expanded(child: Text(e.value.label, style: TextStyle(fontSize: 15.sp, fontWeight: sel ? FontWeight.w700 : FontWeight.normal, color: sel ? e.value.color : Colors.grey[700]))),
                    if (!e.value.isLocation)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                        decoration: BoxDecoration(color: e.value.color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20.r)),
                        child: Text(
                          '${_cache[e.key]?.where((x) => x.isActive).length ?? 0}',
                          style: TextStyle(fontSize: 12.sp, color: e.value.color, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    return Column(children: [
      // ─── Header ───
      Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
        color: Colors.white,
        child: Row(children: [
          Icon(_cur.icon, color: _cur.color, size: 30.sp),
          SizedBox(width: 14.w),
          Text(_cur.label, style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w800, color: const Color(0xFF1A1A2E))),
          const Spacer(),
          if (!_cur.isLocation)
            Text('${_items.where((i) => i.isActive).length} نشط  /  ${_items.length} إجمالي', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: _buildStandardView(),
      ),
    ]);
  }

  // ─── Standard ───
  Widget _buildStandardView() {
    return Padding(
      padding: EdgeInsets.all(28.w),
      child: Column(children: [
        _buildAddField(),
        SizedBox(height: 20.h),
        Expanded(
          child: _items.isEmpty
              ? _emptyState()
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, i) => _itemTile(_cur.tableName, _items[i]),
                ),
        ),
      ]),
    );
  }



  Widget _buildAddField() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: const Color(0xFFEAEAF0))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _addCtrl,
            onSubmitted: (_) => _addItem(),
            style: TextStyle(fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: 'اكتب قيمة جديدة ثم اضغط إضافة...',
              filled: true, fillColor: const Color(0xFFF8F8FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
        SizedBox(width: 14.w),
        ElevatedButton.icon(
          onPressed: _addItem,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('إضافة', style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _cur.color,
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      ]),
    );
  }

  Widget _itemTile(String table, LookupOptionModel item, {bool isLoc = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: item.isActive ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: item.isActive ? const Color(0xFFEAEAF0) : Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
        leading: Container(
          width: 11.r, height: 11.r,
          decoration: BoxDecoration(shape: BoxShape.circle, color: item.isActive ? _cur.color : Colors.grey[400]),
        ),
        title: Text(
          item.nameAr,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: item.isActive ? const Color(0xFF1A1A2E) : Colors.grey,
            decoration: item.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (table == 'lead_statuses' && item.extra != null) ...[
              SizedBox(height: 6.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 4.h,
                children: [
                  _buildChip(
                    Icons.linear_scale,
                    _dataManager.getOptionModels('stage_types').firstWhere(
                          (e) => e.id == item.extra!['stage_type_id'],
                          orElse: () => const LookupOptionModel(id: '', nameAr: 'غير محدد'),
                        ).nameAr,
                    Colors.indigo,
                  ),
                  if (item.extra!['delay_value'] != null)
                    _buildChip(
                      Icons.timer_outlined,
                      '${item.extra!['delay_value']} ${item.extra!['delay_unit'] == 'minutes' ? 'دقائق' : item.extra!['delay_unit'] == 'hours' ? 'ساعات' : 'أيام'}',
                      Colors.orange,
                    ),
                  if (item.extra!['is_default'] == true)
                    _buildChip(Icons.star_rounded, 'الافتراضية', Colors.amber),
                ],
              ),
              SizedBox(height: 6.h),
            ],
            if (!item.isActive)
              Text('معطّل — لن يظهر في القوائم الجديدة', style: TextStyle(fontSize: 12.sp, color: Colors.red[300])),
          ],
        ),
        trailing: _actions(table, item, isLoc: isLoc),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _actions(String table, LookupOptionModel item, {bool isLoc = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
        icon: Icon(Icons.edit_outlined, size: 22.sp, color: AppColors.info),
        tooltip: 'تعديل',
        onPressed: () => _edit(table, item, isLoc: isLoc),
      ),
      IconButton(
        icon: Icon(
          item.isActive ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
          size: 30.sp,
          color: item.isActive ? AppColors.success : Colors.grey[400],
        ),
        tooltip: item.isActive ? 'تعطيل' : 'تفعيل',
        onPressed: () => _toggle(table, item),
      ),
      if (table == 'lead_statuses')
        IconButton(
          icon: Icon(Icons.delete_forever_outlined, size: 22.sp, color: Colors.red),
          tooltip: 'حذف نهائي',
          onPressed: () => _hardDelete(table, item),
        ),
    ]);
  }

  Future<void> _hardDelete(String table, LookupOptionModel item) async {
    if (table != 'lead_statuses') return;

    setState(() => _isLoading = true);
    int leadsCount = 0;
    try {
      leadsCount = await _repository.countLeadsWithStatus(item.id);
    } catch (e) {
      _showErr('فشل في التحقق من عدد العملاء المرتبطين بالحالة: $e');
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = false);

    String? replaceWithId;
    bool canDelete = leadsCount == 0;
    
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: Text('تحذير: حذف نهائي لـ "${item.nameAr}"', style: const TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadsCount > 0) ...[
                Text('هذه الحالة مرتبطة بـ $leadsCount عميل! بمسح هذه الحالة، يجب نقل جميع العملاء المرتبطين بها إلى حالة أخرى.'),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  hint: const Text('اختر الحالة البديلة'),
                  value: replaceWithId,
                  items: _cache['lead_statuses']
                      ?.where((s) => s.id != item.id && s.isActive)
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameAr)))
                      .toList() ?? [],
                  onChanged: (v) {
                    setStateSB(() {
                      replaceWithId = v;
                      canDelete = v != null;
                    });
                  },
                ),
              ] else ...[
                const Text('لا يوجد عملاء مرتبطين بهذه الحالة. هل أنت متأكد من مسحها نهائياً؟'),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: canDelete ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(leadsCount > 0 ? 'نقل العملاء وحذف' : 'حذف', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    if (leadsCount > 0 && replaceWithId == null) return;

    setState(() => _isLoading = true);
    try {
      await _repository.deleteLeadStatus(item.id, replaceWithId);
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk(leadsCount > 0 ? 'تم المسح ونقل العملاء بنجاح ✅' : 'تم المسح بنجاح ✅');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.list_alt_outlined, size: 60.sp, color: Colors.grey.withValues(alpha: 0.3)),
      SizedBox(height: 16.h),
      Text('لا توجد عناصر بعد', style: TextStyle(fontSize: 18.sp, color: Colors.grey[500])),
    ]));
  }
}
