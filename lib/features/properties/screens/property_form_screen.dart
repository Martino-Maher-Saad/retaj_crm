import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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

  // الحالات المختارة (Selections)
  String? _selectedCity, _selectedType, _selectedCategory, _selectedFinishing;
  bool _isAvailable = true;
  bool _isLastFloor = false;
  bool _flatShare = false;

  // معالجة الصور
  List<Uint8List> _newImagesBytes = [];
  List<String> _existingImages = [];
  List<String> _imagesToDelete = [];

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
      'price': TextEditingController(text: p?.price != null ? p!.price.toStringAsFixed(0) : ""),
      'area': TextEditingController(text: p?.area != null ? p!.area.toStringAsFixed(0) : ""),
      'rooms': TextEditingController(text: p?.rooms?.toString()),
      'baths': TextEditingController(text: p?.baths?.toString()),
      'lounges': TextEditingController(text: p?.lounges?.toString()),
      'kitchens': TextEditingController(text: p?.kitchens?.toString()),
      'balconies': TextEditingController(text: p?.balconies?.toString()),
      'floor': TextEditingController(text: p?.floor?.toString()),
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

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImagesBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one image")));
      return;
    }

    final cubit = context.read<PropertiesCubit>();
    final model = _mapFieldsToModel();

    if (widget.property == null) {
      cubit.addProperty(model, _newImagesBytes);
    } else {
      cubit.updateProperty(
        property: model,
        newImages: _newImagesBytes,
        imagesToDelete: _imagesToDelete,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertiesCubit, PropertiesState>(
      listener: (context, state) {
        if (state is PropertiesSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved successfully"), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else if (state is PropertiesError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(widget.property == null ? "Add Property" : "Edit Property #${widget.property!.id.substring(0, 5)}"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 1000.w),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    _buildFormSection(
                      title: "Media & Images",
                      icon: Icons.collections_outlined,
                      child: _buildImagePickerSection(),
                    ),
                    SizedBox(height: 20.h),
                    _buildFormSection(
                      title: "Basic Info",
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          _buildResponsiveRow([
                            _buildDropdown("Category", ["Residential", "Commercial", "Administrative"], (v) => setState(() => _selectedCategory = v), _selectedCategory),
                            _buildDropdown("City", ["Zayed", "October", "Cairo", "Maadi", "New Cairo"], (v) => setState(() => _selectedCity = v), _selectedCity),
                          ]),
                          _buildResponsiveRow([
                            _buildDropdown("Type", ["Sale", "Rent"], (v) => setState(() => _selectedType = v), _selectedType),
                            _buildTextField(_controllers['price']!, "Price (EGP)", isNum: true, prefix: Icons.payments_outlined),
                          ]),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildFormSection(
                      title: "Unit Specifications",
                      icon: Icons.home_work_outlined,
                      child: Column(
                        children: [
                          _buildResponsiveRow([
                            _buildTextField(_controllers['area']!, "Area m²", isNum: true),
                            _buildTextField(_controllers['rooms']!, "Rooms", isNum: true),
                            _buildTextField(_controllers['baths']!, "Baths", isNum: true),
                          ]),
                          _buildResponsiveRow([
                            _buildTextField(_controllers['floor']!, "Floor", isNum: true),
                            _buildTextField(_controllers['lounges']!, "Lounges", isNum: true),
                            _buildDropdown("Finishing", ["Super Lux", "Lux", "Semi Finished", "Core & Shell"], (v) => setState(() => _selectedFinishing = v), _selectedFinishing),
                          ]),
                          const Divider(),
                          _buildOptionsRow(),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildFormSection(
                      title: "Location & Description",
                      icon: Icons.map_outlined,
                      child: Column(
                        children: [
                          _buildTextField(_controllers['locAr']!, "Address Details", prefix: Icons.location_on_outlined),
                          _buildTextField(_controllers['locMap']!, "Google Maps Link", prefix: Icons.link),
                          _buildTextField(_controllers['descAr']!, "Description", maxLines: 4),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildFormSection(
                      title: "Owner Data (Confidential)",
                      icon: Icons.admin_panel_settings_outlined,
                      color: Colors.blueGrey.shade50,
                      child: _buildResponsiveRow([
                        _buildTextField(_controllers['ownerName']!, "Owner Name", prefix: Icons.person_outline),
                        _buildTextField(_controllers['ownerPhone']!, "Phone", isNum: true, prefix: Icons.phone_android_outlined),
                      ]),
                    ),
                    SizedBox(height: 120.h),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: _buildSubmitButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // --- Image Picker Logic ---
  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImages.map((url) => _imageTile(
                  CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, placeholder: (c,u) => Container(color: Colors.grey[200])),
                      () => setState(() { _existingImages.remove(url); _imagesToDelete.add(url); })
              )),
              ..._newImagesBytes.asMap().entries.map((e) => _imageTile(
                  Image.memory(e.value, fit: BoxFit.cover),
                      () => setState(() => _newImagesBytes.removeAt(e.key))
              )),
              if ((_existingImages.length + _newImagesBytes.length) < 10) _addPhotoButton(),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text("Max 10 images. First image is the thumbnail.", style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _imageTile(Widget img, VoidCallback onDel) {
    return Container(
      width: 110.w,
      margin: EdgeInsets.only(right: 12.w),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12.r), child: SizedBox.expand(child: img)),
          Positioned(
            right: 5, top: 5,
            child: GestureDetector(
              onTap: onDel,
              child: CircleAvatar(radius: 12.r, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16.sp, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPhotoButton() {
    return GestureDetector(
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
        width: 110.w,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid)),
        child: Icon(Icons.add_a_photo_outlined, color: AppColors.primaryBlue, size: 30.sp),
      ),
    );
  }

  // --- Helper Build Methods ---
  Widget _buildFormSection({required String title, required IconData icon, required Widget child, Color? color}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primaryBlue, size: 22.sp),
            SizedBox(width: 10.w),
            Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ]),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(List<Widget> children) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children.map((w) => Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8.w), child: w))).toList());
        } else {
          return Column(children: children.map((w) => Padding(padding: EdgeInsets.only(bottom: 12.h), child: w)).toList());
        }
      }),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, {bool isNum = false, int maxLines = 1, IconData? prefix}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix != null ? Icon(prefix, size: 20.sp) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Field Required" : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChg, String? val) {
    return DropdownButtonFormField<String>(
      value: items.contains(val) ? val : null,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(fontSize: 14.sp)))).toList(),
      onChanged: onChg,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)), filled: true, fillColor: Colors.white),
      validator: (v) => v == null ? "Required" : null,
    );
  }

  Widget _buildOptionsRow() {
    return Wrap(
      spacing: 20.w,
      runSpacing: 10.h,
      children: [
        _buildCheckOption("Last Floor", _isLastFloor, (v) => setState(() => _isLastFloor = v!)),
        _buildCheckOption("Flat Share", _flatShare, (v) => setState(() => _flatShare = v!)),
        _buildSwitchOption("Is Available", _isAvailable, (v) => setState(() => _isAvailable = v)),
      ],
    );
  }

  Widget _buildCheckOption(String l, bool v, Function(bool?) onChg) => Row(mainAxisSize: MainAxisSize.min, children: [Checkbox(value: v, onChanged: onChg), Text(l, style: TextStyle(fontSize: 12.sp))]);

  Widget _buildSwitchOption(String l, bool v, Function(bool) onChg) => Row(mainAxisSize: MainAxisSize.min, children: [Text(l, style: TextStyle(fontSize: 12.sp)), Switch(value: v, onChanged: onChg)]);

  Widget _buildSubmitButton() {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        final bool isLoading = state is PropertiesLoading;
        return SizedBox(
          width: 300.w,
          height: 50.h,
          child: FloatingActionButton.extended(
            onPressed: isLoading ? null : _handleSubmit,
            label: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Save Property", style: TextStyle(fontWeight: FontWeight.bold)),
            icon: isLoading ? null : const Icon(Icons.check_circle_outline),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      },
    );
  }
}