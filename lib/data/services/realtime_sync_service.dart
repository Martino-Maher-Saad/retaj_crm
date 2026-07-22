import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../core/di/injection_container.dart' as di;
import '../../core/utils/static_data_manager.dart';

/// Defines the types of operations that can happen in Realtime
enum RealtimeOpType { insert, update, delete }

/// Represents a payload from the Realtime broadcast
class RealtimePayload {
  final String table;
  final RealtimeOpType type;
  final Map<String, dynamic> oldRecord;
  final Map<String, dynamic> newRecord;

  RealtimePayload({
    required this.table,
    required this.type,
    required this.oldRecord,
    required this.newRecord,
  });
}

/// Centralized service to handle Supabase Realtime connections efficiently.
class RealtimeSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Channels
  RealtimeChannel? _operationsChannel;
  RealtimeChannel? _broadcastChannel;
  RealtimeChannel? _systemConfigChannel;

  // Stream for custom broadcast events (like bulk transfers)
  final _broadcastController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get broadcastEvents => _broadcastController.stream;

  // Event Bus (Broadcast Stream)
  final _eventController = StreamController<RealtimePayload>.broadcast();
  Stream<RealtimePayload> get events => _eventController.stream;

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    _setupSystemConfigChannel();
    _setupOperationsChannel();
    _setupBroadcastChannel();
  }

  void _setupBroadcastChannel() {
    _broadcastChannel = _supabase.channel('public:leads_broadcast');
    
    _broadcastChannel!.onBroadcast(
      event: 'bulk_transfer',
      callback: (payload) {
        if (kDebugMode) {
          print('Received Broadcast: bulk_transfer -> $payload');
        }
        _broadcastController.add({'event': 'bulk_transfer', 'payload': payload});
      },
    ).onBroadcast(
      event: 'lead_inserted',
      callback: (payload) {
        final record = payload['record'] as Map<String, dynamic>?;
        if (record != null) {
          _eventController.add(RealtimePayload(table: 'leads', type: RealtimeOpType.insert, oldRecord: const {}, newRecord: record));
        }
      },
    ).onBroadcast(
      event: 'lead_updated',
      callback: (payload) {
        final record = payload['record'] as Map<String, dynamic>?;
        if (record != null) {
          record['fetch_logs'] = false;
          _eventController.add(RealtimePayload(table: 'leads', type: RealtimeOpType.update, oldRecord: const {}, newRecord: record));
        }
      },
    ).onBroadcast(
      event: 'lead_deleted',
      callback: (payload) {
        final record = payload['record'] as Map<String, dynamic>?;
        if (record != null) {
          _eventController.add(RealtimePayload(table: 'leads', type: RealtimeOpType.delete, oldRecord: record, newRecord: const {}));
        }
      },
    ).onBroadcast(
      event: 'log_added',
      callback: (payload) {
        final record = payload['record'] as Map<String, dynamic>?;
        if (record != null) {
          _eventController.add(RealtimePayload(table: 'lead_logs', type: RealtimeOpType.insert, oldRecord: const {}, newRecord: record));
        }
      },
    ).subscribe();
  }

  Future<void> sendBulkTransferEvent(String receiverId) async {
    try {
      if (_broadcastChannel != null) {
        await _broadcastChannel!.sendBroadcastMessage(
          event: 'bulk_transfer',
          payload: {'receiver_id': receiverId},
        );
      }
    } catch (e) {
      if (kDebugMode) print('Failed to send broadcast: $e');
    }
  }

  void broadcastNewLead(String leadId, String assignedTo) {
    _broadcastChannel?.sendBroadcastMessage(
      event: 'lead_inserted',
      payload: { 'record': { 'id': leadId, 'assigned_to': assignedTo } },
    );
  }

  void broadcastLeadUpdated(String leadId, String assignedTo) {
    _broadcastChannel?.sendBroadcastMessage(
      event: 'lead_updated',
      payload: { 'record': { 'id': leadId, 'assigned_to': assignedTo } },
    );
  }

  void broadcastLeadDeleted(String leadId) {
    _broadcastChannel?.sendBroadcastMessage(
      event: 'lead_deleted',
      payload: { 'record': { 'id': leadId } },
    );
  }

  void broadcastLogAdded(Map<String, dynamic> logJson) {
    _broadcastChannel?.sendBroadcastMessage(
      event: 'log_added',
      payload: { 'record': logJson },
    );
  }

  void _setupOperationsChannel() {
    _operationsChannel = _supabase.channel('public:operations_channel');

    _operationsChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        callback: (payload) => _dispatchPayload('profiles', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'leads',
        callback: (payload) => _dispatchPayload('leads', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'lead_logs',
        callback: (payload) => _dispatchPayload('lead_logs', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'lead_notes',
        callback: (payload) => _dispatchPayload('lead_notes', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tasks',
        callback: (payload) => _dispatchPayload('tasks', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'properties',
        callback: (payload) => _dispatchPayload('properties', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'property_images',
        callback: (payload) => _dispatchPayload('property_images', payload),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'property_shares',
        callback: (payload) => _dispatchPayload('property_shares', payload),
      )
      .subscribe((status, error) {
        if (kDebugMode) {
          print('Operations Channel Status: $status');
        }
      });
  }

  void _setupSystemConfigChannel() {
    _systemConfigChannel = _supabase.channel('public:system_config_channel');
    
    // جداول القوائم العادية — تستدعي refreshDropdowns() فقط
    final dropdownTables = [
      'lead_statuses',
      'lead_rates',
      'property_types',
      'listing_types',
      'lead_platforms',
      'lead_exclusion_reasons',
      'activity_types',
      'meeting_types',
      'meeting_purposes',
      'cities',
      'governorates',
      'communication_channels',
      'property_approval_statuses',
    ];

    for (var table in dropdownTables) {
      _systemConfigChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) {
          if (kDebugMode) {
            print('System Config changed: $table → refreshing dropdowns only...');
          }
          di.sl<StaticDataManager>().refreshDropdowns();
        },
      );
    }

    // جدول حقول النموذج — يستدعي refreshFormFields() فقط
    _systemConfigChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'form_field_definitions',
      callback: (payload) {
        if (kDebugMode) {
          print('form_field_definitions changed → refreshing form fields only...');
        }
        di.sl<StaticDataManager>().refreshFormFields();
      },
    );

    _systemConfigChannel!.subscribe();
  }

  void _dispatchPayload(String table, PostgresChangePayload payload) {
    if (kDebugMode) {
      print('REALTIME_DEBUG: Received event on ${payload.table}, type: ${payload.eventType}');
    }

    RealtimeOpType type;
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        type = RealtimeOpType.insert;
        break;
      case PostgresChangeEvent.update:
        type = RealtimeOpType.update;
        break;
      case PostgresChangeEvent.delete:
        type = RealtimeOpType.delete;
        break;
      default:
        return;
    }

    _eventController.add(RealtimePayload(
      table: table,
      type: type,
      oldRecord: payload.oldRecord,
      newRecord: payload.newRecord,
    ));
  }

  void dispose() {
    _operationsChannel?.unsubscribe();
    _systemConfigChannel?.unsubscribe();
    _eventController.close();
    _isInitialized = false;
  }
}
