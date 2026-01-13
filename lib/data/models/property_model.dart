class PropertyModel {
  final String id;
  final String descAr;
  final String descEn;
  final int rooms;
  final int baths;
  final String locationAr;
  final String locationEn;
  final String locationMap;
  final String ownerName;
  final String ownerPhone;
  final String createdBy;
  final DateTime? createdAt;
  final double price;
  final double area;
  final String city;
  final bool isAvailable;
  final String type;
  final String category;
  final int floor;
  final bool is_last_floor;
  final int lounges;
  final int kitchens;
  final int balconies;
  final String finishing_type;
  final bool flat_share;
  final List<String> images;

  PropertyModel({
    required this.id,
    required this.descAr,
    required this.descEn,
    required this.rooms,
    required this.baths,
    required this.locationAr,
    required this.locationEn,
    required this.locationMap,
    required this.ownerName,
    required this.ownerPhone,
    required this.createdBy,
    this.createdAt,
    required this.price,
    required this.area,
    required this.city,
    required this.isAvailable,
    required this.type,
    required this.category,
    required this.floor,
    required this.is_last_floor,
    required this.lounges,
    required this.kitchens,
    required this.balconies,
    required this.finishing_type,
    required this.flat_share,
    this.images = const [],
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? imagesData = json['property_images'];
    return PropertyModel(
      id: json['id'] ?? '',
      descAr: json['desc_ar'] ?? '',
      descEn: json['desc_en'] ?? '',
      rooms: json['rooms'] ?? 0,
      baths: json['baths'] ?? 0,
      locationAr: json['location_ar'] ?? '',
      locationEn: json['location_en'] ?? '',
      locationMap: json['location_map'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerPhone: json['owner_phone'] ?? '',
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      city: json['city'] ?? '',
      isAvailable: json['is_available'] ?? true,
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      floor: json['floor'] ?? 0,
      is_last_floor: json['is_last_floor'] ?? false,
      lounges: json['lounges'] ?? 0,
      kitchens: json['kitchens'] ?? 0,
      balconies: json['balconies'] ?? 0,
      finishing_type: json['finishing_type'] ?? '',
      flat_share: json['flat_share'] ?? false,
      images: imagesData != null
          ? imagesData.map((img) => img['image_url'] as String).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'desc_ar': descAr,
      'desc_en': descEn,
      'rooms': rooms,
      'baths': baths,
      'location_ar': locationAr,
      'location_en': locationEn,
      'location_map': locationMap,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'created_by': createdBy,
      'price': price,
      'area': area,
      'city': city,
      'is_available': isAvailable,
      'type': type,
      'category': category,
      'floor': floor,
      'is_last_floor': is_last_floor,
      'lounges': lounges,
      'kitchens': kitchens,
      'balconies': balconies,
      'finishing_type': finishing_type,
      'flat_share': flat_share,
    };
  }

  PropertyModel copyWith({
    String? descAr,
    String? descEn,
    int? rooms,
    int? baths,
    String? locationAr,
    String? locationEn,
    String? locationMap,
    String? ownerName,
    String? ownerPhone,
    double? price,
    double? area,
    String? city,
    bool? isAvailable,
    String? type,
    String? category,
    int? floor,
    bool? is_last_floor,
    int? lounges,
    int? kitchens,
    int? balconies,
    String? finishing_type,
    bool? flat_share,
    List<String>? images,
  }) {
    return PropertyModel(
      id: this.id,
      createdBy: this.createdBy,
      createdAt: this.createdAt,
      descAr: descAr ?? this.descAr,
      descEn: descEn ?? this.descEn,
      rooms: rooms ?? this.rooms,
      baths: baths ?? this.baths,
      locationAr: locationAr ?? this.locationAr,
      locationEn: locationEn ?? this.locationEn,
      locationMap: locationMap ?? this.locationMap,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      price: price ?? this.price,
      area: area ?? this.area,
      city: city ?? this.city,
      isAvailable: isAvailable ?? this.isAvailable,
      type: type ?? this.type,
      category: category ?? this.category,
      floor: floor ?? this.floor,
      is_last_floor: is_last_floor ?? this.is_last_floor,
      lounges: lounges ?? this.lounges,
      kitchens: kitchens ?? this.kitchens,
      balconies: balconies ?? this.balconies,
      finishing_type: finishing_type ?? this.finishing_type,
      flat_share: flat_share ?? this.flat_share,
      images: images ?? this.images,
    );
  }
}

extension PropertyImageOptimizer on PropertyModel {
  String getThumbnailUrl(String url) {
    return "$url?width=250&quality=30";
  }
  String getPreviewUrl(String url) {
    return "$url?width=800&quality=50";
  }
}