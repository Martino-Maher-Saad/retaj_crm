class PropertyImageModel {
  final String? id;
  final String propertyId;
  final String imageUrl;

  PropertyImageModel({this.id, required this.propertyId, required this.imageUrl});

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) {
    return PropertyImageModel(
      id: json['id']?.toString(),
      propertyId: json['property_id']?.toString() ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}