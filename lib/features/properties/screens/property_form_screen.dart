import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/property_model.dart';
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

  late TextEditingController _titleAr, _titleEn, _price, _area, _rooms, _baths, _locAr, _locEn, _ownerName, _ownerPhone, _descAr, _descEn;
  String? _selectedCity, _selectedType;
  bool _isAvailable = true;

  // إدارة الصور بالبايتات لضمان عملها على الويب والموبايل
  List<Uint8List> _newImagesBytes = [];
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleAr = TextEditingController(text: p?.titleAr);
    _titleEn = TextEditingController(text: p?.titleEn);
    _price = TextEditingController(text: p?.price.toString());
    _area = TextEditingController(text: p?.area.toString());
    _rooms = TextEditingController(text: p?.rooms.toString());
    _baths = TextEditingController(text: p?.baths.toString());
    _locAr = TextEditingController(text: p?.locationAr);
    _locEn = TextEditingController(text: p?.locationEn);
    _ownerName = TextEditingController(text: p?.ownerName);
    _ownerPhone = TextEditingController(text: p?.ownerPhone);
    _descAr = TextEditingController(text: p?.descAr);
    _descEn = TextEditingController(text: p?.descEn);
    _selectedCity = p?.city;
    _selectedType = p?.type;
    _isAvailable = p?.isAvailable ?? true;
    _existingImages = p?.images != null ? List.from(p!.images) : [];
  }

  // ميثود لتجميع البيانات من الحقول وتحويلها لـ Model
  PropertyModel _createPropertyFromFields() {
    return PropertyModel(
      id: widget.property?.id, // لو null يبقى إضافة، لو قيمة يبقى تعديل
      titleAr: _titleAr.text,
      titleEn: _titleEn.text,
      rooms: int.tryParse(_rooms.text) ?? 0,
      baths: int.tryParse(_baths.text) ?? 0,
      locationAr: _locAr.text,
      locationEn: _locEn.text,
      ownerName: _ownerName.text,
      ownerPhone: _ownerPhone.text,
      createdBy: widget.userId,
      price: double.tryParse(_price.text) ?? 0.0,
      area: double.tryParse(_area.text) ?? 0.0,
      city: _selectedCity ?? '',
      isAvailable: _isAvailable,
      type: _selectedType ?? '',
      descAr: _descAr.text,
      descEn: _descEn.text,
      images: _existingImages,
    );
  }

  // معالجة الضغط على زر الحفظ باستخدام الـ PropertiesCubit
  void _handleSubmit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        // 1. إظهار مؤشر تحميل (Loading Dialog)
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          ),
        );

        // 2. استدعاء الميثود الموحدة في PropertiesCubit
        // ملاحظة: تأكد من تسمية الميثود في الكيوبيت بـ addProperty أو saveFullProperty كما عدلناها
        await context.read<PropertiesCubit>().saveFullProperty(
          property: _createPropertyFromFields(),
          imageBytesList: _newImagesBytes,
        );

        // 3. إغلاق الـ Loading والعودة للشاشة السابقة
        if (!mounted) return;
        Navigator.pop(context); // إغلاق الديالوج
        Navigator.pop(context); // العودة للقائمة

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم الحفظ بنجاح"), backgroundColor: Colors.green),
        );
      } catch (e) {
        // إغلاق التحميل وإظهار الخطأ
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property == null ? "إضافة عقار جديد" : "تعديل العقار"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(key: _formKey, child: _buildFormFields(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleSubmit(context),
        label: const Text("حفظ البيانات"),
        icon: const Icon(Icons.save),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildImagePicker(),
          const SizedBox(height: 20),
          _buildTextField(_titleEn, "العنوان (بالإنجليزي)"),
          _buildTextField(_titleAr, "العنوان (بالعربي)"),
          Row(children: [
            Expanded(child: _buildTextField(_price, "السعر", isNum: true)),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField(_area, "المساحة", isNum: true)),
          ]),
          Row(children: [
            Expanded(child: _buildTextField(_rooms, "الغرف", isNum: true)),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField(_baths, "الحمامات", isNum: true)),
          ]),
          _buildDropdown("المدينة", ["Zayed", "October", "Cairo", "New Cairo"], (v) => setState(() => _selectedCity = v), _selectedCity),
          _buildDropdown("النوع", ["Apartment", "Villa", "Office", "Studio"], (v) => setState(() => _selectedType = v), _selectedType),
          _buildTextField(_ownerName, "اسم المالك"),
          _buildTextField(_ownerPhone, "رقم المالك"),
          _buildTextField(_locEn, "الموقع (بالإنجليزي)"),
          _buildTextField(_locAr, "الموقع (بالعربي)"),
          _buildTextField(_descEn, "الوصف (بالإنجليزي)", maxLines: 3),
          _buildTextField(_descAr, "الوصف (بالعربي)", maxLines: 3),
          SwitchListTile(
            title: const Text("متاح حالياً؟"),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("الصور (حد أقصى 10)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImages.map((url) => _imageBox(Image.network(url, fit: BoxFit.cover), isExisting: true, url: url)),
              ..._newImagesBytes.asMap().entries.map((entry) => _imageBox(
                Image.memory(entry.value, fit: BoxFit.cover),
                isExisting: false,
                index: entry.key,
              )),
              if ((_existingImages.length + _newImagesBytes.length) < 10)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_a_photo, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageBox(Widget img, {required bool isExisting, String? url, int? index}) {
    return Stack(children: [
      Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: img),
      ),
      Positioned(
        top: 0, right: 10,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isExisting) {
                _existingImages.remove(url);
              } else {
                _newImagesBytes.removeAt(index!);
              }
            });
          },
          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
        ),
      )
    ]);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() => _newImagesBytes.add(bytes));
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNum = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => v!.isEmpty ? "مطلوب" : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => v == null ? "مطلوب" : null,
      ),
    );
  }
}