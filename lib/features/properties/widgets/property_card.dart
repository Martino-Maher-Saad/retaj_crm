import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../core/utils/property_cache_manager.dart';
import '../../../core/utils/whatsapp_share_helper.dart';
import '../../../data/models/property_model.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_image_model.dart';
import '../cubit/properties_cubit.dart';
import '../screens/property_full_screen_image.dart';
import '../screens/property_details_screen.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text.replaceAll(',', '');
    final intValue = int.tryParse(text);
    if (intValue == null) return oldValue;
    final newText = intValue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class PropertyCard extends StatefulWidget {
  final PropertyModel property;
  final String currentUserId;
  final String role;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onShareInternal;
  final VoidCallback onTap;
  final VoidCallback? onPinToggle;
  
  final bool initialEditMode;
  final bool isAddingMode;
  final VoidCallback? onCancelAdd;

  const PropertyCard({
    super.key,
    required this.property,
    required this.currentUserId,
    required this.role,
    this.onEdit,
    this.onDelete,
    this.onArchive,
    this.onRestore,
    this.onShareInternal,
    required this.onTap,
    this.onPinToggle,
    this.initialEditMode = false,
    this.isAddingMode = false,
    this.onCancelAdd,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  late bool _isEditing;
  bool _isSavingInline = false;
  
  final TextEditingController _propertyCodeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  String? _selectedListingType;
  String? _selectedPropertyType;
  int? _selectedCityId;
  
  List<PropertyImageModel> _existingImages = [];
  List<Uint8List> _newImagesBytes = [];
  List<PropertyImageModel> _imagesToDeleteObjects = [];
  
  bool _isDescExpanded = false;
  
  String? _propertyCodeError;
  String? _priceError;
  String? _ownerPhoneError;
  String? _descError;
  String? _listingTypeError;
  String? _propertyTypeError;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialEditMode;
    if (_isEditing) {
      _initInlineEditData();
    }
  }
  
  void _initInlineEditData() {
    _propertyCodeController.text = widget.property.propertyCode ?? '';
    if (widget.property.price > 0) {
      _priceController.text = widget.property.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    } else {
      _priceController.text = '';
    }
    _ownerNameController.text = widget.property.ownerName ?? '';
    _ownerPhoneController.text = widget.property.ownerPhone ?? '';
    _descController.text = widget.property.descAr ?? '';
    
    _selectedListingType = widget.property.listingTypeAr;
    _selectedPropertyType = widget.property.propertyTypeAr;
    _selectedCityId = widget.property.cityId;
    
    if (widget.isAddingMode) {
      _priceController.text = '';
      _selectedListingType = null;
      _selectedPropertyType = null;
      _selectedCityId = null;
    }
    
    _existingImages = List.from(widget.property.images);
    _newImagesBytes = [];
    _imagesToDeleteObjects = [];
  }
  
  @override
  void dispose() {
    _propertyCodeController.dispose();
    _priceController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _descController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    for (var f in picked) {
      if ((_newImagesBytes.length + _existingImages.length) < 10) {
        final b = await f.readAsBytes();
        final compressed = await ImageCompressor.compressImage(b);
        setState(() => _newImagesBytes.add(compressed));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الحد الأقصى 10 صور فقط')));
        }
        break;
      }
    }
  }

  Future<void> _saveInlineProperty() async {
    setState(() {
      _propertyCodeError = null;
      _priceError = null;
      _ownerPhoneError = null;
      _descError = null;
      _listingTypeError = null;
      _propertyTypeError = null;
      _cityError = null;
    });

    bool hasError = false;

    if (_newImagesBytes.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('صورة واحدة على الأقل مطلوبة')));
      hasError = true;
    }
    if (_propertyCodeController.text.trim().isEmpty) {
      _propertyCodeError = 'هذا الحقل مطلوب';
      hasError = true;
    }
    if (_selectedPropertyType == null) {
      _propertyTypeError = 'مطلوب';
      hasError = true;
    }
    if (_selectedListingType == null) {
      _listingTypeError = 'مطلوب';
      hasError = true;
    }
    if (_selectedCityId == null) {
      _cityError = 'مطلوب';
      hasError = true;
    }
    if (_priceController.text.trim().isEmpty) {
      _priceError = 'هذا الحقل مطلوب';
      hasError = true;
    }
    if (_ownerPhoneController.text.trim().isEmpty) {
      _ownerPhoneError = 'هذا الحقل مطلوب';
      hasError = true;
    }
    if (_descController.text.trim().isEmpty) {
      _descError = 'هذا الحقل مطلوب';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }
    
    final priceStr = _priceController.text.trim().replaceAll(',', '');
    final num priceNum = num.tryParse(priceStr) ?? 0;
    
    final bool hasChanges = _propertyCodeController.text.trim() != (widget.property.propertyCode ?? '') ||
        priceNum != widget.property.price ||
        _ownerNameController.text.trim() != (widget.property.ownerName ?? '') ||
        _ownerPhoneController.text.trim() != (widget.property.ownerPhone ?? '') ||
        _descController.text.trim() != (widget.property.descAr ?? '') ||
        _selectedListingType != widget.property.listingTypeAr ||
        _selectedPropertyType != widget.property.propertyTypeAr ||
        _selectedCityId != widget.property.cityId ||
        _newImagesBytes.isNotEmpty ||
        _imagesToDeleteObjects.isNotEmpty;

    if (!hasChanges) {
      if (!widget.isAddingMode) {
        setState(() => _isEditing = false);
      } else {
        widget.onCancelAdd?.call();
      }
      return;
    }
    
    setState(() => _isSavingInline = true);
    
    try {
      final dataManager = di.sl<StaticDataManager>();
      final cityObj = dataManager.allCities.firstWhere((c) => c.id == _selectedCityId, orElse: () => dataManager.allCities.first);
      
      final model = widget.property.copyWith(
        propertyCode: _propertyCodeController.text.trim(),
        price: num.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0,
        ownerName: _ownerNameController.text.trim(),
        ownerPhone: _ownerPhoneController.text.trim(),
        descAr: _descController.text.trim(),
        listingTypeAr: _selectedListingType,
        propertyTypeAr: _selectedPropertyType,
        listingTypeId: dataManager.getIdByName('listing_type', _selectedListingType!),
        propertyTypeId: dataManager.getIdByName('property_type', _selectedPropertyType!),
        cityId: _selectedCityId,
        cityAr: cityObj.name,
      );
      
      if (widget.isAddingMode) {
        await context.read<PropertiesCubit>().addProperty(model, _newImagesBytes, platformIds: const []);
        if (mounted) {
          widget.onCancelAdd?.call();
        }
      } else {
        await context.read<PropertiesCubit>().updateProperty(
          property: model, 
          newImages: _newImagesBytes,
          imagesToDelete: _imagesToDeleteObjects,
          platformIds: const [],
        );
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSavingInline = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e')));
        setState(() => _isSavingInline = false);
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "غير متوفر";
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _openGallery() {
    if (widget.property.images.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            width: 0.9.sw,
            height: 0.7.sh,
            child: PropertyFullScreenImage(
              imageUrls: widget.property.images.map((img) => img.original).toList(),
              initialIndex: 0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return _buildEditMode();
    }
    return _buildViewMode();
  }

  // ─── View Mode (4 Columns) ───
  Widget _buildViewMode() {
    final bool isMine = widget.property.createdBy == widget.currentUserId;
    final bool shouldMask = (widget.role == 'sales' || widget.role == 'marketing') && !isMine;
    
    final String? firstImageUrl = widget.property.images.isNotEmpty ? widget.property.images.first.thumbnail : null;
    final String displayUrl = firstImageUrl ?? "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
          children: [
            if (shouldMask)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.brandAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.r), topRight: Radius.circular(16.r)),
                ),
                child: Center(
                  child: Text(
                    "هذا العقار يخص زميل مبيعات آخر",
                    style: TextStyle(color: AppColors.brandAccent, fontWeight: FontWeight.w800, fontSize: 15.sp),
                  ),
                ),
              ),
              
            IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Column 1: Image ───
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: SizedBox(
                          height: 200.h,
                          child: GestureDetector(
                            onTap: _openGallery,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: CachedNetworkImage(
                                    cacheManager: PropertyCacheManager.instance,
                                    imageUrl: displayUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.bgMain,
                                      child: const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary)),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.bgMain,
                                      child: Icon(Icons.broken_image_outlined, color: AppColors.textDisabled, size: 40.sp),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6.h, right: 6.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4.r)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.photo_library_outlined, color: Colors.white, size: 14.sp),
                                        SizedBox(width: 4.w),
                                        Text("${widget.property.images.length}", style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8.h, left: 8.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: _getApprovalColor(widget.property.approvalStatusName),
                                      borderRadius: BorderRadius.circular(8.r),
                                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                    child: Text(
                                      widget.property.approvalStatusName ?? "في الانتظار",
                                      style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
                    ),
                    
                    // ─── Column 2: Info ───
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildDetailRow("أضيف بواسطة", widget.property.createdByName ?? "غير معروف", icon: Icons.person)),
                              Expanded(flex: 2, child: _buildDetailRow("كود العقار", widget.property.propertyCode ?? "غير متوفر")),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildDetailRow("نوع العقار", widget.property.propertyTypeAr)),
                              Expanded(child: _buildDetailRow("نوع الإعلان", widget.property.listingTypeAr)),
                              Expanded(child: _buildDetailRow("المدينة", widget.property.cityAr ?? "غير محدد")),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildDetailRow("السعر", "${widget.property.price.toCurrency()} ج.م", isHighlighted: true)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow("تاريخ الإضافة", _formatDate(widget.property.createdAt)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
                    ),
                    
                    // ─── Column 3: Owner Details & Description ───
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!shouldMask) ...[
                                Expanded(flex: 2, child: _buildDetailRow("اسم المالك", widget.property.ownerName ?? "غير متوفر")),
                                Expanded(flex: 2, child: _buildDetailRow("رقم المالك", widget.property.ownerPhone ?? "غير متوفر", isPhone: true)),
                              ],
                              
                              if (widget.property.managerNotes?.isNotEmpty == true || 
                                  (widget.property.approvalStatusName?.contains('موافق') == true || widget.property.approvalStatusName?.contains('مقبول') == true))
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "ملاحظات / منصات",
                                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[500], fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4.h),
                                      Wrap(
                                        spacing: 6.w,
                                        runSpacing: 6.h,
                                        children: [
                                          if (widget.property.managerNotes?.isNotEmpty == true)
                                            InkWell(
                                              onTap: () => _showManagerNotesDialog(widget.property.managerNotes!),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.notes_rounded, color: Colors.red, size: 14.sp),
                                                    SizedBox(width: 4.w),
                                                    Text("ملاحظات المدير", style: TextStyle(color: Colors.red, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          if (widget.property.approvalStatusName?.contains('موافق') == true || widget.property.approvalStatusName?.contains('مقبول') == true)
                                            ...widget.property.advertisingPlatforms.map((p) => Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6.r),
                                                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.campaign_rounded, color: Colors.blue, size: 14.sp),
                                                  SizedBox(width: 4.w),
                                                  Text(p.nameAr, style: TextStyle(color: Colors.blue[800], fontSize: 11.sp, fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Divider(height: 16.h, color: AppColors.borderSubtle),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("وصف العقار", style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                                    SizedBox(width: 8.w),
                                    if ((widget.property.descAr ?? "").isNotEmpty)
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: widget.property.descAr ?? ""));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الوصف بنجاح', style: TextStyle(fontFamily: 'Tajawal'))));
                                        },
                                        borderRadius: BorderRadius.circular(8.r),
                                        child: Padding(
                                          padding: EdgeInsets.all(4.r),
                                          child: Icon(Icons.copy_rounded, size: 22.sp, color: AppColors.brandPrimary),
                                        ),
                                      ),
                                  ],
                                ),
                                if ((widget.property.descAr ?? "").length > 80)
                                  InkWell(
                                    onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      child: Text(_isDescExpanded ? "عرض أقل" : "قراءة المزيد", style: TextStyle(color: AppColors.brandPrimary, fontSize: 17.sp, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: SizedBox(
                              width: double.infinity,
                              child: SelectableText(
                                widget.property.descAr ?? "لا يوجد وصف",
                                style: TextStyle(fontSize: 21.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.5),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                maxLines: _isDescExpanded ? null : 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
                    ),
                    
                    // ─── Column 4: Actions (Aligned to end and top) ───
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.onPinToggle != null)
                            _iconBtn(widget.property.isPinned ? Icons.push_pin : Icons.push_pin_outlined, widget.property.isPinned ? Colors.orange : Colors.grey, widget.onPinToggle!, widget.property.isPinned ? "إلغاء التثبيت" : "تثبيت"),
                          if (widget.onPinToggle != null) SizedBox(height: 12.h),
                          
                          if (widget.onEdit != null)
                            _iconBtn(Icons.edit_rounded, Colors.blue, () {
                              setState(() {
                                _isEditing = true;
                                _initInlineEditData();
                              });
                            }, "تعديل"),
                          if (widget.onEdit != null) SizedBox(height: 12.h),
                          
                          if (widget.onDelete != null)
                            _iconBtn(Icons.delete_outline_rounded, Colors.red, widget.onDelete!, "حذف"),
                          if (widget.onDelete != null) SizedBox(height: 12.h),
                          
                          Theme(
                            data: Theme.of(context).copyWith(
                              popupMenuTheme: PopupMenuThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                            ),
                            child: PopupMenuButton<String>(
                              tooltip: "المزيد",
                              child: Container(
                                padding: EdgeInsets.all(10.r),
                                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8.r)),
                                child: Icon(Icons.more_vert_rounded, color: Colors.grey[800], size: 24.sp),
                              ),
                              onSelected: (val) {
                                if (val == 'details') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailsScreen(
                                    property: widget.property,
                                    currentUserId: widget.currentUserId,
                                    role: widget.role,
                                  )));
                                }
                                if (val == 'share' && widget.onShareInternal != null) widget.onShareInternal!();
                                if (val == 'download') WhatsappShareHelper.downloadImages(context, widget.property);
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.visibility_rounded, color: Colors.teal, size: 20.sp), SizedBox(width: 8.w), const Text("التفاصيل")])),
                                if (widget.onShareInternal != null)
                                  PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, color: Colors.purple, size: 20.sp), SizedBox(width: 8.w), const Text("مشاركة مع زميل")])),
                                if (widget.property.images.isNotEmpty)
                                  PopupMenuItem(value: 'download', child: Row(children: [Icon(Icons.download_rounded, color: Colors.green, size: 20.sp), SizedBox(width: 8.w), const Text("تحميل الصور")])),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false, bool isPhone = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20.sp, color: Colors.grey[600]), SizedBox(width: 4.w)],
            Text(label, style: TextStyle(fontSize: 18.sp, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 4.h),
        SelectableText(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 24.sp : 20.sp,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w700,
            color: isHighlighted ? AppColors.brandPrimary : AppColors.textPrimary,
            letterSpacing: isPhone ? 1.5 : 0,
          ),
        ),
      ],
    );
  }
  
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 24.sp),
        ),
      ),
    );
  }

  // ─── Edit Mode (4 Columns Layout) ───
  Widget _buildEditMode() {
    final dataManager = di.sl<StaticDataManager>();
    final listingOptions = dataManager.getOptions('listing_type').toSet().toList();
    final propOptions = dataManager.getOptions('property_type').toSet().toList();
    final cities = dataManager.allCities;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Column 1: Images ───
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("الصور (بحد أقصى 10)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (var img in _existingImages)
                          _buildImageThumbnail(img.thumbnail, () => setState(() {
                            _imagesToDeleteObjects.add(img);
                            _existingImages.remove(img);
                          })),
                        for (int i = 0; i < _newImagesBytes.length; i++)
                          _buildMemoryThumbnail(_newImagesBytes[i], () => setState(() => _newImagesBytes.removeAt(i))),
                        if ((_existingImages.length + _newImagesBytes.length) < 10)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 60.w, height: 60.w,
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.r), border: Border.all(color: Colors.grey)),
                              child: const Icon(Icons.add_a_photo, color: Colors.grey, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
            ),
            
            // ─── Column 2: Info ───
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTextField(
                    "كود العقار *", 
                    _propertyCodeController, 
                    errorText: _propertyCodeError,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                      UpperCaseTextFormatter(),
                    ],
                    hintText: "مثال: APT-123",
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDropdown("نوع العقار *", _selectedPropertyType, propOptions, (val) {
                        setState(() { _selectedPropertyType = val; _propertyTypeError = null; });
                      }, errorText: _propertyTypeError)),
                      SizedBox(width: 8.w),
                      Expanded(child: _buildDropdown("نوع الإعلان *", _selectedListingType, listingOptions, (val) {
                        setState(() { _selectedListingType = val; _listingTypeError = null; });
                      }, errorText: _listingTypeError)),
                      SizedBox(width: 8.w),
                      Expanded(child: _buildCityDropdown("المدينة *", _selectedCityId, cities, (val) {
                        setState(() { _selectedCityId = val; _cityError = null; });
                      }, errorText: _cityError)),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1, 
                        child: _buildTextField(
                          "السعر *", 
                          _priceController, 
                          isNumber: true, 
                          errorText: _priceError,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ThousandsFormatter(),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(flex: 1, child: const SizedBox.shrink()),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
            ),
            
            // ─── Column 3: Owner & Desc ───
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildTextField("اسم المالك", _ownerNameController, isRtl: true)),
                        SizedBox(width: 8.w),
                        Expanded(child: _buildTextField("رقم المالك *", _ownerPhoneController, isNumber: true, errorText: _ownerPhoneError)),
                      ],
                    ),
                  SizedBox(height: 12.h),
                  _buildTextField(
                    "الوصف *", 
                    _descController, 
                    maxLines: 4, 
                    isRtl: true,
                    errorText: _descError,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.open_in_new_rounded, color: AppColors.brandPrimary, size: 24.sp),
                      onPressed: _showDescriptionEditorDialog,
                      tooltip: "فتح الوصف في نافذة مكبرة",
                    ),
                  ),
                ],
              ),
              ),
            ),
            
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: VerticalDivider(width: 1, thickness: 1, color: AppColors.borderSubtle),
            ),
            
            // ─── Column 4: Actions ───
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: _isSavingInline 
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.check_circle_rounded),
                  label: Text("حفظ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                  onPressed: _isSavingInline ? null : _saveInlineProperty,
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_rounded),
                  label: Text("إلغاء", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  onPressed: _isSavingInline ? null : () {
                    if (widget.isAddingMode) {
                      widget.onCancelAdd?.call();
                    } else {
                      setState(() => _isEditing = false);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String url, VoidCallback onDelete) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: CachedNetworkImage(imageUrl: url, width: 60.w, height: 60.w, fit: BoxFit.cover),
        ),
        Positioned(
          top: 0, right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(padding: EdgeInsets.all(2.r), color: Colors.red, child: const Icon(Icons.close, color: Colors.white, size: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryThumbnail(Uint8List bytes, VoidCallback onDelete) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Image.memory(bytes, width: 60.w, height: 60.w, fit: BoxFit.cover),
        ),
        Positioned(
          top: 0, right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(padding: EdgeInsets.all(2.r), color: Colors.red, child: const Icon(Icons.close, color: Colors.white, size: 14)),
          ),
        ),
      ],
    );
  }

  void _showDescriptionEditorDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text("وصف العقار", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 0.6.sw,
              height: 0.6.sh,
              child: TextFormField(
                controller: _descController,
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "اكتب وصف العقار هنا...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  contentPadding: EdgeInsets.all(16.w),
                ),
                style: TextStyle(fontSize: 20.sp, height: 1.6, fontWeight: FontWeight.w600),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("تم", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1, bool isRtl = false, Widget? suffixIcon, String? errorText, List<TextInputFormatter>? inputFormatters, String? hintText}) {
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        keyboardType: maxLines > 1 ? TextInputType.multiline : (isNumber ? TextInputType.number : TextInputType.text),
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: maxLines > 1 ? 20.h : 18.h),
          isDense: true,
          suffixIcon: suffixIcon,
          errorText: errorText,
          errorStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _buildDropdown(String label, String? value, List<String> options, ValueChanged<String?> onChanged, {String? errorText}) {
    return DropdownMenu<String>(
      expandedInsets: EdgeInsets.zero,
      menuHeight: 250,
      enableFilter: true,
      enableSearch: false,
      errorText: errorText,
      label: Text(label, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
      initialSelection: options.contains(value) ? value : null,
      onSelected: onChanged,
      dropdownMenuEntries: options.map((e) => DropdownMenuEntry<String>(value: e, label: e)).toList(),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        isDense: true,
      ),
      textStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }
  
  Widget _buildCityDropdown(String label, int? value, List<dynamic> cities, ValueChanged<int?> onChanged, {String? errorText}) {
    return DropdownMenu<int>(
      expandedInsets: EdgeInsets.zero,
      menuHeight: 250,
      enableFilter: true,
      enableSearch: false,
      errorText: errorText,
      label: Text(label, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
      initialSelection: value,
      onSelected: onChanged,
      dropdownMenuEntries: cities.map((c) => DropdownMenuEntry<int>(value: c.id, label: c.name)).toList(),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        isDense: true,
      ),
      textStyle: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  Color _getApprovalColor(String? status) {
    if (status == null) return Colors.orange;
    if (status.contains('موافق') || status.contains('مقبول')) return Colors.green;
    if (status.contains('مرفوض')) return Colors.red;
    return Colors.orange; // 'في الانتظار' or other
  }

  void _showManagerNotesDialog(String notes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.notes_rounded, color: Colors.red, size: 24.sp),
            SizedBox(width: 8.w),
            Text('ملاحظات المدير', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18.sp, fontFamily: 'Cairo')),
          ],
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            notes,
            style: TextStyle(fontSize: 16.sp, height: 1.5, color: Colors.grey[800], fontFamily: 'Cairo'),
            textAlign: TextAlign.right,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
