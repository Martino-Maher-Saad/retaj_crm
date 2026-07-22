import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskRepository {
  final TaskService _taskService;

  TaskRepository(this._taskService);

  Future<List<TaskModel>> getTasks({
    required String role,
    required String userId,
    String? filterByEmployeeId,
    String? statusId,
    String? leadId,
    String? propertyId,
  }) async {
    try {
      return await _taskService.getTasks(
        role: role,
        userId: userId,
        filterByEmployeeId: filterByEmployeeId,
        statusId: statusId,
        leadId: leadId,
        propertyId: propertyId,
      );
    } catch (e) {
      throw 'حدث خطأ أثناء جلب المهام';
    }
  }

  Future<TaskModel> getTaskById(String id) async {
    try {
      return await _taskService.getTaskById(id);
    } catch (e) {
      throw 'حدث خطأ أثناء جلب المهمة';
    }
  }

  Future<TaskModel> addTask(TaskModel task) async {
    try {
      return await _taskService.addTask(task);
    } catch (e) {
      throw 'حدث خطأ أثناء إضافة المهمة';
    }
  }

  Future<TaskModel> updateTask(String id, TaskModel task) async {
    try {
      return await _taskService.updateTask(id, task);
    } catch (e) {
      throw 'حدث خطأ أثناء تحديث المهمة';
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _taskService.deleteTask(id);
    } catch (e) {
      throw 'حدث خطأ أثناء مسح المهمة';
    }
  }

  Future<TaskModel> updateTaskStatus(String id, String statusId) async {
    try {
      return await _taskService.updateTaskStatus(id, statusId);
    } catch (e) {
      throw 'حدث خطأ أثناء تحديث حالة المهمة';
    }
  }
}
