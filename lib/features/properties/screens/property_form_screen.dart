import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/property_image_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';

import '../widgets/property_form_card.dart';
import '../widgets/form_sections/image_section.dart';

class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? property;
  final String userId;
  final String userRole;

  const PropertyFormScreen({
    super.key,
    this.property,
    required this.userId,
    required this.userRole,
  });

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dataManager = di.sl<StaticDataManager>();

  // مغيرات الاختيار
  String? selectedListingType;
  String? selectedPropertyType;
  int? selectedGovId;
  String? selectedCityName;
  String? selectedSource;
  List<String> selectedPlatforms = [];

  final List<Uint8List> _newImagesBytes = [];
  List<PropertyImageModel> _existingImages = [];
  final List<PropertyImageModel> _imagesToDeleteObjects = [];

  late Map<String, TextEditingController> _controllers;
  bool status = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final p = widget.property;
    final priceStr = p?.price != null ? p!.price.toCurrency() : '';
    _controllers = {
      'propertyCode': TextEditingController(text: p?.propertyCode),
      'titleAr': TextEditingController(text: p?.titleAr),
      'descAr': TextEditingController(text: p?.descAr),
      'regionAr': TextEditingController(text: p?.regionAr),
      'locDetails': TextEditingController(text: p?.locationInDetails),
      'locMap': TextEditingController(text: p?.locationMap),
      'price': TextEditingController(text: priceStr),
      'ownerName': TextEditingController(text: p?.ownerName),
      'ownerPhone': TextEditingController(text: p?.ownerPhone),
      'internalNotes': TextEditingController(text: p?.internalNotes),
    };

    if (p != null) {
      status = p.status;
      _existingImages = List.from(p.images);
      selectedListingType = p.listingTypeAr;
      selectedPropertyType = p.propertyTypeAr;
      selectedSource = p.source;
      selectedPlatforms = widget.property!.advertisingPlatforms
          .map((p) => p.nameAr)
          .where((name) => name.isNotEmpty)
          .toList();

      // أولاً: جرب من الـ governorateId الجديد مباشرة
      if (p.governorateId != null) {
        selectedGovId = p.governorateId;
        selectedCityName = p.cityAr;
      } else {
        // Fallback: ابحث باسم المحافظة (للسجلات القديمة)
        try {
          final gov = dataManager.governorates.firstWhere((g) => g.name == p.governorateAr);
          selectedGovId = gov.id;
          selectedCityName = p.cityAr;
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PropertiesCubit, PropertiesState>(
      listener: (context, state) {
        if (state is PropertiesSuccess) {
          if (!_isLoading) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ البيانات بنجاح ✅"), backgroundColor: Colors.green),
          );
          setState(() => _isLoading = false);
          Navigator.pop(context);
        } else if (state is PropertiesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5FB),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.w),
              child: Column(
                children: [
                  // ─── Page Header ───
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 28.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.property == null ? 'إضافة عقار جديد' : 'تعديل بيانات العقار',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'أدخل تفاصيل العقار والصور وجميع البيانات المطلوبة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: const Color(0xFFAAAABB),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                            label: const Text('رجوع'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFAAAABB)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  PropertyFormCard(
                    title: "الصور",
                    icon: Icons.photo_camera_outlined,
                    stepNumber: 1,
                    child: ImageSection(
                      existingImages: _existingImages,
                      newImagesBytes: _newImagesBytes,
                      onRemoveExisting: (img) => setState(() {
                        _imagesToDeleteObjects.add(img);
                        _existingImages.remove(img);
                      }),
                      onRemoveNew: (index) => setState(() => _newImagesBytes.removeAt(index)),
                      onAddPressed: _pick,
                    ),
                  ),

                  PropertyFormCard(
                    title: "البيانات الأساسية",
                    icon: Icons.info_outline,
                    stepNumber: 2,
                    child: Column(
                      children: [
                        RetajTextField(
                          controller: _controllers['titleAr']!,
                          label: "عنوان الإعلان بالعربي",
                          hint: "مثال: شقة سوبر لوكس للبيع",
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['descAr']!,
                          label: "الوصف التفصيلي *",
                          hint: "اكتب وصف العقار...",
                          maxLines: null,
                          minLines: 3,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'يرجى إدخال وصف العقار';
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['propertyCode']!,
                          label: "كود العقار (اختياري)",
                          hint: "مثال: PR-1234",
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['price']!,
                          label: "السعر *",
                          hint: "مثال: 1,500,000",
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            NumberFormatter(),
                          ],
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'يرجى إدخال السعر';
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                "نوع الإعلان",
                                dataManager.getActiveOptions('listing_type', includeValue: selectedListingType),
                                selectedListingType,
                                (v) => setState(() => selectedListingType = v),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: _buildDropdown(
                                "نوع العقار",
                                dataManager.getActiveOptions('property_type', includeValue: selectedPropertyType),
                                selectedPropertyType,
                                (v) => setState(() => selectedPropertyType = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  PropertyFormCard(
                    title: "الموقع",
                    icon: Icons.location_on_outlined,
                    stepNumber: 3,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RetajDropdown<int>(
                                label: "المحافظة",
                                value: selectedGovId,
                                items: dataManager.getActiveGovernorates(includeId: selectedGovId)
                                    .map(
                                      (gov) => DropdownMenuItem<int>(
                                        value: gov.id,
                                        child: Text(gov.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedGovId = v;
                                    selectedCityName = null;
                                  });
                                },
                                validator: (v) => v == null ? 'مطلوب' : null,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: RetajDropdown<String>(
                                label: "المدينة",
                                value: selectedCityName != null &&
                                            dataManager
                                                .getActiveCitiesByGovId(selectedGovId!, includeName: selectedCityName)
                                                .any((c) => c.name == selectedCityName)
                                        ? selectedCityName
                                        : null,
                                items: selectedGovId == null
                                    ? []
                                    : dataManager
                                        .getActiveCitiesByGovId(selectedGovId!, includeName: selectedCityName)
                                        .map((c) => c.name)
                                        .toSet()
                                        .map(
                                          (name) => DropdownMenuItem<String>(
                                            value: name,
                                            child: Text(name),
                                          ),
                                        )
                                        .toList(),
                                onChanged: selectedGovId == null
                                    ? null
                                    : (v) => setState(() => selectedCityName = v),
                                validator: (v) => v == null ? 'مطلوب' : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['regionAr']!,
                          label: "المنطقة (اختياري)",
                          hint: "مثال: الحي المتميز",
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['locDetails']!,
                          label: "العنوان التفصيلي (اختياري - للإدارة فقط)",
                          hint: "مثال: شارع التسعين، عمارة 5",
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['locMap']!,
                          label: "رابط خريطة جوجل (اختياري)",
                          hint: "https://maps.google.com/...",
                        ),
                      ],
                    ),
                  ),

                  PropertyFormCard(
                    title: "بيانات المالك والإدارة",
                    icon: Icons.admin_panel_settings_outlined,
                    stepNumber: 4,
                    child: Column(
                      children: [
                        RetajTextField(
                          controller: _controllers['ownerName']!,
                          label: "اسم المالك",
                          hint: "مثال: أحمد محمد",
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['ownerPhone']!,
                          label: "رقم هاتف المالك *",
                          hint: "مثال: 01000000000",
                          keyboardType: TextInputType.phone,
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'يرجى إدخال رقم هاتف المالك';
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        RetajTextField(
                          controller: _controllers['internalNotes']!,
                          label: "ملاحظات إدارية (اختياري)",
                          hint: "أرقام هواتف إضافية، ملاحظات خاصة...",
                          maxLines: null,
                          minLines: 3,
                        ),
                        SizedBox(height: 24.h),
                        SwitchListTile(
                          title: const Text("حالة العقار (متاح؟)"),
                          value: status,
                          activeColor: AppColors.brandPrimary,
                          onChanged: (v) => setState(() => status = v),
                        ),
                      ],
                    ),
                  ),

                  PropertyFormCard(
                    title: "مصدر العقار ومنصات الإعلان",
                    icon: Icons.campaign_outlined,
                    stepNumber: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdown(
                          "مصدر العقار (اختياري)",
                          dataManager.getActiveOptions('property_source', includeValue: selectedSource),
                          selectedSource,
                          (v) => setState(() => selectedSource = v),
                          required: false,
                        ),
                        if (widget.userRole == 'admin' || widget.userRole == 'ceo') ...[
                          SizedBox(height: 24.h),
                          Text(
                            "منصات الإعلان (اختياري)",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF555566),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Wrap(
                            spacing: 10.w,
                            runSpacing: 8.h,
                            children: dataManager.getActiveOptions('advertising_platforms').map((platform) {
                              final isSelected = selectedPlatforms.contains(platform);
                              return FilterChip(
                                label: Text(
                                  platform,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF555566),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedPlatforms.add(platform);
                                    } else {
                                      selectedPlatforms.remove(platform);
                                    }
                                  });
                                },
                                selectedColor: AppColors.brandPrimary,
                                backgroundColor: const Color(0xFFF0F0F8),
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? AppColors.brandPrimary : const Color(0xFFDDDDEE),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  _buildSubmitButton(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged, {
    bool required = true,
  }) {
    final List<String> validItems = items.toSet().toList();
    if (value != null && !validItems.contains(value)) {
      validItems.insert(0, value);
    }

    return RetajDropdown<String>(
      label: hint,
      value: value,
      items: validItems
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      validator: required ? (v) => v == null || v.isEmpty ? 'مطلوب' : null : null,
    );
  }

  Widget _buildSubmitButton() {
    final bool isEdit = widget.property != null;
    if (_isLoading) {
      return Container(
        height: 64.h,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    }
    return Row(
      children: [
        // ─── زر حفظ العقار ───
        Expanded(
          flex: 3,
          child: Container(
            height: 64.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              gradient: LinearGradient(
                colors: [AppColors.brandPrimary, AppColors.brandPrimary.withValues(alpha: 0.8)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _submit,
                borderRadius: BorderRadius.circular(14.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      isEdit ? 'حفظ التعديلات' : 'حفظ العقار',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // ─── زر إلغاء ───
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 64.h,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF888899),
                side: const BorderSide(color: Color(0xFFDDDDEE), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text('إلغاء',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newImagesBytes.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إضافة صورة واحدة على الأقل للعقار"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ─── Smart Comparison (وضع التعديل فقط) ───
    if (widget.property != null) {
      final p = widget.property!;

      // مقارنة الحقول النصية والـ IDs
      final bool dataChanged =
          _controllers['titleAr']!.text         != p.titleAr                  ||
          _controllers['descAr']!.text          != p.descAr                   ||
          _controllers['price']!.text           != p.price.toString()          ||
          _controllers['propertyCode']!.text    != (p.propertyCode ?? '')      ||
          _controllers['regionAr']!.text        != (p.regionAr ?? '')          ||
          _controllers['locDetails']!.text      != (p.locationInDetails ?? '') ||
          _controllers['locMap']!.text          != (p.locationMap ?? '')       ||
          _controllers['internalNotes']!.text   != (p.internalNotes ?? '')     ||
          _controllers['ownerName']!.text       != (p.ownerName ?? '')         ||
          _controllers['ownerPhone']!.text      != (p.ownerPhone ?? '')        ||
          selectedPropertyType                  != p.propertyTypeAr            ||
          selectedListingType                   != p.listingTypeAr             ||
          selectedSource                        != p.source                    ||
          selectedGovId                         != p.governorateId             ||
          selectedCityName                      != p.cityAr                    ||
          status                                != p.status;

      // مقارنة المنصات الإعلانية
      final selectedSorted = selectedPlatforms.toList()..sort();
      final existingSorted = p.advertisingPlatforms.map((e) => e.nameAr).toList()..sort();
      final bool platformsChanged = selectedSorted.join('|') != existingSorted.join('|');

      // مقارنة الصور
      final bool imagesChanged = _newImagesBytes.isNotEmpty || _imagesToDeleteObjects.isNotEmpty;

      if (!dataChanged && !platformsChanged && !imagesChanged) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم إجراء أي تعديلات — البيانات كما هي ✅'),
            backgroundColor: Colors.blueGrey,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      String finalCode = _controllers['propertyCode']!.text;
      if (finalCode.isEmpty) {
        finalCode = "PROP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      }

      // تحويل الاختيارات النصية إلى IDs
      final propertyTypeId = selectedPropertyType != null
          ? dataManager.getIdByName('property_type', selectedPropertyType!)
          : null;
      final listingTypeId = selectedListingType != null
          ? dataManager.getIdByName('listing_type', selectedListingType!)
          : null;
      final sourceId = selectedSource != null
          ? dataManager.getIdByName('property_source', selectedSource!)
          : null;

      // المدينة: احصل على الـ ID من الـ name
      int? cityId;
      if (selectedGovId != null && selectedCityName != null) {
        try {
          final cityObj = dataManager
              .getCitiesByGovId(selectedGovId!)
              .firstWhere((c) => c.name == selectedCityName);
          cityId = cityObj.id;
        } catch (_) {}
      }

      // اسم المحافظة للعرض النصي (legacy fields)
      String govName = '';
      if (selectedGovId != null) {
        try {
          govName = dataManager.governorates.firstWhere((g) => g.id == selectedGovId).name;
        } catch (_) {}
      }

      final model = PropertyModel(
        id: widget.property?.id ?? '',
        propertyCode: finalCode,
        createdBy: widget.userId,
        status: status,
        titleAr: _controllers['titleAr']!.text,
        descAr: _controllers['descAr']!.text,
        // النصوص للعرض
        listingTypeAr: selectedListingType ?? '',
        propertyTypeAr: selectedPropertyType ?? '',
        governorateAr: govName,
        cityAr: selectedCityName ?? '',
        source: selectedSource,
        // IDs للحفظ
        propertyTypeId: propertyTypeId,
        listingTypeId: listingTypeId,
        sourceId: sourceId,
        governorateId: selectedGovId,
        cityId: cityId,
        regionAr: _controllers['regionAr']!.text,
        locationInDetails: _controllers['locDetails']!.text,
        locationMap: _controllers['locMap']!.text,
        price: num.tryParse(_controllers['price']!.text.replaceAll(',', '')) ?? 0,
        ownerName: _controllers['ownerName']!.text,
        ownerPhone: _controllers['ownerPhone']!.text,
        internalNotes: _controllers['internalNotes']!.text,
        images: _existingImages,
        advertisingPlatforms: const [],
        // تعيين حالة الاعتماد عند الإضافة
        approvalStatusId: widget.property == null 
            ? '634f7e69-6161-4535-b409-d1ea1bbbdcd3'
            : widget.property!.approvalStatusId,
      );

      // حل أسماء المنصات إلى IDs
      final platformIds = selectedPlatforms
          .map((name) => dataManager.getIdByName('advertising_platform', name))
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (widget.property == null) {
        final phone = _controllers['ownerPhone']!.text;
        final duplicates = await context.read<PropertiesCubit>().checkDuplicates(phone);
        final myDuplicates = duplicates.where((d) => d.createdBy == widget.userId).toList();

        if (myDuplicates.isNotEmpty) {
          setState(() => _isLoading = false);
          final dup = myDuplicates.first;
          
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
                  SizedBox(width: 10.w),
                  const Text('تحذير: رقم مكرر!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("يوجد عقار آخر مضاف بواسطتك يمتلك نفس رقم المالك (أو يتطابق في آخر 6 أرقام).", style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 15.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("عنوان العقار: ${dup.titleAr}", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900)),
                        SizedBox(height: 5.h),
                        Text("رقم المالك: ${dup.ownerPhone}", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.brandPrimary)),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Text("هل أنت متأكد أنك تريد إضافة هذا العقار كعقار جديد على أي حال؟", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء', style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('إضافة على أي حال', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
                ),
              ],
            ),
          );

          if (confirm != true) return;
          setState(() => _isLoading = true);
        }

        if (mounted) {
          context.read<PropertiesCubit>().addProperty(model, _newImagesBytes, platformIds: platformIds);
        }
      } else {
        context.read<PropertiesCubit>().updateProperty(
          property: model,
          newImages: _newImagesBytes,
          imagesToDelete: _imagesToDeleteObjects,
          platformIds: platformIds,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في معالجة البيانات: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    for (var f in picked) {
      if ((_newImagesBytes.length + _existingImages.length) < 10) {
        final b = await f.readAsBytes();
        setState(() => _newImagesBytes.add(b));
      }
    }
  }
}
