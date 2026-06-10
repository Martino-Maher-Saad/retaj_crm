import 'package:flutter/foundation.dart';
import '../../data/models/property_model.dart';

/// يربط تحديثات مهام العقارات بشاشة المخزون بدون مشاركة الـ Cubit.
class PropertySyncNotifier extends ChangeNotifier {
  PropertyModel? _updated;
  String? _deletedId;

  void notifyUpdated(PropertyModel property) {
    _updated = property;
    _deletedId = null;
    notifyListeners();
  }

  void notifyDeleted(String propertyId) {
    _deletedId = propertyId;
    _updated = null;
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
}
