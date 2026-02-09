import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../tables/task_table.dart';
import '../tables/category_table.dart';

part 'task_dao.g.dart';

/// Combines a [Task] row with its associated [Category] row.
class TaskWithCategory {
  final Task task;
  final Category category;

  TaskWithCategory({required this.task, required this.category});
}

/// Data access object for task CRUD operations and filtered queries.
@DriftAccessor(tables: [Tasks, Categories])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watches all tasks joined with their categories, ordered by completion, priority, and due date.
  Stream<List<TaskWithCategory>> watchAllTasks() {
    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  /// Watches all tasks and applies a client-side [filter] predicate.
  Stream<List<TaskWithCategory>> watchTasksByFilter({
    required bool Function(Task) filter,
  }) {
    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows
          .map((row) {
            return TaskWithCategory(
              task: row.readTable(tasks),
              category: row.readTable(categories),
            );
          })
          .where((tc) => filter(tc.task))
          .toList();
    });
  }

  /// Watches only tasks whose due date falls on the current calendar day.
  Stream<List<TaskWithCategory>> watchTodayTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  /// Watches tasks with a due date strictly after today.
  Stream<List<TaskWithCategory>> watchUpcomingTasks() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isBiggerOrEqualValue(endOfToday))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.dueDate),
        OrderingTerm.asc(tasks.priority),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  /// Watches incomplete tasks whose due date is before today.
  Stream<List<TaskWithCategory>> watchOverdueTasks() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.dueDate.isSmallerThanValue(startOfDay) &
          tasks.isCompleted.equals(false))
      ..orderBy([
        OrderingTerm.asc(tasks.dueDate),
        OrderingTerm.asc(tasks.priority),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  /// Watches tasks belonging to a specific [categoryId].
  Stream<List<TaskWithCategory>> watchTasksByCategory(int categoryId) {
    final query = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.categoryId.equals(categoryId))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  /// Watches the count of incomplete tasks in a given [categoryId].
  Stream<int> watchTaskCountByCategory(int categoryId) {
    final query = select(tasks)
      ..where(
          (t) => t.categoryId.equals(categoryId) & t.isCompleted.equals(false));
    return query.watch().map((rows) => rows.length);
  }

  /// Retrieves a single task by its [id].
  Future<Task> getTaskById(int id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Inserts a new task and returns the generated row ID.
  Future<int> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  /// Updates an existing task and returns `true` if any row was affected.
  Future<bool> updateTask(TasksCompanion task) {
    return (update(tasks)..where((t) => t.id.equals(task.id.value)))
        .write(task)
        .then((rows) => rows > 0);
  }

  /// Toggles the completion status and updates [completedAt] accordingly.
  Future<void> toggleTaskCompletion(int id, bool isCompleted) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
      ),
    );
  }

  /// Deletes a task by [id] and returns the number of rows removed.
  Future<int> deleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Reassigns all tasks from [fromCategoryId] to [toCategoryId].
  Future<void> moveTasksToCategory(int fromCategoryId, int toCategoryId) {
    return (update(tasks)..where((t) => t.categoryId.equals(fromCategoryId)))
        .write(TasksCompanion(categoryId: Value(toCategoryId)));
  }

  /// Watches tasks whose title or description matches [query] (LIKE pattern).
  Stream<List<TaskWithCategory>> watchSearchResults(String query) {
    final pattern = '%$query%';
    final q = select(tasks).join([
      leftOuterJoin(categories, categories.id.equalsExp(tasks.categoryId)),
    ])
      ..where(tasks.title.like(pattern) | tasks.description.like(pattern))
      ..orderBy([
        OrderingTerm.asc(tasks.isCompleted),
        OrderingTerm.asc(tasks.priority),
        OrderingTerm.asc(tasks.dueDate),
      ]);

    return q.watch().map((rows) {
      return rows.map((row) {
        return TaskWithCategory(
          task: row.readTable(tasks),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  /// Watches the total count of incomplete tasks.
  Stream<int> countTotal() {
    final q = select(tasks)..where((t) => t.isCompleted.equals(false));
    return q.watch().map((rows) => rows.length);
  }

  /// Watches the count of tasks completed during the current day.
  Stream<int> countCompletedToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final q = select(tasks)
      ..where((t) =>
          t.isCompleted.equals(true) &
          t.completedAt.isBetweenValues(startOfDay, endOfDay));
    return q.watch().map((rows) => rows.length);
  }

  /// Watches the count of overdue (past-due and incomplete) tasks.
  Stream<int> countOverdue() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final q = select(tasks)
      ..where((t) =>
          t.dueDate.isSmallerThanValue(startOfDay) &
          t.isCompleted.equals(false));
    return q.watch().map((rows) => rows.length);
  }

  /// Watches the completion rate of tasks created in the last 7 days.
  Stream<double> weeklyCompletionRate() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final allThisWeek = select(tasks)
      ..where((t) => t.createdAt.isBiggerOrEqualValue(weekAgo));
    return allThisWeek.watch().map((rows) {
      if (rows.isEmpty) return 0.0;
      final completed = rows.where((t) => t.isCompleted).length;
      return completed / rows.length;
    });
  }
}
