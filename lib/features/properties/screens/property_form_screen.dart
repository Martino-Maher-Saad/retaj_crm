import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/property_model.dart';
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
  late Map<String, TextEditingController> _controllers;
  List<String> _imagesToDelete = [];

  // الحالات المختارة
  String? _selectedCity, _selectedType, _selectedCategory, _selectedFinishing;
  bool _isAvailable = true;
  bool _isLastFloor = false;
  bool _flatShare = false;

  List<Uint8List> _newImagesBytes = [];
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final p = widget.property;
    _controllers = {
      'descAr': TextEditingController(text: p?.descAr),
      'descEn': TextEditingController(text: p?.descEn),
      'price': TextEditingController(text: p?.price.toString()),
      'area': TextEditingController(text: p?.area.toString()),
      'rooms': TextEditingController(text: p?.rooms.toString()),
      'baths': TextEditingController(text: p?.baths.toString()),
      'lounges': TextEditingController(text: p?.lounges.toString()),
      'kitchens': TextEditingController(text: p?.kitchens.toString()),
      'balconies': TextEditingController(text: p?.balconies.toString()),
      'floor': TextEditingController(text: p?.floor.toString()),
      'locAr': TextEditingController(text: p?.locationAr),
      'locEn': TextEditingController(text: p?.locationEn),
      'locMap': TextEditingController(text: p?.locationMap),
      'ownerName': TextEditingController(text: p?.ownerName),
      'ownerPhone': TextEditingController(text: p?.ownerPhone),
    };

    _selectedCity = p?.city;
    _selectedType = p?.type;
    _selectedCategory = p?.category;
    _selectedFinishing = p?.finishing_type;
    _isAvailable = p?.isAvailable ?? true;
    _isLastFloor = p?.is_last_floor ?? false;
    _flatShare = p?.flat_share ?? false;
    _existingImages = p?.images != null ? List.from(p!.images) : [];
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  PropertyModel _mapFieldsToModel() {
    return PropertyModel(
      id: widget.property?.id ?? '',
      descAr: _controllers['descAr']!.text,
      descEn: _controllers['descEn']!.text,
      price: double.tryParse(_controllers['price']!.text) ?? 0.0,
      area: double.tryParse(_controllers['area']!.text) ?? 0.0,
      rooms: int.tryParse(_controllers['rooms']!.text) ?? 0,
      baths: int.tryParse(_controllers['baths']!.text) ?? 0,
      lounges: int.tryParse(_controllers['lounges']!.text) ?? 0,
      kitchens: int.tryParse(_controllers['kitchens']!.text) ?? 0,
      balconies: int.tryParse(_controllers['balconies']!.text) ?? 0,
      floor: int.tryParse(_controllers['floor']!.text) ?? 0,
      locationAr: _controllers['locAr']!.text,
      locationEn: _controllers['locEn']!.text,
      locationMap: _controllers['locMap']!.text,
      ownerName: _controllers['ownerName']!.text,
      ownerPhone: _controllers['ownerPhone']!.text,
      city: _selectedCity ?? '',
      type: _selectedType ?? '',
      category: _selectedCategory ?? '',
      finishing_type: _selectedFinishing ?? '',
      isAvailable: _isAvailable,
      createdAt: widget.property?.createdAt ?? DateTime.now(),
      is_last_floor: _isLastFloor,
      flat_share: _flatShare,
      createdBy: widget.property?.createdBy ?? widget.userId,
      images: _existingImages,
    );
  }

  // دالة الحفظ التي تستدعي الكيوبت مباشرة
  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<PropertiesCubit>();
    final model = _mapFieldsToModel();

    if (widget.property == null) {
      // حالة الإضافة: نرسل الموديل والصور الجديدة فقط
      cubit.addProperty(model, _newImagesBytes);
    } else {
      // حالة التعديل: نرسل الموديل، الصور الجديدة، وقائمة الروابط المراد حذفها
      cubit.updateProperty(
        property: model,
        newImages: _newImagesBytes,
        imagesToDelete: _imagesToDelete, // 👈 هذه القائمة التي تجمع فيها الروابط عند الضغط على (X)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertiesCubit, PropertiesState>(
      // الاستماع لحالة النجاح أو الفشل للتحكم في الواجهة
      listener: (context, state) {
        if (state is PropertiesSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم حفظ البيانات بنجاح"), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // العودة للخلف بعد النجاح فقط
        } else if (state is PropertiesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.property == null ? "إضافة عقار جديد" : "تعديل العقار"),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("صور العقار"),
                _buildImagePicker(),
                const Divider(height: 32),

                _sectionTitle("المعلومات الأساسية"),
                _dropdownField("التصنيف", ["Residential", "Commercial", "Administrative"], (v) => setState(() => _selectedCategory = v), _selectedCategory),
                Row(children: [
                  Expanded(child: _dropdownField("المدينة", ["Zayed", "October", "Cairo"], (v) => setState(() => _selectedCity = v), _selectedCity)),
                  const SizedBox(width: 10),
                  Expanded(child: _dropdownField("النوع", ["Sale", "Rent"], (v) => setState(() => _selectedType = v), _selectedType)),
                ]),

                _sectionTitle("تفاصيل الوحدة"),
                Row(children: [
                  Expanded(child: _customField(_controllers['price']!, "السعر", isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _customField(_controllers['area']!, "المساحة m²", isNum: true)),
                ]),
                Row(children: [
                  Expanded(child: _customField(_controllers['rooms']!, "الغرف", isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _customField(_controllers['baths']!, "الحمامات", isNum: true)),
                ]),
                Row(children: [
                  Expanded(child: _customField(_controllers['lounges']!, "الريسبشن", isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _customField(_controllers['kitchens']!, "المطابخ", isNum: true)),
                ]),
                Row(children: [
                  Expanded(child: _customField(_controllers['floor']!, "الدور", isNum: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _customField(_controllers['balconies']!, "البلكونات", isNum: true)),
                ]),
                _dropdownField("نوع التشطيب", ["Extra Super Lux", "Super Lux", "Lux", "Semi Finished", "Core & Shell"], (v) => setState(() => _selectedFinishing = v), _selectedFinishing),

                _sectionTitle("خيارات إضافية"),
                CheckboxListTile(title: const Text("آخر دور؟"), value: _isLastFloor, onChanged: (v) => setState(() => _isLastFloor = v!)),
                CheckboxListTile(title: const Text("سكن مشترك؟ (Flat Share)"), value: _flatShare, onChanged: (v) => setState(() => _flatShare = v!)),
                SwitchListTile(title: const Text("متاح حالياً"), value: _isAvailable, onChanged: (v) => setState(() => _isAvailable = v)),

                _sectionTitle("الموقع والوصف"),
                _customField(_controllers['locAr']!, "العنوان بالتفصيل (عربي)"),
                _customField(_controllers['locMap']!, "رابط Google Maps"),
                _customField(_controllers['descAr']!, "الوصف (عربي)", maxLines: 3),

                _sectionTitle("بيانات المالك (سرية)"),
                _customField(_controllers['ownerName']!, "اسم المالك"),
                _customField(_controllers['ownerPhone']!, "رقم المالك", isNum: true),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        floatingActionButton: BlocBuilder<PropertiesCubit, PropertiesState>(
          builder: (context, state) {
            final bool isLoading = state is PropertiesLoading;

            return FloatingActionButton.extended(
              heroTag: "propertyFormHeroTag",
              onPressed: isLoading ? null : _handleSubmit,
              label: isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text("حفظ العقار"),
              icon: isLoading ? null : const Icon(Icons.check),
              backgroundColor: isLoading ? Colors.grey : Colors.blueAccent,
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // --- Widgets المساعدة ---

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
  );

  Widget _customField(TextEditingController ctrl, String label, {bool isNum = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (v) => (v == null || v.isEmpty) ? "هذا الحقل مطلوب" : null,
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, Function(String?) onChg, String? val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: items.contains(val) ? val : null,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChg,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (v) => v == null ? "مطلوب" : null,
      ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._existingImages.map((url) => _imageTile(
            Image.network(url, fit: BoxFit.cover),
                () => setState(() {
              _existingImages.remove(url);    // مسح من العرض
              _imagesToDelete.add(url);      // إضافتها لقائمة الحذف لإرسالها للسيرفر
            }),
          )),
          ..._newImagesBytes.asMap().entries.map((e) => _imageTile(
            Image.memory(e.value, fit: BoxFit.cover),
                () => setState(() => _newImagesBytes.removeAt(e.key)),
          )),
          if ((_existingImages.length + _newImagesBytes.length) < 10) _addPhotoButton(),
        ],
      ),
    );
  }

  Widget _imageTile(Widget img, VoidCallback onDel) => Container(
    width: 100,
    margin: const EdgeInsets.only(right: 8),
    child: Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox.expand(child: img)),
        Positioned(
          right: 4,
          top: 4,
          child: GestureDetector(
            onTap: onDel,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _addPhotoButton() => GestureDetector(
    onTap: () async {
      final picked = await ImagePicker().pickMultiImage();
      if (picked.isNotEmpty) {
        for (var file in picked) {
          if (_newImagesBytes.length + _existingImages.length < 10) {
            final bytes = await file.readAsBytes();
            setState(() => _newImagesBytes.add(bytes));
          }
        }
      }
    },
    child: Container(
      width: 100,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.add_a_photo, color: Colors.grey),
    ),
  );
}