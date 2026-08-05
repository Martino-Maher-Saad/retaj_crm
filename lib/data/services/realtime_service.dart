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
    );

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'leads',
      callback: (payload) => _handlePostgresChange('lead', payload),
    );

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'properties',
      callback: (payload) => _handlePostgresChange('property', payload),
    );

    _channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'property_shares',
      callback: (payload) => _handlePostgresChange('property_share', payload),
    );

    _channel.subscribe();
  }

  void _handlePostgresChange(String entity, PostgresChangePayload payload) {
    String action;
    if (payload.eventType == PostgresChangeEvent.insert) {
      action = 'insert';
    } else if (payload.eventType == PostgresChangeEvent.update) {
      action = 'update';
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      action = 'delete';
    } else {
      return;
    }

    final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
    if (record.isEmpty || !record.containsKey('id')) return;

    final event = CrmEvent(
      entity: entity,
      action: action,
      id: record['id'].toString(),
      assignedTo: record['assigned_to']?.toString(),
      createdBy: record['created_by']?.toString(),
      data: record,
    );

    if (action == 'insert') {
      // Delay insert events by 4 seconds to allow time for images to upload and other related records to finish.
      Future.delayed(const Duration(seconds: 4), () {
        if (!_eventController.isClosed) {
          _eventController.add(event);
        }
      });
    } else {
      _eventController.add(event);
    }
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
