class DesignImageModel {
  final String id;
  final String designId;
  final String imageUrl;
  final DateTime createdAt;

  DesignImageModel({
    required this.id,
    required this.designId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory DesignImageModel.fromJson(Map<String, dynamic> json) {
    return DesignImageModel(
      id: json['id'] is int ? json['id'].toString() : json['id'] as String,
      designId: json['design_id'] is int ? json['design_id'].toString() : json['design_id'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'design_id': designId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
