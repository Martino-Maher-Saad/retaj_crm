import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/property_model.dart';
import '../cubit/property_details_cubit.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    // حل مشكلة الـ Context: نغلف الشاشة بـ BlocProvider
    return BlocProvider(
      create: (context) => PropertyDetailsCubit(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Property ID: ${property.id?.substring(0, 8)}...",
              style: const TextStyle(color: Colors.black, fontSize: 16)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        // استخدمنا Builder هنا لإنشاء context جديد يقع "تحت" الـ BlocProvider
        body: Builder(
            builder: (newContext) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. قسم الصور
                    _buildImageSection(newContext, property.images ?? []),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. المعلومات الأساسية
                          Text(property.titleEn ?? "No Title",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("${property.price} EGP",
                              style: const TextStyle(fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold)),

                          const Divider(height: 40),

                          // 3. شبكة مواصفات العقار (من الـ Model)
                          _buildPropertyGrid(property),

                          const SizedBox(height: 30),

                          // 4. الوصف
                          const Text("Description",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            property.descEn ?? "No description provided.",
                            style: const TextStyle(color: Colors.black87, height: 1.5),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }

  // ويدجت الصور مع المؤشر والـ Cubit
  Widget _buildImageSection(BuildContext context, List<String> images) {
    return AspectRatio(
      aspectRatio: 800 / 600, // الالتزام بالمقاس المطلوب
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.isEmpty ? 1 : images.length,
            onPageChanged: (index) {
              // تحديث الـ Cubit عند تغيير الصورة
              context.read<PropertyDetailsCubit>().updateImageIndex(index);
            },
            itemBuilder: (context, index) {
              if (images.isEmpty) {
                return Image.network('https://upload.wikimedia.org/wikipedia/commons/a/a3/Image-not-found.png', fit: BoxFit.cover);
              }
              return _KeepAliveImage(imageUrl: images[index]);
            },
          ),

          // المؤشر الرقمي (يسمع للـ Cubit)
          Positioned(
            bottom: 20,
            right: 20,
            child: BlocBuilder<PropertyDetailsCubit, PropertyDetailsState>(
              builder: (context, state) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${images.isEmpty ? 0 : state.currentIndex + 1} / ${images.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // عرض بيانات الـ Model بشكل منظم
  Widget _buildPropertyGrid(PropertyModel p) {
    final Map<String, String> specs = {
      "Area": "${p.area ?? 0} m²",
      "Rooms": "${p.rooms ?? 0}",
      "Baths": "${p.baths ?? 0}",
      "Floor": "${p.baths ?? 'N/A'}",
      "Type": p.type ?? "N/A",
      "Status": "${p.isAvailable}" ?? "N/A",
      "Finishing": p.descEn ?? "N/A",
      "Furnished": p.city,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        String key = specs.keys.elementAt(index);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Text("$key: ", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Expanded(
                child: Text(specs[key]!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ويدجت الصورة مع الحفاظ على الحالة (Keep Alive) لمنع إعادة التحميل
class _KeepAliveImage extends StatefulWidget {
  final String imageUrl;
  const _KeepAliveImage({required this.imageUrl});

  @override
  State<_KeepAliveImage> createState() => _KeepAliveImageState();
}

class _KeepAliveImageState extends State<_KeepAliveImage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // يمنع حذف الصورة من الذاكرة عند التمرير

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.grey[100]),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
    );
  }
}