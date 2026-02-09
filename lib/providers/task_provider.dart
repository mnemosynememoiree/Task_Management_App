import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/daos/task_dao.dart';
import '../models/enums/task_filter.dart';
import '../models/enums/task_sort.dart';
import 'database_provider.dart';
import 'filter_provider.dart';
import 'sort_provider.dart';

/// Provides a real-time stream of all tasks with their categories.
final allTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchAllTasks();
});

/// Provides a real-time stream of tasks due today.
final todayTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchTodayTasks();
});

/// Provides a real-time stream of tasks due after today.
final upcomingTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchUpcomingTasks();
});

/// Provides a real-time stream of overdue incomplete tasks.
final overdueTasksStreamProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchOverdueTasks();
});

List<TaskWithCategory> _applySorting(
    List<TaskWithCategory> tasks, TaskSort sort) {
  final sorted = List<TaskWithCategory>.from(tasks);
  switch (sort) {
    case TaskSort.priorityAsc:
      sorted.sort((a, b) {
        final compCompleted =
            a.task.isCompleted ? 1 : 0;
        final compCompletedB =
            b.task.isCompleted ? 1 : 0;
        final c = compCompleted.compareTo(compCompletedB);
        if (c != 0) return c;
        return a.task.priority.compareTo(b.task.priority);
      });
    case TaskSort.dueDateAsc:
      sorted.sort((a, b) {
        if (a.task.dueDate == null && b.task.dueDate == null) return 0;
        if (a.task.dueDate == null) return 1;
        if (b.task.dueDate == null) return -1;
        return a.task.dueDate!.compareTo(b.task.dueDate!);
      });
    case TaskSort.dueDateDesc:
      sorted.sort((a, b) {
        if (a.task.dueDate == null && b.task.dueDate == null) return 0;
        if (a.task.dueDate == null) return 1;
        if (b.task.dueDate == null) return -1;
        return b.task.dueDate!.compareTo(a.task.dueDate!);
      });
    case TaskSort.titleAsc:
      sorted.sort(
          (a, b) => a.task.title.toLowerCase().compareTo(b.task.title.toLowerCase()));
    case TaskSort.createdAtDesc:
      sorted.sort((a, b) => b.task.createdAt.compareTo(a.task.createdAt));
  }
  return sorted;
}

/// Combines the active filter and sort option into a single sorted task stream.
final filteredTasksProvider =
    StreamProvider<List<TaskWithCategory>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final dao = ref.watch(taskDaoProvider);
  final sort = ref.watch(taskSortProvider);

  Stream<List<TaskWithCategory>> stream;
  switch (filter) {
    case TaskFilter.today:
      stream = dao.watchTodayTasks();
    case TaskFilter.upcoming:
      stream = dao.watchUpcomingTasks();
    case TaskFilter.overdue:
      stream = dao.watchOverdueTasks();
    case TaskFilter.all:
      stream = dao.watchAllTasks();
  }

  return stream.map((tasks) => _applySorting(tasks, sort));
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

/// Manages task mutations (add, update, delete, toggle, move).
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final TaskDao _dao;

  TaskNotifier(this._dao) : super(const AsyncValue.data(null));

  /// Creates a new task and returns its generated row ID.
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

  /// Updates an existing task's fields.
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

  /// Toggles the completion status of a task.
  Future<void> toggleCompletion(int id, bool isCompleted) async {
    try {
      await _dao.toggleTaskCompletion(id, isCompleted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Permanently deletes a task by [id].
  Future<void> deleteTask(int id) async {
    try {
      await _dao.deleteTask(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a task but return its data so it can be restored.
  Future<TasksCompanion?> deleteTaskWithUndo(int id) async {
    try {
      final task = await _dao.getTaskById(id);
      final companion = TasksCompanion(
        id: Value(task.id),
        title: Value(task.title),
        description: Value(task.description),
        isCompleted: Value(task.isCompleted),
        priority: Value(task.priority),
        dueDate: Value(task.dueDate),
        dueTime: Value(task.dueTime),
        categoryId: Value(task.categoryId),
        createdAt: Value(task.createdAt),
        completedAt: Value(task.completedAt),
      );
      await _dao.deleteTask(id);
      return companion;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Restore a previously deleted task.
  Future<void> restoreTask(TasksCompanion companion) async {
    try {
      await _dao.insertTask(companion);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Moves all tasks from one category to another.
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
