import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../data/models/design_model.dart';
import '../cubit/design_form_cubit.dart';

class DesignInlineForm extends StatefulWidget {
  final DesignModel? existingDesign;
  final VoidCallback onCancel;
  final Function(DesignModel) onSuccess;

  const DesignInlineForm({
    super.key,
    this.existingDesign,
    required this.onCancel,
    required this.onSuccess,
  });

  @override
  State<DesignInlineForm> createState() => _DesignInlineFormState();
}

class _DesignInlineFormState extends State<DesignInlineForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descController;
  final _dataManager = di.sl<StaticDataManager>();

  String? _selectedRoomType;
  String? _selectedStyle;

  final List<Uint8List> _newImagesBytes = [];
  final List<DesignLinkModel> _links = [];

  final List<DesignImageModel> _existingImages = [];
  final List<String> _deletedImageIds = [];

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(
      text: widget.existingDesign?.descAr ?? '',
    );
    _selectedRoomType = widget.existingDesign?.roomType;
    _selectedStyle = widget.existingDesign?.style;
    if (widget.existingDesign?.links != null) {
      _links.addAll(widget.existingDesign!.links);
    }
    if (widget.existingDesign?.images != null) {
      _existingImages.addAll(widget.existingDesign!.images!);
    }
  }

  void _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    for (var img in images) {
      final bytes = await img.readAsBytes();
      setState(() {
        _newImagesBytes.add(bytes);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomType == null || _selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء اختيار نوع الغرفة والستايل')),
      );
      return;
    }
    if (_existingImages.isEmpty && _newImagesBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة صورة واحدة على الأقل')),
      );
      return;
    }

    context.read<DesignFormCubit>().submitDesign(
      existingDesign: widget.existingDesign,
      descAr: _descController.text,
      roomTypeId:
          _dataManager.getIdByName('design_room_types', _selectedRoomType!) ??
          '',
      styleId: _dataManager.getIdByName('design_styles', _selectedStyle!) ?? '',
      links: _links,
      newImages: _newImagesBytes,
      deletedImageIds: _deletedImageIds,
    );
  }

  void _openDescriptionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('وصف التشطيب'),
          content: SizedBox(
            width: 600.w,
            child: TextField(
              controller: _descController,
              maxLines: 15,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'اكتب تفاصيل التشطيب هنا بحرية...',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {}); // تحديث الواجهة
                Navigator.pop(context);
              },
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DesignFormCubit, DesignFormState>(
      listener: (context, state) {
        if (state is DesignFormSuccess) {
          widget.onSuccess(state.design);
        } else if (state is DesignFormError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is DesignFormLoading;

        return Card(
          elevation: 8,
          shadowColor: Colors.black12,
          margin: EdgeInsets.only(bottom: 24.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(
              color: AppColors.brandPrimary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.design_services,
                        color: AppColors.brandPrimary,
                        size: 24.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        widget.existingDesign == null
                            ? 'إضافة تصميم جديد'
                            : 'تعديل التصميم',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العمود الأيمن (الأساسيات)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownMenu<String>(
                                    initialSelection: _selectedRoomType,
                                    expandedInsets: EdgeInsets.zero,
                                    enableSearch: true,
                                    enableFilter: true,
                                    menuHeight: 180,
                                    textStyle: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    label: Text(
                                      'نوع الغرفة',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    dropdownMenuEntries: _dataManager
                                        .getOptionModels('design_room_types')
                                        .map(
                                          (o) => DropdownMenuEntry(
                                            value: o.nameAr,
                                            label: o.nameAr,
                                          ),
                                        )
                                        .toList(),
                                    onSelected: (val) =>
                                        setState(() => _selectedRoomType = val),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: DropdownMenu<String>(
                                    initialSelection: _selectedStyle,
                                    expandedInsets: EdgeInsets.zero,
                                    enableSearch: true,
                                    enableFilter: true,
                                    menuHeight: 180,
                                    textStyle: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    label: Text(
                                      'ستايل التشطيب',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    dropdownMenuEntries: _dataManager
                                        .getOptionModels('design_styles')
                                        .map(
                                          (o) => DropdownMenuEntry(
                                            value: o.nameAr,
                                            label: o.nameAr,
                                          ),
                                        )
                                        .toList(),
                                    onSelected: (val) =>
                                        setState(() => _selectedStyle = val),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _descController,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'وصف التشطيب (للبحث)',
                                      labelStyle: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      border: const OutlineInputBorder(),
                                      alignLabelWithHint: true,
                                    ),
                                    maxLines: null,
                                    minLines: 3,
                                    validator: (val) =>
                                        val!.isEmpty ? 'مطلوب' : null,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _openDescriptionDialog,
                                  icon: const Icon(
                                    Icons.open_in_full,
                                    size: 20,
                                  ),
                                  tooltip: 'توسيع',
                                  color: AppColors.brandPrimary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 24.w),

                      // العمود الأيسر (الروابط والصور)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'الروابط والصور',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                children: [
                                  ..._links.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    DesignLinkModel link = entry.value;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: 8.h),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: link.title,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'اسم الرابط (Key)',
                                                labelStyle: TextStyle(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              onChanged: (val) =>
                                                  _links[index] =
                                                      DesignLinkModel(
                                                        title: val,
                                                        url: _links[index].url,
                                                      ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: TextFormField(
                                              initialValue: link.url,
                                              textDirection: TextDirection.ltr,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'الرابط (Value)',
                                                labelStyle: TextStyle(
                                                  fontSize: 15.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              onChanged: (val) =>
                                                  _links[index] =
                                                      DesignLinkModel(
                                                        title: _links[index].title,
                                                        url: val,
                                                      ),
                                            ),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            onPressed: () => setState(
                                              () => _links.removeAt(index),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => setState(
                                      () => _links.add(
                                        DesignLinkModel(title: '', url: ''),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_link, size: 20),
                                    label: Text(
                                      'إضافة رابط',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isLoading ? null : _pickImages,
                                    icon: const Icon(
                                      Icons.add_photo_alternate,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'اختر الصور',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade100,
                                      foregroundColor: AppColors.brandPrimary,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_existingImages.isNotEmpty ||
                                _newImagesBytes.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 8.h),
                                child: Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: [
                                    // عرض الصور القديمة
                                    ..._existingImages.asMap().entries.map((
                                      entry,
                                    ) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 45.w,
                                            height: 45.w,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    CloudinaryService.getThumbnailUrl(
                                                      entry.value.imageUrl,
                                                    ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            left: -6,
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _deletedImageIds.add(
                                                    entry.value.id,
                                                  );
                                                  _existingImages.removeAt(
                                                    entry.key,
                                                  );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                    // عرض الصور الجديدة
                                    ..._newImagesBytes.asMap().entries.map((
                                      entry,
                                    ) {
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 45.w,
                                            height: 45.w,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: MemoryImage(entry.value),
                                                fit: BoxFit.cover,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6.r),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: -6,
                                            left: -6,
                                            child: InkWell(
                                              onTap: () => setState(
                                                () => _newImagesBytes.removeAt(
                                                  entry.key,
                                                ),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : widget.onCancel,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 14.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'حفظ التصميم',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
