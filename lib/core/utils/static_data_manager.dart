import 'dart:convert';
import 'package:flutter/services.dart';

import '../../data/models/location_model.dart';
import '../../data/models/property_type_model.dart';


class StaticDataManager {
  // Singleton Pattern لضمان وجود نسخة واحدة فقط في التطبيق
  static final StaticDataManager _instance = StaticDataManager._internal();
  factory StaticDataManager() => _instance;
  StaticDataManager._internal();

  List<Governorate> _governorates = [];
  List<City> _cities = [];
  List<ListingType> _listingTypes = [];
  List<PropertyType> _propertyTypes = [];

  // دالة التحميل الأساسية
  Future<void> initialize() async {
    // 1. تحميل المواقع
    final String govRes = await rootBundle.loadString('assets/data/governorates.json');
    _governorates = (json.decode(govRes) as List).map((i) => Governorate.fromJson(i)).toList();

    final String cityRes = await rootBundle.loadString('assets/data/cities.json');
    _cities = (json.decode(cityRes) as List).map((i) => City.fromJson(i)).toList();

    // 2. تحميل إعدادات العقارات
    final String propRes = await rootBundle.loadString('assets/data/property_config.json');
    final Map<String, dynamic> propData = json.decode(propRes);

    _listingTypes = (propData['listing_types'] as List).map((i) => ListingType.fromJson(i)).toList();
    _propertyTypes = (propData['property_types'] as List).map((i) => PropertyType.fromJson(i)).toList();
  }

  // Getters
  List<Governorate> get governorates => _governorates;
  List<ListingType> get listingTypes => _listingTypes;
  List<PropertyType> get propertyTypes => _propertyTypes;

  // دوال الفلترة الذكية
  List<City> getCitiesByGov(String govId) => _cities.where((c) => c.govId == govId).toList();

  List<UnitType> getUnitsByPropertyType(String typeId) {
    return _propertyTypes.firstWhere((p) => p.id == typeId).units;
  }
}