import 'dart:convert';
import 'design_image_model.dart';
import 'profile_model.dart';

class DesignModel {
  final String id;
  final String? descAr;
  final String? roomType;
  final String? style;
  final DateTime createdAt;
  final String? addedBy;
  final List<double>? embedding;
  final List<DesignImageModel>? images;
  final ProfileModel? profile;

  DesignModel({
    required this.id,
    this.descAr,
    this.roomType,
    this.style,
    required this.createdAt,
    this.addedBy,
    this.embedding,
    this.images,
    this.profile,
  });

  factory DesignModel.fromJson(Map<String, dynamic> json) {
    return DesignModel(
      id: json['id'] is int ? json['id'].toString() : json['id'] as String,
      descAr: json['desc_ar'] as String?,
      roomType: json['room_type'] as String?,
      style: json['style'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      addedBy: json['added_by'] as String?,
      embedding: (() {
        final emb = json['embedding'];
        if (emb == null) return null;
        if (emb is String) {
          try {
            return List<double>.from(
              (jsonDecode(emb) as List).map((e) => double.parse(e.toString())),
            );
          } catch (_) {
            return null;
          }
        } else if (emb is List) {
          return List<double>.from(emb.map((e) => double.parse(e.toString())));
        }
        return null;
      })(),
      images: json['design_images'] != null
          ? (json['design_images'] as List).map((i) => DesignImageModel.fromJson(i)).toList()
          : null,
      profile: json['profiles'] != null ? ProfileModel.fromJson(json['profiles']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'desc_ar': descAr,
      'room_type': roomType,
      'style': style,
      'created_at': createdAt.toIso8601String(),
      'added_by': addedBy,
      if (embedding != null) 'embedding': embedding,
    };
  }
}
