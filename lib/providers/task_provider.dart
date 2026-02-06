import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/daos/task_dao.dart';
import '../models/enums/task_filter.dart';
import 'database_provider.dart';
import 'filter_provider.dart';

final allTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchAllTasks();
});

final todayTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchTodayTasks();
});

final upcomingTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchUpcomingTasks();
});

final overdueTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchOverdueTasks();
});

final filteredTasksProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final dao = ref.watch(taskDaoProvider);

  switch (filter) {
    case TaskFilter.today:
      return dao.watchTodayTasks();
    case TaskFilter.upcoming:
      return dao.watchUpcomingTasks();
    case TaskFilter.overdue:
      return dao.watchOverdueTasks();
    case TaskFilter.all:
      return dao.watchAllTasks();
  }
});

final categoryTasksStreamProvider =
    StreamProvider.family<List<TaskWithCategory>, int>((ref, categoryId) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchTasksByCategory(categoryId);
});

final categoryTaskCountProvider =
    StreamProvider.family<int, int>((ref, categoryId) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchTaskCountByCategory(categoryId);
});

final taskByIdProvider = FutureProvider.family<Task, int>((ref, id) {
  final dao = ref.watch(taskDaoProvider);
  return dao.getTaskById(id);
});

class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskDao _dao;

  TaskNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<int> addTask({
    required String title,
    String? description,
    int priority = 1,
    DateTime? dueDate,
    DateTime? dueTime,
    int categoryId = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      final id = await _dao.insertTask(
        TasksCompanion.insert(
          title: title,
          description: Value(description),
          priority: Value(priority),
          dueDate: Value(dueDate),
          dueTime: Value(dueTime),
          categoryId: Value(categoryId),
        ),
      );
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTask({
    required int id,
    required String title,
    String? description,
    required int priority,
    DateTime? dueDate,
    DateTime? dueTime,
    required int categoryId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _dao.updateTask(
        TasksCompanion(
          id: Value(id),
          title: Value(title),
          description: Value(description),
          priority: Value(priority),
          dueDate: Value(dueDate),
          dueTime: Value(dueTime),
          categoryId: Value(categoryId),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleCompletion(int id, bool isCompleted) async {
    try {
      await _dao.toggleTaskCompletion(id, isCompleted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _dao.deleteTask(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> moveTasksToCategory(int fromId, int toId) async {
    try {
      await _dao.moveTasksToCategory(fromId, toId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  return TaskNotifier(ref.watch(taskDaoProvider));
});
