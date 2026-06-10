import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart' as di;
import '../../../core/utils/property_sync_notifier.dart';
import '../../../core/utils/static_data_manager.dart';
import '../../../data/models/property_model.dart';
import '../../../data/repositories/property_repository.dart';
import 'property_tasks_state.dart';

class PropertyTasksCubit extends Cubit<PropertyTasksState> {
  final PropertyRepository _repo;
  final PropertySyncNotifier _sync;

  String _lastUserId = '';
  String _lastRole = '';

  PropertyTasksCubit(this._repo, this._sync) : super(PropertyTasksInitial());

  @override
  void emit(PropertyTasksState state) {
    if (!isClosed) super.emit(state);
  }

  PropertyTasksSuccess get _current => state is PropertyTasksSuccess
      ? state as PropertyTasksSuccess
      : PropertyTasksSuccess();

  void invalidateTasks() {
    if (state is PropertyTasksSuccess) {
      emit(_current.copyWith(hasFetchedTasks: false));
    }
  }

  void invalidateApprovals() {
    if (state is PropertyTasksSuccess) {
      emit(_current.copyWith(hasFetchedApprovals: false));
    }
  }

  Future<void> fetchPendingApprovals({
    required String pendingStatusId,
    String? filteredEmployeeId,
    bool isRefresh = false,
  }) async {
    final current = _current;

    if (_lastUserId.isNotEmpty && _lastRole.isNotEmpty) {
      // In case fetchPendingApprovals is called before fetchTaskProperties, 
      // although it usually requires admin role.
    }

    if (!isRefresh && current.hasFetchedApprovals) return;

    if (!isRefresh && !current.hasFetchedApprovals) {
      emit(current.copyWith(isLoadingApprovals: true, clearError: true));
    }

    try {
      final results = await _repo.filterProperties(
        0,
        100,
        approvalStatusId: pendingStatusId,
        assignedTo: filteredEmployeeId,
      );
      emit(
        current.copyWith(
          pendingApprovals: results,
          isLoadingApprovals: false,
          hasFetchedApprovals: true,
        ),
      );
    } catch (e) {
      emit(PropertyTasksError('فشل تحميل الموافقات: $e'));
    }
  }

  Future<void> fetchTaskProperties({
    required String role,
    required String userId,
    String? filteredEmployeeId,
    bool isRefresh = false,
  }) async {
    final current = _current;

    if (_lastUserId != userId || _lastRole != role) {
      isRefresh = true;
      _lastUserId = userId;
      _lastRole = role;
    }

    if (!isRefresh && current.hasFetchedTasks) return;

    if (!isRefresh && !current.hasFetchedTasks) {
      emit(current.copyWith(isLoadingTasks: true, clearError: true));
    }

    try {
      final isAdmin = role == 'manager' || role == 'admin' || role == 'ceo';
      final String? assignedTo = isAdmin ? filteredEmployeeId : userId;

      final publishedId = '70bb0089-736b-4607-951d-916fbcc1cc07';

      final results = await _repo.fetchTaskProperties(
        assignedTo: assignedTo,
        excludeApprovalStatusId: publishedId,
      );

      emit(
        current.copyWith(
          taskProperties: results,
          isLoadingTasks: false,
          hasFetchedTasks: true,
        ),
      );
    } catch (e) {
      emit(PropertyTasksError('فشل تحميل مهام العقارات: $e'));
    }
  }

  Future<void> approveProperty({
    required String propertyId,
    required String approvalStatusId,
    required List<String> platformIds,
    String? managerNotes,
  }) async {
    await _updateApprovalStatus(
      propertyId: propertyId,
      approvalStatusId: approvalStatusId,
      platformIds: platformIds,
      managerNotes: managerNotes,
      replacePlatforms: platformIds.isNotEmpty,
    );
  }

  Future<void> markAsPublished({
    required String propertyId,
    required String approvalStatusId,
    required List<String> publishedPlatformIds,
  }) async {
    final current = _current;
    try {
      await _repo.updateProperty(
        id: propertyId,
        data: {'approval_status_id': approvalStatusId},
      );
      if (publishedPlatformIds.isNotEmpty) {
        await _repo.publishPropertyPlatforms(propertyId, publishedPlatformIds);
      }
      final fresh = await _repo.getPropertyById(propertyId);
      _applyPropertyUpdate(current, fresh, removeFromTasks: true);
      _sync.notifyUpdated(fresh);
    } catch (e) {
      emit(PropertyTasksError('فشل النشر: $e'));
      emit(current);
    }
  }

  Future<void> resubmitRejectedProperty({
    required String propertyId,
    required String approvedStatusId,
  }) async {
    final current = _current;
    try {
      await _repo.updateProperty(
        id: propertyId,
        data: {'approval_status_id': approvedStatusId},
      );
      await _repo.resetPlatformsPublished(propertyId);
      final fresh = await _repo.getPropertyById(propertyId);
      _applyPropertyUpdate(current, fresh);
      _sync.notifyUpdated(fresh);
    } catch (e) {
      emit(PropertyTasksError('فشل إعادة النشر: $e'));
      emit(current);
    }
  }

  Future<void> deleteFullProperty(String id) async {
    final current = _current;
    try {
      await _repo.deleteFullProperty(id);
      emit(
        current.copyWith(
          taskProperties: current.taskProperties
              .where((p) => p.id != id)
              .toList(),
          pendingApprovals: current.pendingApprovals
              .where((p) => p.id != id)
              .toList(),
        ),
      );
      _sync.notifyDeleted(id);
    } catch (e) {
      emit(PropertyTasksError('فشل الحذف: $e'));
      emit(current);
    }
  }

  Future<void> _updateApprovalStatus({
    required String propertyId,
    required String approvalStatusId,
    List<String> platformIds = const [],
    String? managerNotes,
    bool replacePlatforms = false,
  }) async {
    final current = _current;
    try {
      final updated = await _repo.updateProperty(
        id: propertyId,
        data: {
          'approval_status_id': approvalStatusId,
          if (managerNotes != null) 'manager_notes': managerNotes,
        },
        platformIds: replacePlatforms ? platformIds : const [],
      );

      final dataManager = di.sl<StaticDataManager>();
      final publishedId = dataManager.getIdByName(
        'property_approval_statuses',
        'تم النشر',
      );
      final pendingId = dataManager.getIdByName(
        'property_approval_statuses',
        'قيد المراجعة',
      );

      final removeFromTasks = approvalStatusId == publishedId;
      final removeFromApprovals = approvalStatusId != pendingId;

      _applyPropertyUpdate(
        current,
        updated,
        removeFromTasks: removeFromTasks,
        removeFromApprovals: removeFromApprovals,
      );
      _sync.notifyUpdated(updated);
    } catch (e) {
      emit(PropertyTasksError('فشل تحديث الحالة: $e'));
      emit(current);
    }
  }

  void _applyPropertyUpdate(
    PropertyTasksSuccess current,
    PropertyModel updated, {
    bool removeFromTasks = false,
    bool removeFromApprovals = true,
  }) {
    List<PropertyModel> taskProps;
    if (removeFromTasks) {
      taskProps = current.taskProperties
          .where((e) => e.id != updated.id)
          .toList();
    } else {
      taskProps = current.taskProperties
          .map((e) => e.id == updated.id ? updated : e)
          .toList();
      if (!taskProps.any((e) => e.id == updated.id)) {
        taskProps = [...taskProps, updated];
      }
    }

    final pendingProps = removeFromApprovals
        ? current.pendingApprovals.where((e) => e.id != updated.id).toList()
        : current.pendingApprovals
              .map((e) => e.id == updated.id ? updated : e)
              .toList();

    emit(
      current.copyWith(
        taskProperties: taskProps,
        pendingApprovals: pendingProps,
      ),
    );
  }
}
