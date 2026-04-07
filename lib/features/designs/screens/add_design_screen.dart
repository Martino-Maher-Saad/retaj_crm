import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/retaj_shared_fields.dart';
import '../../../data/models/design_model.dart';
import '../cubit/designs_cubit.dart';
import '../cubit/designs_state.dart';

class AddDesignScreen extends StatefulWidget {
  const AddDesignScreen({super.key});

  @override
  State<AddDesignScreen> createState() => _AddDesignScreenState();
}

class _AddDesignScreenState extends State<AddDesignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  String? _selectedRoomType;
  String? _selectedStyle;
  final List<Uint8List> _newImagesBytes = [];
  bool _isSubmitting = false;

  final List<String> _roomTypes = ["ريسبشن", "غرفة نوم", "مطبخ", "حمام", "غرفة معيشة", "مكتب", "أخرى"];
  final List<String> _styles = ["مودرن (Modern)", "كلاسيك (Classic)", "نيو كلاسيك (Neo-Classic)", "بوهيمي (Bohemian)", "صناعي (Industrial)", "أخرى"];

  void _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      for (var img in images) {
        final bytes = await img.readAsBytes();
        setState(() {
          _newImagesBytes.add(bytes);
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);

    final design = DesignModel(
      id: '',
      descAr: _descController.text,
      roomType: _selectedRoomType,
      style: _selectedStyle,
      createdAt: DateTime.now(),
      // addedBy will be set by the backend/DB via auth hook or can be passed if currentUserId is available
    );

    try {
      await context.read<DesignsCubit>().addDesign(design, _newImagesBytes);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة التصميم بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("إضافة تصميم جديد", style: AppTextStyles.blue16Bold),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: BlocBuilder<DesignsCubit, DesignsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  RetajSectionCard(
                    title: "بيانات التصميم",
                    icon: Icons.design_services,
                    children: [
                      RetajTextArea(
                        controller: _descController,
                        label: "وصف التصميم بالعربي",
                        minLines: 3,
                      ),
                      SizedBox(height: 16.h),
                      RetajFieldRow(
                        first: _buildDropdown(
                          "نوع الغرفة",
                          _selectedRoomType,
                          _roomTypes,
                          (v) => setState(() => _selectedRoomType = v),
                        ),
                        second: _buildDropdown(
                          "الطراز (Style)",
                          _selectedStyle,
                          _styles,
                          (v) => setState(() => _selectedStyle = v),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  RetajSectionCard(
                    title: "الصور والمرفقات",
                    icon: Icons.image,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text("حدد الصور"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                              foregroundColor: AppColors.brandPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                          if (_newImagesBytes.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: _newImagesBytes.asMap().entries.map((e) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.memory(
                                        e.value,
                                        width: 100.w,
                                        height: 100.w,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _newImagesBytes.removeAt(e.key)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || state is DesignsLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      child: _isSubmitting || state is DesignsLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text("حفظ التصميم", style: AppTextStyles.blue18Medium.copyWith(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.inputLabel.copyWith(color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: const BorderSide(color: AppColors.borderSubtle)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppTextStyles.inputText))).toList(),
      onChanged: onChanged,
      // The user specified that room_type and style should be nullable dropdowns.
      // So validator is not strictly requred if they are totally optional.
    );
  }
}
