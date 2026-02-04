import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../data/models/property_image_model.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';

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

  List<Uint8List> _newImagesBytes = [];
  List<PropertyImageModel> _existingImages = [];
  List<PropertyImageModel> _imagesToDeleteObjects = [];

  late Map<String, TextEditingController> _controllers;
  bool status = true;
  bool negotiable = false;
  bool isCompound = false;
  bool hasInstallment = false; // للتحكم في ظهور حقول التقسيط

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
      _existingImages = p.images != null ? List.from(p.images!) : [];
      // تحديد حالة الكمبوند بناءً على وجود بيانات مالية أو حالة تشطيب
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
    // 1. إذا لم يتم اختيار نوع عقار بعد، لا تظهر الحقل
    if (selectedPropertyTypeId == null) return false;

    // 2. قائمة بالأنواع التي تتطلب "رقم دور" (استخدم الـ IDs الجديدة في الـ JSON)
    const typesWithFloors = [
      'apt',               // شقة
      'duplex',            // دوبلكس
      'penthouse',         // بنتهاوس
      'roof',              // روف
      'studio',            // استوديو
      'chalet',            // شاليه
      'office',            // مكتب
      'clinic',            // عيادة
      'restaurant_cafe',   // مطعم وكافيه
      'pharmacy'           // صيدلية
    ];

    // 3. التحقق المباشر
    return typesWithFloors.contains(selectedPropertyTypeId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertiesCubit, PropertiesState>(
      listener: (context, state) {
        if (state is PropertiesSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ البيانات بنجاح")));
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(title: Text(widget.property == null ? "إضافة إعلان" : "تعديل إعلان"), centerTitle: true),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildCard("الصور", Icons.photo_camera, _buildImageSection()),
                _buildCard("المعلومات الأساسية", Icons.assignment, _buildBasicSection()),
                _buildCard("الموقع", Icons.map, _buildLocationSection()),
                _buildCard("المواصفات الفنية", Icons.straighten, _buildTechnicalSection()),
                _buildCard("حالة العقار", Icons.info_outline, _buildStatusSection()),
                _buildCard("بيانات السعر", Icons.payments, _buildFinancialSection()),
                _buildCard("الإدارة", Icons.admin_panel_settings, _buildAdminSection()),
                SizedBox(height: 24.h),
                _buildSubmitButton(),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalSection() {
    bool isLand = selectedPropertyTypeId == 'land';
    bool showFloor = _shouldShowFloor();
    // استخدام IDs الجديدة للتحقق من السكني
    bool isResidential = selectedPropertyTypeId == 'apartment' ||
        selectedPropertyTypeId == 'villa' ||
        selectedPropertyTypeId == 'chalet';

    return Column(children: [
      if (isLand) _buildField(_controllers['landArea']!, "مساحة الأرض الكلية", num: true, req: true),
      if (!isLand) ...[
        _buildField(_controllers['area']!, "المساحة المبنية (BUA)", num: true, req: true),
        Row(children: [
          Expanded(child: _buildField(_controllers['bedrooms']!, "الغرف", num: true)),
          SizedBox(width: 8.w),
          Expanded(child: _buildField(_controllers['bathrooms']!, "الحمامات", num: true)),
        ]),
        Row(children: [
          Expanded(child: _buildField(_controllers['kitchens']!, "المطابخ", num: true)),
          SizedBox(width: 8.w),
          Expanded(child: _buildField(_controllers['balconies']!, "البلكونات", num: true)),
        ]),

        if (showFloor)
          _buildField(_controllers['floor']!, "رقم الدور", num: true),

        if (isResidential)
          _buildFixedDrop("مفروش؟", ["yes", "no"], selectedFurnished, (v) => setState(() => selectedFurnished = v)),

        if (selectedPropertyTypeId == 'villa' || selectedPropertyTypeId == 'building') ...[
          _buildField(_controllers['totalFloors']!, "عدد الأدوار", num: true),
          if (selectedPropertyTypeId == 'building') _buildField(_controllers['totalApartments']!, "عدد الشقق", num: true),
          _buildField(_controllers['gardenArea']!, "مساحة الحديقة", num: true),
          _buildField(_controllers['landArea']!, "مساحة الأرض الكلية", num: true),
        ],
      ]
    ]);
  }

  Widget _buildBasicSection() {
    return Column(children: [
      _buildField(_controllers['propertyCode']!, "كود العقار"),
      _buildJsonDrop("نوع الإدراج", dataManager.listingTypes, selectedListingTypeId, (v) => setState(() => selectedListingTypeId = v)),
      Row(children: [
        Expanded(child: _buildJsonDrop("نوع العقار", dataManager.propertyTypes, selectedPropertyTypeId, (v) => setState(() { selectedPropertyTypeId = v;}))),
        SizedBox(width: 8.w),
      ]),
      _buildField(_controllers['titleAr']!, "العنوان بالعربي", req: true),
      _buildField(_controllers['descAr']!, "الوصف بالعربي", long: true, req: true),
    ]);
  }

  Widget _buildLocationSection() {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildJsonDrop("المحافظة", dataManager.governorates, selectedGovId, (v) => setState(() { selectedGovId = v; selectedCityId = null; }))),
        SizedBox(width: 8.w),
        Expanded(child: _buildJsonDrop("المدينة", selectedGovId != null ? dataManager.getCitiesByGov(selectedGovId!) : [], selectedCityId, (v) => setState(() => selectedCityId = v))),
      ]),
      Row(children: [
        Expanded(child: _buildField(_controllers['regionAr']!, "المنطقة بالعربي", req: true)),
        SizedBox(width: 8.w),
      ]),
      _buildField(_controllers['locDetails']!, "العنوان التفصيلي", req: true),
      _buildField(_controllers['locMap']!, "رابط جوجل ماب"),
    ]);
  }

  Widget _buildStatusSection() {
    return Column(children: [
      SwitchListTile(title: const Text("داخل كمبوند"), value: isCompound, onChanged: (v) => setState(() => isCompound = v)),
      if (isCompound) ...[
        _buildFixedDrop("حالة التشطيب", ["ready", "off-plan"], selectedCompletionStatus, (v) => setState(() => selectedCompletionStatus = v)),
        if (selectedCompletionStatus == "off-plan")
          _buildDatePicker("تاريخ الاستلام المتوقع"),
      ],
      if (selectedPropertyTypeId != 'land' && !isCompound)
        _buildField(_controllers['buildingAge']!, "عمر العقار", num: true),
    ]);
  }

  /*Widget _buildFinancialSection() {
    bool isRent = selectedListingTypeId == 'rent';
    return Column(children: [
      _buildField(_controllers['price']!, isRent ? "قيمة الإيجار" : "السعر الكلي", num: true, req: true),
      if (isRent) ...[
        _buildFixedDrop("الدورية", ["daily", "weekly", "monthly", "yearly"], selectedRentalFrequency, (v) => setState(() => selectedRentalFrequency = v)),
        _buildField(_controllers['insurance']!, "قيمة التأمين", num: true),
      ],
      if (!isRent && isCompound) ...[
        Row(children: [
          Expanded(child: _buildField(_controllers['downPayment']!, "المقدم", num: true)),
          SizedBox(width: 8.w),
          Expanded(child: _buildField(_controllers['monthlyInstall']!, "القسط", num: true)),
        ]),
        _buildField(_controllers['monthsInstall']!, "مدة التقسيط (شهور)", num: true),
      ],
      CheckboxListTile(title: const Text("السعر قابل للتفاوض"), value: negotiable, onChanged: (v) => setState(() => negotiable = v!)),
    ]);
  }*/
  Widget _buildFinancialSection() {
    // معرفة هل الإدراج الحالي "بيع" (نفترض أن ID البيع هو 'sale' حسب الـ StaticDataManager)
    bool isSale = selectedListingTypeId == 'sale';
    bool isRent = selectedListingTypeId == 'rent';

    return Column(children: [
      _buildField(_controllers['price']!, isRent ? "قيمة الإيجار" : "السعر الكلي", num: true, req: true),

      if (isRent) ...[
        _buildFixedDrop("الدورية", ["daily", "weekly", "monthly", "yearly"], selectedRentalFrequency, (v) => setState(() => selectedRentalFrequency = v)),
        _buildField(_controllers['insurance']!, "قيمة التأمين", num: true),
      ],

      // حقول التقسيط تظهر فقط في حالة البيع
      if (isSale) ...[
        SwitchListTile(
          title: const Text("يوجد نظام تقسيط؟"),
          value: hasInstallment,
          onChanged: (v) => setState(() => hasInstallment = v),
        ),
        if (hasInstallment) ...[
          Row(children: [
            Expanded(child: _buildField(_controllers['downPayment']!, "المقدم", num: true)),
            SizedBox(width: 8.w),
            Expanded(child: _buildField(_controllers['monthlyInstall']!, "القسط الشهري", num: true)),
          ]),
          _buildField(_controllers['monthsInstall']!, "مدة التقسيط (شهور)", num: true),
        ],
      ],

      CheckboxListTile(title: const Text("السعر قابل للتفاوض"), value: negotiable, onChanged: (v) => setState(() => negotiable = v!)),
    ]);
  }

  Widget _buildAdminSection() {
    return Column(children: [
      _buildField(_controllers['ownerName']!, "اسم المالك"),
      _buildField(_controllers['ownerPhone']!, "رقم المالك"),
      _buildField(_controllers['internalNotes']!, "ملاحظات إدارية", long: true),
      SwitchListTile(title: const Text("نشط (يظهر للعملاء)"), value: status, onChanged: (v) => setState(() => status = v)),
    ]);
  }

  /*Widget _buildSubmitButton() {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        bool isLoading = state is PropertiesLoading;
        return ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, minimumSize: Size(double.infinity, 54.h)),
          child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("حفظ العقار", style: TextStyle(color: Colors.white)),
        );
      },
    );
  }*/
  Widget _buildSubmitButton() {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        // التحقق من حالة التحميل
        bool isLoading = state is PropertiesLoading;

        return Container(
          width: double.infinity,
          height: 54.h,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
              : ElevatedButton(
            onPressed: _submit, // الدالة المستدعاة
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text("حفظ العقار", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        );
      },
    );
  }


  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    try {
      // جلب البيانات من الـ DataManager بناءً على الاختيارات
      final listing = dataManager.listingTypes.firstWhere((e) => e.id == selectedListingTypeId);
      final propertyType = dataManager.propertyTypes.firstWhere((e) => e.id == selectedPropertyTypeId);
      final gov = dataManager.governorates.firstWhere((g) => g.id == selectedGovId);
      final city = dataManager.getCitiesByGov(selectedGovId!).firstWhere((c) => c.id == selectedCityId);

      // تجهيز كود العقار (لأن الأسكيما تطلبه NOT NULL)
      // إذا كان تعديل نأخذ الكود القديم، إذا كان جديد نولد كود مؤقت أو نأخذه من الحقل
      String finalCode = _controllers['propertyCode']!.text;
      if (finalCode.isEmpty) {
        finalCode = "PROP-${DateTime.now().millisecondsSinceEpoch}";
      }

      final model = PropertyModel(
        // إذا كان تعديل نرسل الـ ID، إذا كان جديد نرسل نص فارغ ليتجاهله الموديل في الـ toJson
        id: widget.property?.id ?? '',
        propertyCode: finalCode,
        createdBy: widget.userId, // الـ userId قادم من السكرينة السابقة وهو مطلوب (UUID)
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

        // تحويل القيم الرقمية بشكل آمن
        price: num.tryParse(_controllers['price']!.text),
        downPayment: num.tryParse(_controllers['downPayment']!.text),
        monthlyInstallation: num.tryParse(_controllers['monthlyInstall']!.text),
        insurance: num.tryParse(_controllers['insurance']!.text),
        monthsInstallations: int.tryParse(_controllers['monthsInstall']!.text),

        // المواصفات الفنية
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

        // المواعيد والحالة
        deliveryDate: selectedDeliveryDate,
        completionStatus: selectedCompletionStatus,
        furnished: selectedFurnished,
        rentalFrequency: selectedRentalFrequency,

        // بيانات التواصل والملاحظات
        ownerName: _controllers['ownerName']!.text,
        ownerPhone: _controllers['ownerPhone']!.text,
        internalNotes: _controllers['internalNotes']!.text,

        // الصور الحالية (في حالة التعديل)
        images: _existingImages,
      );

      if (widget.property == null) {
        // حالة الإضافة
        context.read<PropertiesCubit>().addProperty(model, _newImagesBytes);
      } else {
        // حالة التعديل
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
    }
  }

// ... بقية الـ Widgets كما هي

  // --- Widgets UI Helpers ---
  Widget _buildCard(String title, IconData icon, Widget child) => Container(
    margin: EdgeInsets.only(bottom: 16.h),
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey.shade200)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 20.sp, color: AppColors.primaryBlue), SizedBox(width: 8.w), Text(title, style: AppTextStyles.blue16Bold)]),
      const Divider(height: 24),
      child,
    ]),
  );

  Widget _buildField(TextEditingController ctrl, String label, {bool num = false, bool long = false, bool req = false}) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: TextFormField(
      controller: ctrl,
      maxLines: long ? 3 : 1,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
      validator: (v) => (req && (v == null || v.isEmpty)) ? "حقل مطلوب" : null,
    ),
  );

  Widget _buildJsonDrop(String label, List<dynamic> items, String? val, Function(String?) onChg) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: DropdownButtonFormField<String>(
      value: val, onChanged: onChg,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
      items: items.map((i) => DropdownMenuItem(value: i.id.toString(), child: Text(i.nameAr))).toList(),
    ),
  );

  Widget _buildFixedDrop(String label, List<String> items, String? val, Function(String?) onChg) => Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: DropdownButtonFormField<String>(
      value: items.contains(val) ? val : null, onChanged: onChg,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r))),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toUpperCase()))).toList(),
    ),
  );

  Widget _buildDatePicker(String label) => ListTile(
    title: Text(selectedDeliveryDate == null ? label : DateFormat('yyyy-MM-dd').format(selectedDeliveryDate!)),
    trailing: const Icon(Icons.calendar_today),
    onTap: () async {
      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2040));
      if (d != null) setState(() => selectedDeliveryDate = d);
    },
  );

  Widget _buildImageSection() {
    return SizedBox(
      height: 110.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._existingImages.map((img) => _imgBox(CachedNetworkImage(imageUrl: img.imageUrl!, fit: BoxFit.cover),
              onDel: () => setState(() { _imagesToDeleteObjects.add(img); _existingImages.remove(img); }))),
          ..._newImagesBytes.asMap().entries.map((e) => _imgBox(Image.memory(e.value, fit: BoxFit.cover),
              onDel: () => setState(() => _newImagesBytes.removeAt(e.key)))),
          if ((_newImagesBytes.length + _existingImages.length) < 10) _addImgBtn(),
        ],
      ),
    );
  }

  Widget _imgBox(Widget img, {required VoidCallback onDel}) => Container(
    width: 90.w, margin: EdgeInsets.only(right: 8.w),
    child: Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(8.r), child: SizedBox.expand(child: img)), Positioned(top: 2, right: 2, child: GestureDetector(onTap: onDel, child: CircleAvatar(radius: 11.r, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14.sp, color: Colors.white))))]),
  );

  Widget _addImgBtn() => GestureDetector(onTap: _pick, child: Container(width: 90.w, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8.r)), child: const Icon(Icons.add_a_photo, color: Colors.blue)));

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