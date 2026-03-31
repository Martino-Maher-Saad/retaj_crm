import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/property_image_model.dart';

class ImageSection extends StatelessWidget {
  final List<PropertyImageModel> existingImages;
  final List<Uint8List> newImagesBytes;
  final Function(PropertyImageModel) onRemoveExisting;
  final Function(int) onRemoveNew;
  final VoidCallback onAddPressed;

  const ImageSection({
    super.key,
    required this.existingImages,
    required this.newImagesBytes,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...existingImages.map((img) => _imgBox(
                CachedNetworkImage(imageUrl: img.imageUrl, fit: BoxFit.cover),
                onDel: () => onRemoveExisting(img),
              )),
          ...newImagesBytes.asMap().entries.map((e) => _imgBox(
                Image.memory(e.value, fit: BoxFit.cover),
                onDel: () => onRemoveNew(e.key),
              )),
          if ((newImagesBytes.length + existingImages.length) < 10) _addImgBtn(),
        ],
      ),
    );
  }

  Widget _imgBox(Widget img, {required VoidCallback onDel}) => Container(
        width: 90.w,
        margin: EdgeInsets.only(right: 8.w),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox.expand(child: img),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onDel,
                child: CircleAvatar(
                  radius: 11.r,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.close, size: 14.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _addImgBtn() => GestureDetector(
        onTap: onAddPressed,
        child: Container(
          width: 90.w,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: const Icon(Icons.add_a_photo, color: Colors.blue),
        ),
      );
}
