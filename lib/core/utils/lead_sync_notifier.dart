import 'package:flutter/foundation.dart';
import '../../data/models/lead_model.dart';

class LeadSyncNotifier extends ChangeNotifier {
  LeadModel? _updated;
  String? _deletedId;

  bool _needsRefresh = false;

  void notifyUpdated(LeadModel lead) {
    _updated = lead;
    _deletedId = null;
    _needsRefresh = false;
    notifyListeners();
  }

  void notifyDeleted(String leadId) {
    _deletedId = leadId;
    _updated = null;
    _needsRefresh = false;
    notifyListeners();
  }
  
  void notifyRefresh() {
    _needsRefresh = true;
    _updated = null;
    _deletedId = null;
    notifyListeners();
  }

  LeadModel? consumeUpdate() {
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
