import 'package:flutter/foundation.dart';
import '../../data/models/property_model.dart';

/// يربط تحديثات مهام العقارات بشاشة المخزون بدون مشاركة الـ Cubit.
class PropertySyncNotifier extends ChangeNotifier {
  PropertyModel? _updated;
  String? _deletedId;
  bool _needsRefresh = false;

  void notifyUpdated(PropertyModel property) {
    _updated = property;
    _deletedId = null;
    _needsRefresh = false;
    notifyListeners();
  }

  void notifyDeleted(String propertyId) {
    _deletedId = propertyId;
    _updated = null;
    _needsRefresh = false;
    notifyListeners();
  }

  /// يُستخدم عند bulk transfer — يطلب من صفحة العقارات إعادة تحميل البيانات
  void notifyRefresh() {
    _needsRefresh = true;
    _updated = null;
    _deletedId = null;
    notifyListeners();
  }

  PropertyModel? consumeUpdate() {
    final value = _updated;
    _updated = null;
    return value;
  }

  String? consumeDeletion() {
    final value = _deletedId;
    _deletedId = null;
    return value;
  }

  bool consumeRefresh() {
    final value = _needsRefresh;
    _needsRefresh = false;
    return value;
  }
}
