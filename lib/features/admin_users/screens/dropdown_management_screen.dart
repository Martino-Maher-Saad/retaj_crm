import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/static_data_manager.dart';
import '../../../../data/repositories/dropdown_repository.dart';
import '../../../../data/services/dropdown_service.dart';
import '../../../../core/di/injection_container.dart' as di;

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
    'cities':                 _CategoryConfig(label: 'المدن',               icon: Icons.location_city_outlined, tableName: 'cities',       isLocation: true, color: Color(0xFF374151)),
  };

  String _selectedKey = 'lead_statuses';
  bool _isLoading = true;
  final Map<String, List<LookupOptionModel>> _cache = {};

  final _addArCtrl = TextEditingController();
  final _addEnCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _addArCtrl.dispose();
    _addEnCtrl.dispose();
    super.dispose();
  }

  _CategoryConfig get _cur => _cats[_selectedKey]!;
  List<LookupOptionModel> get _items => _cache[_selectedKey] ?? [];

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final futures = <Future>[];
      final keys = <String>[];
      for (final e in _cats.entries) {
        keys.add(e.key);
        if (e.key == 'cities') {
          futures.add(_repository.fetchCitiesOnly());
        } else {
          futures.add(_repository.fetchAllForAdmin(e.value.tableName));
        }
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
      if (_selectedKey == 'cities') {
        _cache[_selectedKey] = await _repository.fetchCitiesOnly();
      } else {
        _cache[_selectedKey] = await _repository.fetchAllForAdmin(_cur.tableName);
      }
      setState(() {});
    } catch (e) {
      _showErr('خطأ في التحديث');
    }
  }

  Future<void> _addItem() async {
    final textAr = _addArCtrl.text.trim();
    final textEn = _addEnCtrl.text.trim();
    if (textAr.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final order = _items.length; // Appending at the end
      if (_selectedKey == 'cities') {
        // Just use governorate_id = 1 as dummy since we hide it. We assume 1 exists.
        await _repository.addOption('cities', textAr, nameEn: textEn, listOrder: order, isLocation: true, governorateId: 1);
      } else {
        await _repository.addOption(_cur.tableName, textAr, nameEn: textEn, listOrder: order);
      }
      _addArCtrl.clear();
      _addEnCtrl.clear();
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk('تمت الإضافة بنجاح ✅');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _edit(String table, LookupOptionModel item, {bool isLoc = false}) async {
    final arCtrl = TextEditingController(text: item.nameAr);
    final enCtrl = TextEditingController(text: item.nameEn);
    final res = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل القيمة', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: arCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'الاسم بالعربية')),
            SizedBox(height: 10.h),
            TextField(controller: enCtrl, decoration: const InputDecoration(labelText: 'الاسم بالإنجليزية (اختياري)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {'ar': arCtrl.text.trim(), 'en': enCtrl.text.trim()}),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (res == null || res['ar']!.isEmpty) return;
    if (res['ar'] == item.nameAr && res['en'] == item.nameEn) return;

    setState(() => _isLoading = true);
    try {
      await _repository.updateOption(table, item.id, res['ar']!, nameEn: res['en']!, listOrder: item.listOrder, isLocation: isLoc);
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk('تم التعديل — يتحدث تلقائياً في كل الصفحات ✅');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggle(String table, LookupOptionModel item) async {
    final deactivate = item.isActive;
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

  Future<void> _hardDelete(String table, LookupOptionModel item) async {
    final activeOthers = _items.where((e) => e.isActive && e.id != item.id).toList();
    if (activeOthers.isEmpty) {
      _showErr('لا يوجد عناصر أخرى نشطة لنقل البيانات إليها!');
      return;
    }

    String? selectedNewId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('حذف نهائي ونقل بيانات', style: AppTextStyles.h3.copyWith(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('هذا الإجراء سيحذف "${item.nameAr}" نهائياً من النظام.', style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10.h),
                const Text('لتجنب فقدان البيانات، يرجى اختيار القيمة البديلة التي سيتم نقل جميع السجلات المرتبطة (عملاء، عقارات.. الخ) إليها:'),
                SizedBox(height: 20.h),
                DropdownButtonFormField<String>(
                  value: selectedNewId,
                  hint: const Text('اختر القيمة البديلة...'),
                  items: activeOthers.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nameAr))).toList(),
                  onChanged: (v) => setDialogState(() => selectedNewId = v),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: selectedNewId == null ? null : () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('تأكيد الحذف والنقل', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );

    if (confirmed != true || selectedNewId == null) return;

    setState(() => _isLoading = true);
    try {
      await _repository.hardDeleteOption(table, item.id, selectedNewId!);
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk('تم الحذف ونقل البيانات بنجاح ✅');
    } catch (e) {
      _showErr('حدث خطأ أثناء النقل: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    setState(() {}); // Optimistic UI update

    // API update in background
    try {
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].listOrder != i) {
          await _repository.updateOption(_cur.tableName, _items[i].id, _items[i].nameAr, nameEn: _items[i].nameEn, listOrder: i, isLocation: _cur.isLocation);
        }
      }
      await _dataManager.refresh();
      await _reloadCurrent();
    } catch (e) {
      _showErr('خطأ أثناء إعادة الترتيب');
      _reloadCurrent(); // Revert
    }
  }

  void _showOk(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: AppColors.success, duration: const Duration(seconds: 2)));
  void _showErr(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FB),
      body: Row(children: [_buildSidebar(), Expanded(child: _buildContent())]),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260.w,
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
            Text('أضف، عدّل، رتب، أو عطّل', style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
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
                onTap: () => setState(() => _selectedKey = e.key),
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
          Text('${_items.where((i) => i.isActive).length} نشط  /  ${_items.length} إجمالي', style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)) : _buildStandardView(),
      ),
    ]);
  }

  Widget _buildStandardView() {
    return Padding(
      padding: EdgeInsets.all(28.w),
      child: Column(children: [
        _buildAddField(),
        SizedBox(height: 20.h),
        Expanded(
          child: _items.isEmpty
              ? _emptyState()
              : ReorderableListView.builder(
                  itemCount: _items.length,
                  onReorder: _reorder,
                  buildDefaultDragHandles: false, // We'll add custom handle
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return _itemTile(_cur.tableName, item, i, key: ValueKey(item.id));
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildAddField() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: const Color(0xFFEAEAF0))),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _addArCtrl,
            style: TextStyle(fontSize: 15.sp),
            decoration: InputDecoration(
              hintText: 'الاسم بالعربية...',
              filled: true, fillColor: const Color(0xFFF8F8FC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _addEnCtrl,
            onSubmitted: (_) => _addItem(),
            style: TextStyle(fontSize: 15.sp),
            decoration: InputDecoration(
              hintText: 'الاسم بالإنجليزية...',
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

  Widget _itemTile(String table, LookupOptionModel item, int index, {required Key key}) {
    return Container(
      key: key,
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: item.isActive ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: item.isActive ? const Color(0xFFEAEAF0) : Colors.grey.withValues(alpha: 0.15)),
        boxShadow: item.isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))] : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(Icons.drag_indicator, color: Colors.grey[400], size: 26.sp),
        ),
        title: Text(
          item.nameAr,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: item.isActive ? const Color(0xFF1A1A2E) : Colors.grey,
            decoration: item.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Row(
          children: [
            if (item.nameEn.isNotEmpty) ...[
              Text(item.nameEn, style: TextStyle(fontSize: 13.sp, color: Colors.grey[500])),
              SizedBox(width: 8.w),
            ],
            if (!item.isActive)
              Text('• معطّل', style: TextStyle(fontSize: 12.sp, color: Colors.red[300])),
          ],
        ),
        trailing: _actions(table, item, isLoc: _cur.isLocation),
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
      Container(width: 1, height: 24, color: Colors.grey[300], margin: EdgeInsets.symmetric(horizontal: 8.w)),
      IconButton(
        icon: Icon(Icons.delete_outline, size: 22.sp, color: Colors.red[400]),
        tooltip: 'حذف نهائي ونقل',
        onPressed: () => _hardDelete(table, item),
      ),
    ]);
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.list_alt_outlined, size: 60.sp, color: Colors.grey.withValues(alpha: 0.3)),
      SizedBox(height: 16.h),
      Text('لا توجد عناصر بعد', style: TextStyle(fontSize: 18.sp, color: Colors.grey[500])),
    ]));
  }
}

