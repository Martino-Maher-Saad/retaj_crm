import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crm_event.dart';

class RealtimeService {
  final _supabase = Supabase.instance.client;
  final _eventController = StreamController<CrmEvent>.broadcast();
  late final RealtimeChannel _channel;

  Stream<CrmEvent> get eventStream => _eventController.stream;

  void init() {
    _channel = _supabase.channel('crm_updates');
    
    _channel.onBroadcast(
      event: 'crm_event',
      callback: (payload) {
        if (payload != null) {
          final event = CrmEvent.fromJson(Map<String, dynamic>.from(payload));
          _eventController.add(event);
        }
      },
    ).subscribe();
  }

  void broadcastEvent(CrmEvent event) {
    try {
      _channel.sendBroadcastMessage(
        event: 'crm_event',
        payload: event.toJson(),
      );
      _eventController.add(event); // Echo locally
    } catch (e) {
      print('Failed to broadcast event: $e');
    }
  }

  void dispose() {
    _channel.unsubscribe();
    _eventController.close();
  }
}
