import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            (property.id.length >= 8)
                ? "Property ID: ${property.id.substring(0, 8)}"
                : "Property Details",
            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Builder(builder: (newContext) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Optimized Image Section (Ratio 16:9)
                _buildImageSection(newContext, property.images),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Price and Date
                      _buildPriceAndDate(),

                      const SizedBox(height: 8),
                      Text(
                        "${property.city} - ${property.category}",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w500),
                      ),

                      const Divider(height: 30, thickness: 1),

                      // 3. Technical Specifications (List view instead of Grid)
                      const Text("Specifications",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildPropertySpecsList(property),

                      const Divider(height: 40, thickness: 1),

                      // 4. Description
                      _buildDescriptionSection(),

                      const SizedBox(height: 30),

                      // 5. Internal Owner Data
                      _buildOwnerSection(property),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // استخدام نسبة 1.77 لجعل الصورة عرضية (أقل ضخامة في الارتفاع)
  Widget _buildImageSection(BuildContext context, List<String> images) {
    return AspectRatio(
      aspectRatio: 1.77,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _openFullScreenGallery(context, images),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.isEmpty ? 1 : images.length,
              onPageChanged: (index) =>
                  context.read<PropertyDetailsCubit>().updateImageIndex(index),
              itemBuilder: (context, index) {
                if (images.isEmpty) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: property.getPreviewUrl(images[index]), // Optimization logic applies here
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[100]),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                );
              },
            ),
          ),

          if (images.length > 1) ...[
            _navArrow(
              icon: Icons.arrow_back_ios_new,
              left: 10,
              onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            ),
            _navArrow(
              icon: Icons.arrow_forward_ios,
              right: 10,
              onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
            ),
          ],

          if (images.isNotEmpty)
            Positioned(
              bottom: 15,
              right: 15,
              child: BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
                builder: (context, state) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text("${state.currentIndex + 1} / ${images.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // تحويل الـ Grid إلى List لسهولة التحكم في العناصر
  Widget _buildPropertySpecsList(PropertyModel p) {
    final List<Map<String, dynamic>> specs = [
      {"label": "Area", "value": "${p.area} m²", "icon": Icons.straighten},
      {"label": "Type", "value": p.type, "icon": Icons.home_work_outlined},
      {"label": "Rooms", "value": p.rooms, "icon": Icons.bed_outlined},
      {"label": "Bathrooms", "value": p.baths, "icon": Icons.bathtub_outlined},
      {"label": "Floor", "value": p.floor == 0 ? "Ground" : p.floor.toString(), "icon": Icons.layers_outlined},
      {"label": "Finishing", "value": p.finishing_type.isEmpty ? "N/A" : p.finishing_type, "icon": Icons.format_paint_outlined},
      {"label": "Status", "value": p.isAvailable ? "Available" : "Closed", "icon": Icons.info_outline},
    ];

    return Column(
      children: specs.map((spec) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(spec['icon'], size: 22, color: const Color(0xFF2563EB)),
              const SizedBox(width: 15),
              Text(
                "${spec['label']}:",
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const Spacer(),
              Text(
                spec['value'].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceAndDate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${NumberFormat.decimalPattern().format(property.price)} EGP",
          style: const TextStyle(fontSize: 24, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
        ),
        if (property.createdAt != null)
          Text(
            DateFormat('dd/MM/yyyy').format(property.createdAt!),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    if (property.descEn.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          property.descEn,
          style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildOwnerSection(PropertyModel p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_person_outlined, color: Colors.blueGrey[700], size: 20),
              const SizedBox(width: 8),
              Text("Internal Info",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
            ],
          ),
          const Divider(height: 24),
          _ownerInfoRow(Icons.person_outline, "Owner", p.ownerName),
          const SizedBox(height: 10),
          _ownerInfoRow(Icons.phone_outlined, "Phone", p.ownerPhone),
        ],
      ),
    );
  }

  Widget _ownerInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _openFullScreenGallery(BuildContext context, List<String> images) {
    if (images.isEmpty) return;
    final int initialPage = context.read<PropertyDetailsCubit>().state.currentIndex;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), elevation: 0),
          body: PageView.builder(
            controller: PageController(initialPage: initialPage),
            itemCount: images.length,
            itemBuilder: (context, index) => InteractiveViewer(
              child: Center(child: CachedNetworkImage(imageUrl: images[index], fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navArrow({required IconData icon, double? left, double? right, required VoidCallback onTap}) {
    return Positioned(
      top: 0, bottom: 0, left: left, right: right,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}