import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/retaj_shared_fields.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/property_image_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';

import '../widgets/property_form_card.dart';
import '../widgets/form_sections/image_section.dart';

class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? property;
  final String userId;

  const PropertyFormScreen({super.key, this.property, required this.userId});

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
    _controllers = {
      'propertyCode': TextEditingController(text: p?.propertyCode),
      'titleAr': TextEditingController(text: p?.titleAr),
      'descAr': TextEditingController(text: p?.descAr),
      'regionAr': TextEditingController(text: p?.regionAr),
      'locDetails': TextEditingController(text: p?.locationInDetails),
      'locMap': TextEditingController(text: p?.locationMap),
      'price': TextEditingController(text: p?.price.toString() ?? ""),
      'ownerName': TextEditingController(text: p?.ownerName),
      'ownerPhone': TextEditingController(text: p?.ownerPhone),
      'internalNotes': TextEditingController(text: p?.internalNotes),
    };

    if (p != null) {
      status = p.status;
      _existingImages = List.from(p.images);
      
      selectedListingType = p.listingTypeAr;
      selectedPropertyType = p.propertyTypeAr;
      
      try {
        final gov = dataManager.governorates.firstWhere((g) => g.name == p.governorateAr);
        selectedGovId = gov.id;
        selectedCityName = p.cityAr;
      } catch (_) {}
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
          appBar: AppBar(
            title: Text(widget.property == null ? "إضافة إعلان" : "تعديل إعلان"),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
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
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['descAr']!,
                          label: "الوصف التفصيلي",
                          hint: "اكتب وصف العقار...",
                          maxLines: 4,
                        ),
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['propertyCode']!,
                          label: "كود العقار (اختياري)",
                          hint: "مثال: PR-1234",
                        ),
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['price']!,
                          label: "السعر",
                          hint: "مثال: 1500000",
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                "نوع الإعلان",
                                dataManager.getOptions('listing_type'),
                                selectedListingType,
                                (v) => setState(() => selectedListingType = v),
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: _buildDropdown(
                                "نوع العقار",
                                dataManager.getOptions('property_type'),
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
                                items: dataManager.governorates
                                    .map(
                                      (g) => DropdownMenuItem<int>(
                                        value: g.id,
                                        child: Text(g.name),
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
                                value: selectedCityName,
                                items: selectedGovId == null
                                    ? []
                                    : dataManager
                                        .getCitiesByGovId(selectedGovId!)
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
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['regionAr']!,
                          label: "المنطقة (اختياري)",
                          hint: "مثال: الحي المتميز",
                        ),
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['locDetails']!,
                          label: "العنوان التفصيلي (اختياري - للإدارة فقط)",
                          hint: "مثال: شارع التسعين، عمارة 5",
                        ),
                        SizedBox(height: 14.h),
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
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['ownerPhone']!,
                          label: "رقم هاتف المالك",
                          hint: "مثال: 01000000000",
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 14.h),
                        RetajTextField(
                          controller: _controllers['internalNotes']!,
                          label: "ملاحظات إدارية (اختياري)",
                          hint: "أرقام هواتف إضافية، ملاحظات خاصة...",
                          maxLines: 3,
                        ),
                        SizedBox(height: 14.h),
                        SwitchListTile(
                          title: const Text("حالة العقار (متاح؟)"),
                          value: status,
                          activeColor: AppColors.brandPrimary,
                          onChanged: (v) => setState(() => status = v),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30.h),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Colors.black12)),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return RetajDropdown<String>(
      label: hint,
      value: value,
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
    );
  }

  Widget _buildSubmitButton() {
    final bool isEdit = widget.property != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isLoading
          ? Container(
              key: const ValueKey('loading'),
              height: 58.h,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.brandPrimary),
            )
          : SizedBox(
              key: const ValueKey('button'),
              width: double.infinity,
              height: 58.h,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add_task, size: 24.sp),
                label: Text(
                  isEdit ? "حفظ التعديلات" : "إضافة العقار",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_newImagesBytes.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى إضافة صورة واحدة على الأقل للعقار"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String finalCode = _controllers['propertyCode']!.text;
      if (finalCode.isEmpty) {
        finalCode = "PROP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      }

      String govName = dataManager.governorates.firstWhere((g) => g.id == selectedGovId).name;

      final model = PropertyModel(
        id: widget.property?.id ?? '',
        propertyCode: finalCode,
        createdBy: widget.userId,
        status: status,
        titleAr: _controllers['titleAr']!.text,
        descAr: _controllers['descAr']!.text,
        listingTypeAr: selectedListingType!,
        propertyTypeAr: selectedPropertyType!,
        governorateAr: govName,
        cityAr: selectedCityName!,
        regionAr: _controllers['regionAr']!.text,
        locationInDetails: _controllers['locDetails']!.text,
        locationMap: _controllers['locMap']!.text,
        price: num.tryParse(_controllers['price']!.text.replaceAll(',', '')) ?? 0,
        ownerName: _controllers['ownerName']!.text,
        ownerPhone: _controllers['ownerPhone']!.text,
        internalNotes: _controllers['internalNotes']!.text,
        images: _existingImages,
      );

      if (widget.property == null) {
        context.read<PropertiesCubit>().addProperty(model, _newImagesBytes);
      } else {
        context.read<PropertiesCubit>().updateProperty(
          property: model,
          newImages: _newImagesBytes,
          imagesToDelete: _imagesToDeleteObjects,
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
