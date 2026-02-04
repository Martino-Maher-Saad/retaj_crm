import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/property_cache_manager.dart';
import '../../../data/models/property_model.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(property.titleAr ?? "تفاصيل العقار", style: AppTextStyles.blue16Bold),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. معرض الصور (Image Header)
            _buildImageHeader(),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // 2. بطاقة المعلومات الأساسية والسعر
                  _buildMainInfoCard(),
                  SizedBox(height: 16.h),

                  // 3. المواصفات الفنية (التقسيم الداخلي)
                  _buildSectionCard("المواصفات الفنية", Icons.straighten, _buildSpecsGrid()),
                  SizedBox(height: 16.h),

                  // 4. الموقع والتفاصيل الجغرافية
                  _buildSectionCard("الموقع", Icons.location_on, _buildLocationDetails()),
                  SizedBox(height: 16.h),

                  // 5. الوصف النصي
                  _buildSectionCard("الوصف", Icons.description, _buildDescriptionSection()),
                  SizedBox(height: 16.h),

                  // 6. بيانات المالك والملاحظات السرية (مهمة للموظف)
                  _buildSectionCard("بيانات الإدارة والمالك", Icons.admin_panel_settings, _buildOwnerSection()),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- مكونات الصفحة ---

  Widget _buildImageHeader() {
    final images = property.images ?? [];
    return SizedBox(
      height: 250.h,
      child: images.isEmpty
          ? Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50))
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) => Container(
          width: 340.w,
          margin: EdgeInsets.only(right: 8.w),
          child: CachedNetworkImage(
            imageUrl: images[index].imageUrl ?? '',
            cacheManager: PropertyCacheManager.instance,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    bool isRent = property.listingTypeAr?.toLowerCase() == 'rent';
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _badge("${property.listingTypeAr} - ${property.propertyTypeAr}", AppColors.primaryBlue),
              Text("ID: #${property.id.substring(0, 6)}", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
            ],
          ),
          SizedBox(height: 12.h),
          Text("${property.price?.toStringAsFixed(0)} EGP", style: AppTextStyles.blue20Medium.copyWith(fontSize: 24.sp, fontWeight: FontWeight.w900)),
          if (isRent) Text("دورية الدفع: ${property.rentalFrequency}", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          Text(property.titleAr ?? '', style: AppTextStyles.blue16Bold.copyWith(color: Colors.black)),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid() {
    return Wrap(
      spacing: 20.w,
      runSpacing: 20.h,
      children: [
        _specItem(Icons.king_bed, "الغرف", "${property.bedrooms}"),
        _specItem(Icons.bathtub, "الحمامات", "${property.bathrooms}"),
        _specItem(Icons.square_foot, "المساحة", "${property.builtArea} م²"),
        _specItem(Icons.layers, "الدور", "${property.floor}"),
        _specItem(Icons.format_paint, "التشطيب", property.completionStatus ?? "غير محدد"),
        _specItem(Icons.chair, "مفروش", property.furnished == "yes" ? "نعم" : "لا"),
      ],
    );
  }

  Widget _buildLocationDetails() {
    return Column(
      children: [
        _infoRow("المحافظة", property.governorateAr),
        _infoRow("المدينة", property.cityAr),
        _infoRow("المنطقة", property.regionAr),
        _infoRow("العنوان التفصيلي", property.locationInDetails),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("بالعربي:", style: TextStyle(fontWeight: FontWeight.bold)),
        Text(property.descAr ?? "لا يوجد وصف"),
        const Divider(height: 30),
        const Text("English:", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOwnerSection() {
    return Column(
      children: [
        _infoRow("اسم المالك", property.ownerName, icon: Icons.person),
        _infoRow("رقم الهاتف", property.ownerPhone, icon: Icons.phone, color: Colors.green),
        const Divider(),
        _infoRow("ملاحظات الموظفين", property.internalNotes, icon: Icons.note, isLong: true),
      ],
    );
  }

  // --- Helper UI Methods ---

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.primaryBlue, size: 20.sp), SizedBox(width: 8.w), Text(title, style: AppTextStyles.blue16Bold)]),
          const Divider(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _specItem(IconData icon, String label, String value) {
    return SizedBox(
      width: 80.w,
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22.sp),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value, {IconData? icon, Color? color, bool isLong = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 16.sp, color: AppColors.primaryBlue),
          if (icon != null) SizedBox(width: 8.w),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "---", style: TextStyle(color: color ?? Colors.black87))),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: Colors.black12.withOpacity(0.05)));

  Widget _badge(String text, Color color) => Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)), child: Text(text, style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold)));
}