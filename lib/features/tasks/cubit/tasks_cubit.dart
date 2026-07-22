import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

import '../../../core/constants/app_roles.dart';
import '../../../data/services/realtime_sync_service.dart';

abstract class TasksState {}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<TaskModel> tasks;
  final String? filterEmployeeId;
  final String? filterStatusId;
  final String? filterLeadId;
  final String? filterPropertyId;
  /// IDs المهام اللي اتحدثت للتو عبر realtime — تُستخدم لعمل وميض لحظي
  final Set<String> flashingIds;

  TasksLoaded({
    required this.tasks,
    this.filterEmployeeId,
    this.filterStatusId,
    this.filterLeadId,
    this.filterPropertyId,
    this.flashingIds = const {},
  });

  TasksLoaded copyWith({
    List<TaskModel>? tasks,
    String? filterEmployeeId,
    String? filterStatusId,
    String? filterLeadId,
    String? filterPropertyId,
    Set<String>? flashingIds,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      filterEmployeeId: filterEmployeeId ?? this.filterEmployeeId,
      filterStatusId: filterStatusId ?? this.filterStatusId,
      filterLeadId: filterLeadId ?? this.filterLeadId,
      filterPropertyId: filterPropertyId ?? this.filterPropertyId,
      flashingIds: flashingIds ?? this.flashingIds,
    );
  }
}

class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
}

class TasksCubit extends Cubit<TasksState> {
  final TaskRepository _taskRepository;
  final RealtimeSyncService _realtime;

  String _currentRole = '';
  String _currentUserId = '';

  TasksCubit(this._taskRepository, this._realtime) : super(TasksInitial()) {
    _realtime.events.listen(_handleRealtimeEvent);
  }

  @override
  void emit(TasksState state) {
    if (!isClosed) super.emit(state);
  }

  void init(String role, String userId) {
    _currentRole = role;
    _currentUserId = userId;
    fetchTasks();
  }

  void _handleRealtimeEvent(RealtimePayload payload) {
    if (state is! TasksLoaded) return;
    if (payload.table != 'tasks') return;

    final st = state as TasksLoaded;

    if (payload.type == RealtimeOpType.update || payload.type == RealtimeOpType.insert) {
      final rawId = payload.newRecord['id']?.toString();
      if (rawId != null) {
        // نجيب التفاصيل الكاملة للمهمة (بـ joins)
        fetchTaskDetails(rawId);
      }
    } else if (payload.type == RealtimeOpType.delete) {
      final deletedId = payload.oldRecord['id']?.toString();
      if (deletedId != null) {
        final updatedTasks = st.tasks.where((t) => t.id != deletedId).toList();
        emit(st.copyWith(tasks: updatedTasks, flashingIds: {}));
      }
    }
  }

  /// يضيف وميضاً لحظياً على المهمة المحدَّثة — يختفي بعد 1.2 ثانية
  void _flashItem(String id) {
    if (state is! TasksLoaded || isClosed) return;
    final st = state as TasksLoaded;
    emit(st.copyWith(flashingIds: {id}));
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (state is TasksLoaded && !isClosed) {
        emit((state as TasksLoaded).copyWith(flashingIds: {}));
      }
    });
  }

  Future<void> fetchTaskDetails(String taskId) async {
    if (state is TasksLoaded) {
      final st = state as TasksLoaded;
      try {
        final detailedTask = await _taskRepository.getTaskById(taskId);
        
        // تحقق من الصلاحية — هل المهمة خاصة بي أو أنا مدير؟
        final isMine = detailedTask.assignedTo == _currentUserId || detailedTask.createdBy == _currentUserId;
        final isManager = AppRole.fromString(_currentRole).isAtLeast(AppRole.manager);

        if (!isMine && !isManager) {
          // مش من حقي → احذف لو كانت موجودة
          final updatedTasks = st.tasks.where((t) => t.id != taskId).toList();
          emit(st.copyWith(tasks: updatedTasks));
          return;
        }

        // تحقق من الفلاتر
        if (st.filterLeadId != null && st.filterLeadId != detailedTask.leadId) return;
        if (st.filterPropertyId != null && st.filterPropertyId != detailedTask.propertyId) return;
        if (st.filterStatusId != null && st.filterStatusId != detailedTask.statusId) return;
        if (st.filterEmployeeId != null && st.filterEmployeeId != detailedTask.assignedTo) return;

        bool exists = st.tasks.any((t) => t.id == taskId);
        List<TaskModel> updatedTasks;
        if (exists) {
          updatedTasks = st.tasks.map((t) => t.id == taskId ? detailedTask : t).toList();
        } else {
          updatedTasks = [detailedTask, ...st.tasks];
        }

        emit(st.copyWith(tasks: updatedTasks));
        _flashItem(taskId);
      } catch (e) {
        // تجاهل الخطأ
      }
    }
  }

  Future<void> fetchTasks({
    String? filterEmployeeId,
    String? statusId,
    String? leadId,
    String? propertyId,
  }) async {
    emit(TasksLoading());
    try {
      final tasks = await _taskRepository.getTasks(
        role: _currentRole,
        userId: _currentUserId,
        filterByEmployeeId: filterEmployeeId,
        statusId: statusId,
        leadId: leadId,
        propertyId: propertyId,
      );
      emit(
        TasksLoaded(
          tasks: tasks,
          filterEmployeeId: filterEmployeeId,
          filterStatusId: statusId,
          filterLeadId: leadId,
          filterPropertyId: propertyId,
        ),
      );
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> refresh() async {
    if (state is TasksLoaded) {
      final currentState = state as TasksLoaded;
      await fetchTasks(
        filterEmployeeId: currentState.filterEmployeeId,
        statusId: currentState.filterStatusId,
        leadId: currentState.filterLeadId,
        propertyId: currentState.filterPropertyId,
      );
    } else {
      await fetchTasks();
    }
  }

  Future<void> addTask(TaskModel task) async {
    // نرسل للـ DB — الـ realtime سيضيف المهمة تلقائياً عند النجاح
    try {
      await _taskRepository.addTask(task);
    } catch (e) {
      emit(TasksError(e.toString()));
      // refresh لاستعادة الحالة الصحيحة
      await refresh();
    }
  }

  Future<void> updateTask(String id, TaskModel task) async {
    // Optimistic update — نحدث محلياً فوراً
    TasksLoaded? prevState;
    if (state is TasksLoaded) {
      prevState = state as TasksLoaded;
      final updatedTasks = prevState.tasks
          .map((t) => t.id == id ? task.copyWith(id: id) : t)
          .toList();
      emit(prevState.copyWith(tasks: updatedTasks));
      _flashItem(id);
    }
    try {
      await _taskRepository.updateTask(id, task);
    } catch (e) {
      // Rollback
      if (prevState != null) emit(prevState);
      emit(TasksError(e.toString()));
    }
  }

  Future<void> deleteTask(String id) async {
    // Optimistic delete — نحذف محلياً فوراً
    TasksLoaded? prevState;
    if (state is TasksLoaded) {
      prevState = state as TasksLoaded;
      final updatedTasks = prevState.tasks.where((t) => t.id != id).toList();
      emit(prevState.copyWith(tasks: updatedTasks));
    }
    try {
      await _taskRepository.deleteTask(id);
    } catch (e) {
      // Rollback
      if (prevState != null) emit(prevState);
      emit(TasksError(e.toString()));
    }
  }

  Future<void> updateTaskStatus(String id, String statusId) async {
    // Optimistic update للـ status فقط
    TasksLoaded? prevState;
    if (state is TasksLoaded) {
      prevState = state as TasksLoaded;
      final updatedTasks = prevState.tasks.map((t) {
        if (t.id == id) return t.copyWith(statusId: statusId);
        return t;
      }).toList();
      emit(prevState.copyWith(tasks: updatedTasks));
      _flashItem(id);
    }
    try {
      await _taskRepository.updateTaskStatus(id, statusId);
    } catch (e) {
      // Rollback
      if (prevState != null) emit(prevState);
      emit(TasksError(e.toString()));
    }
  }
}
