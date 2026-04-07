import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/property_image_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';

import '../widgets/property_form_card.dart';
import '../widgets/form_sections/basic_section.dart';
import '../widgets/form_sections/location_section.dart';
import '../widgets/form_sections/technical_section.dart';
import '../widgets/form_sections/status_section.dart';
import '../widgets/form_sections/financial_section.dart';
import '../widgets/form_sections/admin_section.dart';
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
  final dataManager = StaticDataManager();

  // مغيرات الاختيار
  String? selectedListingTypeId;
  String? selectedPropertyTypeId;
  String? selectedGovId;
  String? selectedCityId;

  String? selectedCompletionStatus;
  String? selectedFurnished;
  String? selectedRentalFrequency;
  DateTime? selectedDeliveryDate;

  final List<Uint8List> _newImagesBytes = [];
  List<PropertyImageModel> _existingImages = [];
  final List<PropertyImageModel> _imagesToDeleteObjects = [];

  late Map<String, TextEditingController> _controllers;
  bool status = true;
  bool negotiable = false;
  bool isCompound = false;
  bool hasInstallment = false;
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
      'price': TextEditingController(text: p?.price?.toString() ?? ""),
      'downPayment': TextEditingController(text: p?.downPayment?.toString() ?? ""),
      'monthlyInstall': TextEditingController(text: p?.monthlyInstallation?.toString() ?? ""),
      'monthsInstall': TextEditingController(text: p?.monthsInstallations?.toString() ?? ""),
      'insurance': TextEditingController(text: p?.insurance?.toString() ?? ""),
      'area': TextEditingController(text: p?.builtArea?.toString() ?? ""),
      'landArea': TextEditingController(text: p?.landArea?.toString() ?? ""),
      'gardenArea': TextEditingController(text: p?.gardenArea?.toString() ?? ""),
      'bedrooms': TextEditingController(text: p?.bedrooms?.toString() ?? ""),
      'bathrooms': TextEditingController(text: p?.bathrooms?.toString() ?? ""),
      'kitchens': TextEditingController(text: p?.kitchens?.toString() ?? ""),
      'balconies': TextEditingController(text: p?.balconies?.toString() ?? ""),
      'floor': TextEditingController(text: p?.floor?.toString() ?? ""),
      'totalFloors': TextEditingController(text: p?.totalFloors?.toString() ?? ""),
      'totalApartments': TextEditingController(text: p?.totalApartments?.toString() ?? ""),
      'buildingAge': TextEditingController(text: p?.buildingAge?.toString() ?? ""),
      'ownerName': TextEditingController(text: p?.ownerName),
      'ownerPhone': TextEditingController(text: p?.ownerPhone),
      'internalNotes': TextEditingController(text: p?.internalNotes),
    };

    if (p != null) {
      status = p.status;
      negotiable = p.negotiable ?? false;
      selectedCompletionStatus = p.completionStatus;
      selectedFurnished = p.furnished;
      selectedRentalFrequency = p.rentalFrequency;
      selectedDeliveryDate = p.deliveryDate;
      _existingImages = List.from(p.images);
      isCompound = p.downPayment != null || p.completionStatus != null;
      _syncSelection(p);
      hasInstallment = p.downPayment != null || p.monthlyInstallation != null;
    }
  }

  void _syncSelection(PropertyModel p) {
    try {
      selectedListingTypeId = dataManager.listingTypes.firstWhere((e) => e.nameAr == p.listingTypeAr).id;
      selectedPropertyTypeId = dataManager.propertyTypes.firstWhere((e) => e.nameAr == p.propertyTypeAr).id;
      selectedGovId = dataManager.governorates.firstWhere((g) => g.nameAr == p.governorateAr).id;
      selectedCityId = dataManager.getCitiesByGov(selectedGovId!).firstWhere((c) => c.nameAr == p.cityAr).id;
    } catch (e) { debugPrint("Mapping Sync Error: $e"); }
  }

  bool _shouldShowFloor() {
    if (selectedPropertyTypeId == null) return false;
    const typesWithFloors = [
      'apt', 'duplex', 'penthouse', 'roof', 'studio', 
      'chalet', 'office', 'clinic', 'restaurant_cafe', 'pharmacy'
    ];
    return typesWithFloors.contains(selectedPropertyTypeId);
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
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // ─── الصور — تحتفظ بـ PropertyFormCard الخاص بها ───
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
                      onRemoveNew: (index) =>
                          setState(() => _newImagesBytes.removeAt(index)),
                      onAddPressed: _pick,
                    ),
                  ),

                  // ─── باقي الـ sections تعرض نفسها مع RetajSectionCard الداخلي ───
                  BasicSection(
                    controllers: _controllers,
                    dataManager: dataManager,
                    selectedListingTypeId: selectedListingTypeId,
                    selectedPropertyTypeId: selectedPropertyTypeId,
                    onListingTypeChanged: (v) =>
                        setState(() => selectedListingTypeId = v),
                    onPropertyTypeChanged: (v) =>
                        setState(() => selectedPropertyTypeId = v),
                  ),
                  LocationSection(
                    controllers: _controllers,
                    dataManager: dataManager,
                    selectedGovId: selectedGovId,
                    selectedCityId: selectedCityId,
                    onGovChanged: (v) => setState(() {
                      selectedGovId = v;
                      selectedCityId = null;
                    }),
                    onCityChanged: (v) => setState(() => selectedCityId = v),
                  ),
                  TechnicalSection(
                    controllers: _controllers,
                    selectedPropertyTypeId: selectedPropertyTypeId,
                    selectedFurnished: selectedFurnished,
                    showFloor: _shouldShowFloor(),
                    onFurnishedChanged: (v) =>
                        setState(() => selectedFurnished = v),
                  ),
                  StatusSection(
                    controllers: _controllers,
                    isCompound: isCompound,
                    selectedPropertyTypeId: selectedPropertyTypeId,
                    selectedCompletionStatus: selectedCompletionStatus,
                    selectedDeliveryDate: selectedDeliveryDate,
                    onCompoundChanged: (v) =>
                        setState(() => isCompound = v),
                    onCompletionStatusChanged: (v) =>
                        setState(() => selectedCompletionStatus = v),
                    onDeliveryDateSelected: (v) =>
                        setState(() => selectedDeliveryDate = v),
                  ),
                  FinancialSection(
                    controllers: _controllers,
                    selectedListingTypeId: selectedListingTypeId,
                    selectedRentalFrequency: selectedRentalFrequency,
                    hasInstallment: hasInstallment,
                    negotiable: negotiable,
                    onRentalFrequencyChanged: (v) =>
                        setState(() => selectedRentalFrequency = v),
                    onInstallmentChanged: (v) =>
                        setState(() => hasInstallment = v),
                    onNegotiableChanged: (v) =>
                        setState(() => negotiable = v),
                  ),
                  AdminSection(
                    controllers: _controllers,
                    status: status,
                    onStatusChanged: (v) => setState(() => status = v),
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

  Widget _buildSubmitButton() {
    final bool isEdit = widget.property != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isLoading
          ? Container(
              key: const ValueKey('loading'),
              height: 54.h,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : SizedBox(
              key: const ValueKey('button'),
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add_task, size: 20.sp),
                label: Text(
                  isEdit ? "حفظ التعديلات" : "إضافة العقار",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final listing = dataManager.listingTypes.firstWhere((e) => e.id == selectedListingTypeId);
      final propertyType = dataManager.propertyTypes.firstWhere((e) => e.id == selectedPropertyTypeId);
      final gov = dataManager.governorates.firstWhere((g) => g.id == selectedGovId);
      final city = dataManager.getCitiesByGov(selectedGovId!).firstWhere((c) => c.id == selectedCityId);

      String finalCode = _controllers['propertyCode']!.text;
      if (finalCode.isEmpty) {
        finalCode = "PROP-${DateTime.now().millisecondsSinceEpoch}";
      }

      final model = PropertyModel(
        id: widget.property?.id ?? '',
        propertyCode: finalCode,
        createdBy: widget.userId,
        status: status,
        negotiable: negotiable,
        titleAr: _controllers['titleAr']!.text,
        descAr: _controllers['descAr']!.text,
        listingTypeAr: listing.nameAr,
        propertyTypeAr: propertyType.nameAr,
        governorateAr: gov.nameAr,
        cityAr: city.nameAr,
        regionAr: _controllers['regionAr']!.text,
        locationInDetails: _controllers['locDetails']!.text,
        locationMap: _controllers['locMap']!.text,
        price: num.tryParse(_controllers['price']!.text.replaceAll(',', '')),
        downPayment: num.tryParse(_controllers['downPayment']!.text.replaceAll(',', '')),
        monthlyInstallation: num.tryParse(_controllers['monthlyInstall']!.text.replaceAll(',', '')),
        insurance: num.tryParse(_controllers['insurance']!.text),
        monthsInstallations: int.tryParse(_controllers['monthsInstall']!.text),
        builtArea: int.tryParse(_controllers['area']!.text),
        landArea: int.tryParse(_controllers['landArea']!.text),
        gardenArea: int.tryParse(_controllers['gardenArea']!.text),
        bedrooms: int.tryParse(_controllers['bedrooms']!.text),
        bathrooms: int.tryParse(_controllers['bathrooms']!.text),
        kitchens: int.tryParse(_controllers['kitchens']!.text),
        balconies: int.tryParse(_controllers['balconies']!.text),
        floor: int.tryParse(_controllers['floor']!.text),
        totalFloors: int.tryParse(_controllers['totalFloors']!.text),
        totalApartments: int.tryParse(_controllers['totalApartments']!.text),
        buildingAge: int.tryParse(_controllers['buildingAge']!.text),
        deliveryDate: selectedDeliveryDate,
        completionStatus: selectedCompletionStatus,
        furnished: selectedFurnished,
        rentalFrequency: selectedRentalFrequency,
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
