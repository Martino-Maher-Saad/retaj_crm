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
    'locations':              _CategoryConfig(label: 'المحافظات والمدن',    icon: Icons.location_on_outlined,   tableName: '',       isLocation: true, color: Color(0xFF374151)),
  };

  String _selectedKey = 'lead_statuses';
  bool _isLoading = true;

  // كل البيانات محمّلة مرة واحدة في الذاكرة
  final Map<String, List<LookupOptionModel>> _cache = {};
  List<Map<String, dynamic>> _govData = [];

  final _addCtrl = TextEditingController();
  int? _selectedGovId;

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
        if (!e.value.isLocation) {
          keys.add(e.key);
          futures.add(_repository.fetchAllForAdmin(e.value.tableName));
        }
      }
      final results = await Future.wait([
        ...futures,
        _repository.fetchGovernoratesWithCitiesForAdmin(),
      ]);
      for (int i = 0; i < keys.length; i++) {
        _cache[keys[i]] = results[i] as List<LookupOptionModel>;
      }
      _govData = results.last as List<Map<String, dynamic>>;
    } catch (e) {
      _showErr('فشل التحميل: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _reloadCurrent() async {
    try {
      if (_cur.isLocation) {
        _govData = await _repository.fetchGovernoratesWithCitiesForAdmin();
      } else {
        _cache[_selectedKey] = await _repository.fetchAllForAdmin(_cur.tableName);
      }
      setState(() {});
    } catch (e) {
      _showErr('خطأ في التحديث');
    }
  }

  Future<void> _addItem() async {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      if (_cur.isLocation) {
        if (_selectedGovId == null) {
          await _repository.addOption('governorates', text, isLocation: true);
        } else {
          await _repository.addOption('cities', text, isLocation: true, governorateId: _selectedGovId);
        }
      } else {
        await _repository.addOption(_cur.tableName, text);
      }
      _addCtrl.clear();
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk('تمت الإضافة ✅');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _edit(String table, LookupOptionModel item, {bool isLoc = false}) async {
    final ctrl = TextEditingController(text: item.nameAr);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل القيمة', style: AppTextStyles.h3),
        content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(labelText: 'الاسم الجديد')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary), child: const Text('حفظ', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (res == null || res.isEmpty || res == item.nameAr) return;
    setState(() => _isLoading = true);
    try {
      await _repository.updateOption(table, item.id, res, isLocation: isLoc);
      await _dataManager.refresh();
      await _reloadCurrent();
      _showOk('تم التعديل — بيتعدل في كل بيانات النظام تلقائياً ✅');
    } catch (e) {
      _showErr('خطأ: $e');
    }
    setState(() => _isLoading = false);
  }

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
                onTap: () => setState(() { _selectedKey = e.key; _selectedGovId = null; }),
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
        child: _cur.isLocation ? _buildLocationsView() : _buildStandardView(),
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

  // ─── Locations ───
  Widget _buildLocationsView() {
    return Padding(
      padding: EdgeInsets.all(28.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLocationAddField(),
        SizedBox(height: 20.h),
        Expanded(
          child: _govData.isEmpty
              ? _emptyState()
              : ListView.separated(
                  itemCount: _govData.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, i) => _govCard(_govData[i]),
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

  Widget _buildLocationAddField() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r), border: Border.all(color: const Color(0xFFEAEAF0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('نوع الإضافة', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        SizedBox(height: 12.h),
        Wrap(spacing: 8.w, children: [
          _typeChip('إضافة محافظة', null),
          ..._govData.map((g) => _typeChip('مدينة في ${g['name']}', g['id'] is int ? g['id'] as int : int.tryParse(g['id'].toString()))),
        ]),
        SizedBox(height: 14.h),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _addCtrl,
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: _selectedGovId == null ? 'اسم المحافظة...' : 'اسم المدينة الجديدة...',
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
      ]),
    );
  }

  Widget _typeChip(String label, int? govId) {
    final sel = _selectedGovId == govId;
    return GestureDetector(
      onTap: () => setState(() => _selectedGovId = govId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        margin: EdgeInsets.only(bottom: 6.h),
        decoration: BoxDecoration(
          color: sel ? _cur.color : const Color(0xFFF0F0F8),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: sel ? _cur.color : const Color(0xFFDDDDEE)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13.sp, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _govCard(Map<String, dynamic> gov) {
    final isActive = _parseBool(gov['is_active']);
    final govId = gov['id'].toString();
    final govName = gov['name']?.toString() ?? '';
    final govModel = LookupOptionModel(id: govId, nameAr: govName, isActive: isActive);
    final rawCities = gov['cities'] as List? ?? [];
    final cities = rawCities.map((c) {
      final m = c as Map<String, dynamic>;
      return LookupOptionModel(
        id: m['id'].toString(),
        nameAr: m['name']?.toString() ?? '',
        isActive: _parseBool(m['is_active']),
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isActive ? const Color(0xFFDDDDEE) : Colors.grey.withValues(alpha: 0.2), width: 1.5),
      ),
      child: ExpansionTile(
        // ─── key فريد يمنع تعارض PageStorage ───
        key: PageStorageKey('gov_$govId'),
        tilePadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        title: Row(children: [
          Icon(Icons.location_city_outlined, size: 20.sp, color: isActive ? _cur.color : Colors.grey),
          SizedBox(width: 10.w),
          Text(govName, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: isActive ? const Color(0xFF1A1A2E) : Colors.grey)),
          SizedBox(width: 10.w),
          if (!isActive)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6.r)),
              child: Text('معطّل', style: TextStyle(fontSize: 12.sp, color: Colors.red)),
            ),
          const Spacer(),
          Text('${cities.length} مدينة', style: TextStyle(fontSize: 13.sp, color: Colors.grey[500])),
          SizedBox(width: 6.w),
        ]),
        trailing: _actions('governorates', govModel, isLoc: true),
        children: [
          if (cities.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text('لا توجد مدن مسجلة', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 24.w, left: 12.w, bottom: 10.h),
              child: Column(
                children: cities.map((city) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: _itemTile('cities', city, isLoc: true),
                )).toList(),
              ),
            ),
        ],
      ),
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
        subtitle: !item.isActive
            ? Text('معطّل — لن يظهر في القوائم الجديدة', style: TextStyle(fontSize: 12.sp, color: Colors.red[300]))
            : null,
        trailing: _actions(table, item, isLoc: isLoc),
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
