import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';

class TaskService {
  final SupabaseClient _supabase;

  TaskService(this._supabase);

  static const String _selectList = 
      '*, '
      'creator:profiles!tasks_created_by_fkey(first_name, last_name), '
      'assignee:profiles!tasks_assigned_to_fkey(first_name, last_name), '
      'task_statuses!tasks_status_id_fkey(name_ar), '
      'leads!tasks_lead_id_fkey(client_name), '
      'properties!tasks_property_id_fkey(title_ar)';

  Future<List<TaskModel>> getTasks({
    required String role,
    required String userId,
    String? filterByEmployeeId,
    String? statusId,
    String? leadId,
    String? propertyId,
  }) async {
    dynamic query = _supabase.from('tasks').select(_selectList);

    // Filter by role/employee
    if (role == 'sales') {
      query = query.eq('assigned_to', userId);
    } else if (filterByEmployeeId != null && filterByEmployeeId.isNotEmpty) {
      query = query.eq('assigned_to', filterByEmployeeId);
    }

    if (statusId != null && statusId.isNotEmpty) {
      query = query.eq('status_id', statusId);
    }
    if (leadId != null && leadId.isNotEmpty) {
      query = query.eq('lead_id', leadId);
    }
    if (propertyId != null && propertyId.isNotEmpty) {
      query = query.eq('property_id', propertyId);
    }

    query = query.order('created_at', ascending: false);

    final response = await query;
    return (response as List).map((e) => TaskModel.fromJson(e)).toList();
  }

  Future<TaskModel> getTaskById(String id) async {
    final response = await _supabase.from('tasks').select(_selectList).eq('id', id).single();
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> addTask(TaskModel task) async {
    final data = task.toJson();
    final response = await _supabase.from('tasks').insert(data).select(_selectList).single();
    return TaskModel.fromJson(response);
  }

  Future<TaskModel> updateTask(String id, TaskModel task) async {
    final data = task.toJson();
    // Don't update created_by etc. if not needed, but toJson handles it.
    final response = await _supabase.from('tasks').update(data).eq('id', id).select(_selectList).single();
    return TaskModel.fromJson(response);
  }

  Future<void> deleteTask(String id) async {
    await _supabase.from('tasks').delete().eq('id', id);
  }

  Future<TaskModel> updateTaskStatus(String id, String statusId) async {
    final response = await _supabase.from('tasks').update({
      'status_id': statusId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select(_selectList).single();
    return TaskModel.fromJson(response);
  }
}
