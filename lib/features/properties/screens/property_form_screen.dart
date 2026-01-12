import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import '../cubit/properties_cubit.dart';

class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? property;
  final String userId;

  const PropertyFormScreen({super.key, this.property, required this.userId});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // الـ Controllers معرفة بشكل مستقل لسهولة التحكم والـ Dispose
  late Map<String, TextEditingController> _controllers;

  String? _selectedCity, _selectedType;
  bool _isAvailable = true;

  // إدارة الصور: بايتات للجديد وروابط للقديم
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
      'titleAr': TextEditingController(text: p?.titleAr),
      'titleEn': TextEditingController(text: p?.titleEn),
      'price': TextEditingController(text: p?.price?.toString()),
      'area': TextEditingController(text: p?.area?.toString()),
      'rooms': TextEditingController(text: p?.rooms?.toString()),
      'baths': TextEditingController(text: p?.baths?.toString()),
      'locAr': TextEditingController(text: p?.locationAr),
      'locEn': TextEditingController(text: p?.locationEn),
      'ownerName': TextEditingController(text: p?.ownerName),
      'ownerPhone': TextEditingController(text: p?.ownerPhone),
      'descAr': TextEditingController(text: p?.descAr),
      'descEn': TextEditingController(text: p?.descEn),
    };
    _selectedCity = p?.city;
    _selectedType = p?.type;
    _isAvailable = p?.isAvailable ?? true;
    _existingImages = p?.images != null ? List.from(p!.images) : [];
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  PropertyModel _mapFieldsToModel() {
    return PropertyModel(
      id: widget.property?.id,
      titleAr: _controllers['titleAr']!.text,
      titleEn: _controllers['titleEn']!.text,
      rooms: int.tryParse(_controllers['rooms']!.text) ?? 0,
      baths: int.tryParse(_controllers['baths']!.text) ?? 0,
      locationAr: _controllers['locAr']!.text,
      locationEn: _controllers['locEn']!.text,
      ownerName: _controllers['ownerName']!.text,
      ownerPhone: _controllers['ownerPhone']!.text,
      createdBy: widget.userId,
      price: double.tryParse(_controllers['price']!.text) ?? 0.0,
      area: double.tryParse(_controllers['area']!.text) ?? 0.0,
      city: _selectedCity ?? '',
      type: _selectedType ?? '',
      isAvailable: _isAvailable,
      descAr: _controllers['descAr']!.text,
      descEn: _controllers['descEn']!.text,
      images: _existingImages, // الروابط التي لم تُحذف
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // نجهز البيانات ونرجعها للشاشة السابقة
    final propertyModel = _mapFieldsToModel();

    if (mounted) {
      // بنرجع Map فيها الموديل والصور الجديدة
      Navigator.pop(context, {
        'model': propertyModel,
        'images': _newImagesBytes,
      });
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.property == null ? "عقار جديد" : "تعديل عقار"),
        elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildFormCore(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleSubmit,
        label: const Text("حفظ البيانات", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.save),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  // دالة اختيار صور متعددة مع مراعاة الحد الأقصى
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final remaining = 10 - (_existingImages.length + _newImagesBytes.length);
    if (remaining <= 0) return;

    final List<XFile> picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      for (var i = 0; i < picked.length && i < remaining; i++) {
        final bytes = await picked[i].readAsBytes();
        setState(() => _newImagesBytes.add(bytes));
      }
    }
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("الصور (بحد أقصى 10)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImages.map((url) => _imageTile(Image.network(url, fit: BoxFit.cover), () => setState(() => _existingImages.remove(url)))),
              ..._newImagesBytes.asMap().entries.map((e) => _imageTile(Image.memory(e.value, fit: BoxFit.cover), () => setState(() => _newImagesBytes.removeAt(e.key)))),
              if ((_existingImages.length + _newImagesBytes.length) < 10)
                _addPhotoButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageTile(Widget img, VoidCallback onDel) => Stack(children: [
    Container(width: 100, margin: const EdgeInsets.only(right: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: img)),
    Positioned(top: 2, right: 10, child: GestureDetector(onTap: onDel, child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 14, color: Colors.white)))),
  ]);

  Widget _addPhotoButton() => GestureDetector(
    onTap: _pickImages,
    child: Container(width: 100, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)), child: const Icon(Icons.add_a_photo, color: Colors.grey)),
  );

  Widget _buildFormCore() {
    return Column(children: [
      _customField(_controllers['titleAr']!, "العنوان بالعربي"),
      _customField(_controllers['titleEn']!, "العنوان بالإنجليزي"),
      Row(children: [
        Expanded(child: _customField(_controllers['price']!, "السعر", isNum: true)),
        const SizedBox(width: 12),
        Expanded(child: _customField(_controllers['area']!, "المساحة", isNum: true)),
      ]),
      _dropdownField("المدينة", ["Zayed", "October", "Cairo", "New Cairo"], (v) => setState(() => _selectedCity = v), _selectedCity),
      _dropdownField("النوع", ["Apartment", "Villa", "Office", "Studio"], (v) => setState(() => _selectedType = v), _selectedType),
      _customField(_controllers['ownerName']!, "اسم المالك"),
      _customField(_controllers['ownerPhone']!, "رقم المالك", isNum: true),
      _customField(_controllers['descAr']!, "وصف العقار", maxLines: 3),
      SwitchListTile(
        title: const Text("العقار متاح حالياً"),
        value: _isAvailable,
        onChanged: (v) => setState(() => _isAvailable = v),
        activeColor: const Color(0xFF2563EB),
      ),
    ]);
  }

  Widget _customField(TextEditingController ctrl, String label, {bool isNum = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        validator: (v) => v!.isEmpty ? "مطلوب" : null,
      ),
    );
  }

  Widget _dropdownField(String label, List<String> items, Function(String?) onChg, String? val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: items.contains(val) ? val : null,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChg,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        validator: (v) => v == null ? "مطلوب" : null,
      ),
    );
  }
}