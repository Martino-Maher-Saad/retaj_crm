class DesignLinkModel {
  final String title;
  final String url;

  DesignLinkModel({required this.title, required this.url});

  factory DesignLinkModel.fromJson(Map<String, dynamic> json) {
    return DesignLinkModel(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}

class DesignImageModel {
  final String id;
  final String designId;
  final String imageUrl;
  final bool isThumbnail;

  DesignImageModel({
    required this.id,
    required this.designId,
    required this.imageUrl,
    required this.isThumbnail,
  });

  factory DesignImageModel.fromJson(Map<String, dynamic> json) {
    return DesignImageModel(
      id: json['id'] ?? '',
      designId: json['design_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      isThumbnail: json['is_thumbnail'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'design_id': designId,
      'image_url': imageUrl,
      'is_thumbnail': isThumbnail,
    };
  }
}

class DesignModel {
  final String id;
  final String descAr;
  final String roomTypeId;
  final String? roomTypeName;
  final String styleId;
  final String? styleName;
  final List<DesignLinkModel> links;
  final DateTime createdAt;
  final String addedBy;
  final String? addedByName;
  final List<DesignImageModel>? images;

  // Getters للواجهة التي تم إنشاؤها مسبقاً
  String? get roomType => roomTypeName;
  String? get style => styleName;
  Map<String, dynamic>? get profile => addedByName != null ? {'first_name': addedByName?.split(' ').first, 'last_name': addedByName?.split(' ').length != 1 ? addedByName?.split(' ').last : ''} : null;

  DesignModel({
    required this.id,
    required this.descAr,
    required this.roomTypeId,
    this.roomTypeName,
    required this.styleId,
    this.styleName,
    required this.links,
    required this.createdAt,
    required this.addedBy,
    this.addedByName,
    this.images,
  });

  factory DesignModel.fromJson(Map<String, dynamic> json) {
    List<DesignLinkModel> parsedLinks = [];
    if (json['links'] != null) {
      if (json['links'] is List) {
        parsedLinks = (json['links'] as List)
            .map((e) => DesignLinkModel.fromJson(e))
            .toList();
      }
    }

    List<DesignImageModel>? parsedImages;
    if (json['design_images'] != null) {
      parsedImages = (json['design_images'] as List)
          .map((e) => DesignImageModel.fromJson(e))
          .toList();
    }

    String? rName;
    if (json['design_room_types'] != null) {
      rName = json['design_room_types']['name_ar'];
    }

    String? sName;
    if (json['design_styles'] != null) {
      sName = json['design_styles']['name_ar'];
    }

    String? adderName;
    if (json['profiles'] != null) {
      adderName = '${json['profiles']['first_name'] ?? ''} ${json['profiles']['last_name'] ?? ''}'.trim();
    }

    return DesignModel(
      id: json['id'] ?? '',
      descAr: json['desc_ar'] ?? '',
      roomTypeId: json['room_type_id'] ?? '',
      roomTypeName: rName,
      styleId: json['style_id'] ?? '',
      styleName: sName,
      links: parsedLinks,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
      addedBy: json['added_by'] ?? '',
      addedByName: adderName,
      images: parsedImages,
    );
  }

  Map<String, dynamic> toJson({List<double>? embedding}) {
    final data = <String, dynamic>{
      'desc_ar': descAr,
      'room_type_id': roomTypeId,
      'style_id': styleId,
      'links': links.map((e) => e.toJson()).toList(),
      'added_by': addedBy,
    };
    
    if (embedding != null) {
      data['embedding'] = embedding;
    }
    
    return data;
  }
}
