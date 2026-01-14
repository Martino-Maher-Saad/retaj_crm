import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/property_model.dart';
import '../cubit/property_details_cubit.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;
  final PageController _pageController = PageController();

  PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PropertyDetailsCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // خلفية رمادية فاتحة جداً للراحة البصرية
        appBar: AppBar(
          title: Text("Property ID: #${property.id.substring(0, 5)}",
              style: AppTextStyles.blue16Bold.copyWith(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // إذا كان العرض أكبر من 900px نستخدم نظام العمودين
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout(context);
            } else {
              return _buildMobileLayout(context);
            }
          },
        ),
      ),
    );
  }

  // --- 1. Desktop Layout (Two Columns) ---
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الجانب الأيسر: الصور والوصف
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildMainImageWithSlider(context),
                SizedBox(height: 24.h),
                _buildDescriptionCard(),
              ],
            ),
          ),
          SizedBox(width: 24.w),
          // الجانب الأيمن: السعر، المواصفات، وبيانات المالك
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildPriceAndActionCard(),
                SizedBox(height: 20.h),
                _buildSpecsGridCard(),
                SizedBox(height: 20.h),
                _buildOwnerInfoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Image Section with Slider ---
  Widget _buildMainImageWithSlider(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => _openFullScreenGallery(context, property.images),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: property.images.isEmpty ? 1 : property.images.length,
                    onPageChanged: (index) => context.read<PropertyDetailsCubit>().updateImageIndex(index),
                    itemBuilder: (context, index) {
                      if (property.images.isEmpty) return _buildNoImage();
                      return CachedNetworkImage(
                        imageUrl: property.getPreviewUrl(property.images[index]), // جودة متوسطة
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                _buildImageCounter(),
              ],
            ),
          ),
        ),
        if (property.images.length > 1) ...[
          SizedBox(height: 12.h),
          _buildThumbnailBar(),
        ],
      ],
    );
  }

  Widget _buildThumbnailBar() {
    return BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
      builder: (context, state) {
        return SizedBox(
          height: 70.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: property.images.length,
            itemBuilder: (context, index) {
              bool isSelected = state.currentIndex == index;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                },
                child: Container(
                  width: 90.w,
                  margin: EdgeInsets.only(right: 10.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.transparent, width: 2),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(property.getThumbnailUrl(property.images[index])),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- 3. Specifications Grid ---
  Widget _buildSpecsGridCard() {
    final specs = [
      {"l": "Area", "v": "${property.area} m²", "i": Icons.square_foot},
      {"l": "Rooms", "v": property.rooms, "i": Icons.bed},
      {"l": "Baths", "v": property.baths, "i": Icons.bathtub},
      {"l": "Floor", "v": property.floor, "i": Icons.layers},
      {"l": "Lounges", "v": property.lounges, "i": Icons.chair},
      {"l": "Type", "v": property.type, "i": Icons.home},
    ];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Property Details", style: AppTextStyles.blue16Bold.copyWith(color: Colors.black)),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 10.w, mainAxisSpacing: 10.h,
            ),
            itemCount: specs.length,
            itemBuilder: (context, i) => _buildSpecItem(specs[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(Map<String, dynamic> spec) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
          child: Icon(spec['i'] as IconData, size: 18.sp, color: AppColors.primaryBlue),
        ),
        SizedBox(width: 10.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(spec['l'].toString(), style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
            Text(spec['v'].toString(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  // --- المساعدات (Helper Widgets) ---

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16.r),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
  );

  Widget _buildPriceAndActionCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Price", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
              Text(property.category, style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8.h),
          Text("${NumberFormat.decimalPattern().format(property.price)} EGP",
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlueDark)),
          const Divider(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: const Text("Contact Support", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // باقي الميثودز (Description, OwnerInfo, NoImage) تتبع نفس النمط...
  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Description", style: AppTextStyles.blue16Bold.copyWith(color: Colors.black)),
          SizedBox(height: 12.h),
          Text(property.descAr.isEmpty ? property.descEn : property.descAr,
              style: TextStyle(fontSize: 14.sp, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration().copyWith(color: const Color(0xFF1E293B)), // لون غامق للمعلومات السرية
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.amber, size: 20),
              SizedBox(width: 10.w),
              Text("Owner Information", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          _ownerDetailRow(Icons.person, "Name", property.ownerName),
          SizedBox(height: 12.h),
          _ownerDetailRow(Icons.phone, "Phone", property.ownerPhone),
        ],
      ),
    );
  }

  Widget _ownerDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16.sp),
        SizedBox(width: 8.w),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildImageCounter() {
    return Positioned(
      bottom: 16, right: 16,
      child: BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
        builder: (context, state) => Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20.r)),
          child: Text("${state.currentIndex + 1} / ${property.images.length}", style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildNoImage() => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50));

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMainImageWithSlider(context),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildPriceAndActionCard(),
                SizedBox(height: 16.h),
                _buildSpecsGridCard(),
                SizedBox(height: 16.h),
                _buildDescriptionCard(),
                SizedBox(height: 16.h),
                _buildOwnerInfoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenGallery(BuildContext context, List<String> images) {
    if (images.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) => InteractiveViewer(child: Center(child: CachedNetworkImage(imageUrl: images[index]))),
      ),
    )));
  }
}