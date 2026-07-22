import 'package:flutter/foundation.dart';
import '../../data/models/lead_model.dart';

class LeadSyncNotifier extends ChangeNotifier {
  LeadModel? _updated;
  String? _deletedId;

  void notifyUpdated(LeadModel lead) {
    _updated = lead;
    _deletedId = null;
    notifyListeners();
  }

  void notifyDeleted(String leadId) {
    _deletedId = leadId;
    _updated = null;
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
}
