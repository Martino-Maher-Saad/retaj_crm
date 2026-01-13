import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/property_model.dart';


class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // رابط الصورة المصغرة لتقليل استهلاك البيانات
    final bool hasImages = property.images.isNotEmpty;
    // داخل build الـ Card، استبدل thumbnailUrl بـ:
    final String thumbnailUrl = hasImages
        ? property.getThumbnailUrl(property.images.first)
        : "https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. صورة العقار مع Badge الحالة
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      width: 120,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // 2. تفاصيل العقار
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "${property.price} EGP",
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(property.city, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFeaturesRow(),
                  ],
                ),
              ),

              // 3. أزرار التحكم (تعديل - حذف)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blue), onPressed: onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: onDelete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ويدجت صغير لعرض أيقونات المميزات (غرف، حمامات، مساحة)
  Widget _buildFeaturesRow() {
    return Row(
      children: [
        _featureIcon(Icons.king_bed_outlined, "${property.rooms}"),
        const SizedBox(width: 10),
        _featureIcon(Icons.square_foot, "${property.area}m²"),
      ],
    );
  }

  Widget _featureIcon(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

}